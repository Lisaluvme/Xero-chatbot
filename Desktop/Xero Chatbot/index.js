/**
 * Xero Chatbot - Main Express Server
 *
 * This is the main server file that handles:
 * - Chat endpoint for AI conversations
 * - Xero OAuth2 callback handling
 * - Token management and refresh
 * - Integration between GLM-4-Flash AI and Xero API
 */

require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const glmClient = require('./glmClient');
const xeroClient = require('./xeroClient');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// ==========================================
// SESSION STORAGE (In-memory for demo)
// In production, use Redis or database
// ==========================================
const sessions = new Map();

/**
 * Store session data
 */
function setSession(sessionId, data) {
  sessions.set(sessionId, {
    ...sessions.get(sessionId),
    ...data,
    updatedAt: Date.now()
  });
}

/**
 * Get session data
 */
function getSession(sessionId) {
  return sessions.get(sessionId);
}

/**
 * Check if access token needs refresh
 */
function needsRefresh(expiresAt) {
  // Refresh 5 minutes before expiration
  return Date.now() > (expiresAt - 300000);
}

// ==========================================
// ROUTES
// ==========================================

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'Xero Chatbot'
  });
});

/**
 * Root endpoint - API information
 */
app.get('/', (req, res) => {
  res.json({
    name: 'Xero Chatbot API',
    version: '1.0.0',
    endpoints: {
      chat: 'POST /chat',
      xeroAuth: 'GET /xero/auth',
      xeroCallback: 'GET /xero/callback',
      xeroDisconnect: 'POST /xero/disconnect'
    },
    documentation: 'See README.md for usage examples'
  });
});

/**
 * Initiate Xero OAuth2 authentication
 *
 * Returns authorization URL for user to visit
 */
