/**
 * Netlify Function: Check Xero Connection Status
 *
 * Returns whether Xero is connected and tenant info
 *
 * Usage: GET /.netlify/functions/status?session_id=xxx
 */

// In-memory session storage (use Redis/database in production)
const sessions = new Map();

function getSession(id) {
  return sessions.get(id);
}

exports.handler = async (event, context) => {
  try {
    // Only allow GET requests
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ success: false, error: 'Method not allowed' })
      };
    }

    const params = new URLSearchParams(event.queryStringParameters || '');
    const sessionId = params.get('session_id') || 'default';
    const session = getSession(sessionId);

    if (!session || !session.connected) {
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          connected: false,
          message: 'Xero account not connected. Please authorize first.'
        })
      };
    }

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        connected: true,
        tenantName: session.tenantName,
        tenantId: session.tenantId
      })
    };

  } catch (error) {
    console.error('Status check error:', error);
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
