/**
 * Netlify Function: Main Chat Endpoint
 *
 * Receives user message, returns AI response
 * Handles both text responses and invoice/quotation creation
 *
 * Usage: POST /.netlify/functions/chat
 * Body: { message: "text", session_id: "xxx" }
 */

const glmClient = require('../../backend/glmClient');
const xeroClient = require('../../backend/xeroClient');

// In-memory session storage (use Redis/database in production)
const sessions = new Map();

function setSession(id, data) {
  sessions.set(id, data);
}

function getSession(id) {
  return sessions.get(id);
}

exports.handler = async (event, context) => {
  try {
    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ success: false, error: 'Method not allowed' })
      };
    }

    // Parse request body
    let body;
    try {
      body = JSON.parse(event.body);
    } catch (e) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          error: 'Invalid JSON body'
        })
      };
    }

    const { message, session_id } = body;

    if (!message) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          error: 'Message is required'
        })
      };
    }

    const sessionId = session_id || 'default';

    // Get or create session
    let session = getSession(sessionId);
    if (!session) {
      session = {
        conversationHistory: [],
        connected: false
      };
      setSession(sessionId, session);
    }

    // Refresh access token if needed (5 minutes before expiry)
    if (session.connected && session.refreshToken && xeroClient.needsRefresh(session.expiresAt)) {
      console.log('Refreshing Xero access token...');

      const refreshResult = await xeroClient.refreshAccessToken(session.refreshToken);

      if (refreshResult.success) {
        setSession(sessionId, {
          ...session,
          accessToken: refreshResult.tokens.accessToken,
          refreshToken: refreshResult.tokens.refreshToken,
          expiresAt: refreshResult.tokens.expiresAt,
          refreshAt: refreshResult.tokens.refreshAt
        });
        session = getSession(sessionId);
        console.log('Token refreshed successfully');
      } else {
        console.error('Token refresh failed:', refreshResult.error);
      }
    }

    // Get AI response
    const aiResponse = await glmClient.chatWithGLM(
      message,
      session.conversationHistory
    );

    if (!aiResponse.success) {
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          message: aiResponse.content,
          error: aiResponse.error
        })
      };
    }

    // Update conversation history (keep last 20 messages)
    session.conversationHistory.push(
      { role: 'user', content: message },
      { role: 'assistant', content: aiResponse.content }
    );
    if (session.conversationHistory.length > 20) {
      session.conversationHistory = session.conversationHistory.slice(-20);
    }

    // If AI response is JSON (invoice/quotation request or info request)
    if (aiResponse.isJSON && aiResponse.parsedJSON) {
      const responseData = aiResponse.parsedJSON;

      // Handle request_info action (AI needs more data)
      if (responseData.action === 'request_info') {
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: true,
            type: 'request_info',
            data: responseData,
            message: responseData.message || 'Please provide additional information'
          })
        };
      }

      // Check if Xero is connected
      if (!session.connected || !session.accessToken) {
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: true,
            type: 'document_data',
            message: aiResponse.content,
            data: responseData,
            xero_connected: false,
            note: 'Please connect Xero account first via /login'
          })
        };
      }

      // Handle create_quotation action
      if (responseData.action === 'create_quotation') {
        const xeroResult = await xeroClient.createQuotation(
          responseData,
          session.accessToken,
          session.tenantId
        );

        if (xeroResult.success) {
          return {
            statusCode: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
              success: true,
              type: 'quotation_created',
              message: 'Quotation created successfully in Xero',
              data: responseData,
              xero_quote: xeroResult.quote,
              xero_quote_id: xeroResult.quote.QuoteID,
              xero_quote_number: xeroResult.quoteNumber,
              quotation_url: xeroResult.quotationUrl
            })
          };
        } else {
          return {
            statusCode: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
              success: false,
              type: 'quotation_error',
              message: 'Failed to create quotation',
              data: responseData,
              xero_error: xeroResult.error,
              details: xeroResult.details
            })
          };
        }
      }

      // Handle create_invoice action
      if (responseData.action === 'create_invoice') {
        const xeroResult = await xeroClient.createInvoice(
          responseData,
          session.accessToken,
          session.tenantId
        );

        if (xeroResult.success) {
          return {
            statusCode: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
              success: true,
              type: 'invoice_created',
              message: 'Invoice created successfully in Xero',
              data: responseData,
              xero_invoice: xeroResult.invoice,
              xero_invoice_id: xeroResult.invoice.InvoiceID,
              xero_invoice_number: xeroResult.invoice.InvoiceNumber,
              invoice_url: xeroResult.invoiceUrl
            })
          };
        } else {
          return {
            statusCode: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
              success: false,
              type: 'invoice_error',
              message: 'Failed to create invoice',
              data: responseData,
              xero_error: xeroResult.error,
              details: xeroResult.details
            })
          };
        }
      }

      // Unknown action
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: true,
          type: 'unknown_action',
          data: responseData,
          message: 'Received JSON response with unknown action'
        })
      };
    }

    // Regular text response from AI
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: true,
        type: 'text',
        message: aiResponse.content,
        xero_connected: session.connected || false
      })
    };

  } catch (error) {
    console.error('Chat error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};