app.get('/xero/auth', async (req, res) => {
  try {
    const { url, state } = xeroClient.getAuthorizationUrl();

    // Store state in session for verification during callback
    const sessionId = req.query.session_id || 'default';
    setSession(sessionId, { oauthState: state });

    res.json({
      success: true,
      authorization_url: url,
      message: 'Visit the authorization URL to connect your Xero account'
    });

  } catch (error) {
    console.error('Auth error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Xero OAuth2 callback handler
 *
 * Receives authorization code and exchanges for tokens
 */
app.get('/xero/callback', async (req, res) => {
  try {
    const { code, state } = req.query;

    if (!code) {
      return res.status(400).send('Missing authorization code');
    }

    // Exchange code for access token
    const tokenResult = await xeroClient.exchangeCodeForToken(code);

    if (!tokenResult.success) {
      return res.status(400).json({
        success: false,
        error: tokenResult.error
      });
    }

    // Get tenants (organizations)
    const tenantsResult = await xeroClient.getTenants(tokenResult.tokens.accessToken);

    if (!tenantsResult.success) {
      return res.status(400).json({
        success: false,
        error: tenantsResult.error
      });
    }

    // Store tokens in session
    const sessionId = 'default'; // In production, use proper session management
    const tenantId = tenantsResult.tenants[0].tenantId;

    setSession(sessionId, {
      accessToken: tokenResult.tokens.accessToken,
      refreshToken: tokenResult.tokens.refreshToken,
      expiresAt: tokenResult.tokens.expiresAt,
      tenantId: tenantId,
      tenantName: tenantsResult.tenants[0].tenantName,
      connected: true
    });

    // Send HTML response (user-friendly)
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Xero Connected</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            text-align: center;
            padding: 20px;
          }
          .success {
            color: #2E7D32;
            font-size: 24px;
            margin-bottom: 20px;
          }
          .info {
            background: #E8F5E9;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
          }
          code {
            background: #f5f5f5;
            padding: 2px 6px;
            border-radius: 4px;
          }
        </style>
      </head>
      <body>
        <div class="success">✅ Xero Account Connected Successfully!</div>
        <div class="info">
          <p><strong>Tenant:</strong> ${tenantsResult.tenants[0].tenantName}</p>
          <p><strong>Tenant ID:</strong> <code>${tenantId}</code></p>
          <p>You can now use the chatbot to create invoices and quotations.</p>
        </div>
        <p>You can close this window and return to your application.</p>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('Callback error:', error);
    res.status(500).send('Authentication failed: ' + error.message);
  }
});

/**
 * Disconnect Xero account
 */
app.post('/xero/disconnect', (req, res) => {
  try {
    const sessionId = req.body.session_id || 'default';

    if (sessions.has(sessionId)) {
      sessions.delete(sessionId);
    }

    res.json({
      success: true,
      message: 'Xero account disconnected successfully'
    });

  } catch (error) {
    console.error('Disconnect error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Check Xero connection status
 */
app.get('/xero/status', (req, res) => {
  try {
    const sessionId = req.query.session_id || 'default';
    const session = getSession(sessionId);

    if (!session || !session.connected) {
      return res.json({
        connected: false,
        message: 'Xero account not connected. Please authenticate first.'
      });
    }

    res.json({
      connected: true,
      tenantName: session.tenantName,
      tenantId: session.tenantId
    });

  } catch (error) {
    console.error('Status check error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * MAIN CHAT ENDPOINT
 *
 * Handles user messages, integrates with GLM-4-Flash AI,
 * and creates invoices/quotations in Xero when requested
 */
app.post('/chat', async (req, res) => {
  try {
    const { message, session_id = 'default' } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message is required'
      });
    }

    // Get or create session
    let session = getSession(session_id);
    if (!session) {
      session = {
        conversationHistory: [],
        connected: false
      };
      setSession(session_id, session);
    }

    // Refresh token if needed
    if (session.connected && session.refreshToken && needsRefresh(session.expiresAt)) {
      console.log('Refreshing access token...');
      const refreshResult = await xeroClient.refreshAccessToken(session.refreshToken);

      if (refreshResult.success) {
        setSession(session_id, {
          accessToken: refreshResult.tokens.accessToken,
          refreshToken: refreshResult.tokens.refreshToken,
          expiresAt: refreshResult.tokens.expiresAt
        });
        session = getSession(session_id);
      }
    }

    // Get AI response from GLM-4-Flash
    const aiResponse = await glmClient.chatWithGLM(
      message,
      session.conversationHistory
    );

    if (!aiResponse.success) {
      return res.json({
        success: false,
        message: aiResponse.content,
        error: aiResponse.error
      });
    }

    // Update conversation history (keep last 10 messages)
    session.conversationHistory.push(
      { role: 'user', content: message },
      { role: 'assistant', content: aiResponse.content }
    );
    if (session.conversationHistory.length > 20) {
      session.conversationHistory = session.conversationHistory.slice(-20);
    }

    // If AI response is JSON (invoice/quotation request)
    if (aiResponse.isJSON && aiResponse.parsedJSON) {
      const invoiceData = aiResponse.parsedJSON;

      // Check if Xero is connected
      if (!session.connected || !session.accessToken) {
        return res.json({
          success: true,
          type: 'document_data',
          message: 'Here is the invoice/quotation data ready to be created in Xero.',
          data: invoiceData,
          xero_connected: false,
          note: 'Please connect Xero account first via GET /xero/auth'
        });
      }

      // Create invoice in Xero
      const xeroResult = await xeroClient.createInvoice(
        invoiceData,
        session.accessToken,
        session.tenantId
      );

      if (xeroResult.success) {
        res.json({
          success: true,
          type: 'invoice_created',
          message: `${aiResponse.content}\n\n✅ Invoice/Quotation created successfully in Xero!`,
          xero_invoice: xeroResult.invoice,
          xero_invoice_id: xeroResult.invoice.InvoiceID,
          xero_invoice_number: xeroResult.invoice.InvoiceNumber,
          invoice_url: `https://go.xero.com/AccountsReceivable/View.aspx?InvoiceID=${xeroResult.invoice.InvoiceID}`
        });
      } else {
        res.json({
          success: false,
          type: 'invoice_error',
          message: aiResponse.content,
          data: invoiceData,
          xero_error: xeroResult.error,
          details: xeroResult.details
        });
      }

    } else {
      // Regular text response from AI
      res.json({
        success: true,
        type: 'text',
        message: aiResponse.content,
        xero_connected: session.connected || false
      });
    }

  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get chat history
 */
app.get('/chat/history', (req, res) => {
  try {
    const sessionId = req.query.session_id || 'default';
    const session = getSession(sessionId);

    res.json({
      success: true,
      history: session ? session.conversationHistory : []
    });

  } catch (error) {
    console.error('History error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Clear chat history
 */
app.delete('/chat/history', (req, res) => {
  try {
    const sessionId = req.body.session_id || 'default';

    if (sessions.has(sessionId)) {
      setSession(sessionId, { conversationHistory: [] });
    }

    res.json({
      success: true,
      message: 'Chat history cleared'
    });

  } catch (error) {
    console.error('Clear history error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ==========================================
// ERROR HANDLER
// ==========================================
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log('╔═══════════════════════════════════════════════════════╗');
  console.log('║           Xero Chatbot Server Started                ║');
  console.log('╚═══════════════════════════════════════════════════════╝');
  console.log(`🚀 Server running on: http://localhost:${PORT}`);
  console.log(`📚 API Health: http://localhost:${PORT}/health`);
  console.log(`💬 Chat Endpoint: POST http://localhost:${PORT}/chat`);
  console.log(`🔐 Xero Auth: GET http://localhost:${PORT}/xero/auth`);
  console.log('');
  console.log('📖 Test the chatbot with:');
  console.log(`   curl -X POST http://localhost:${PORT}/chat \\`);
  console.log('   -H "Content-Type: application/json" \\');
  console.log('   -d \'{"message": "Hello! What can you do?"}\'');
  console.log('');
  console.log('📝 See README.md for complete documentation');
  console.log('╚═══════════════════════════════════════════════════════╝');
});

module.exports = app;
