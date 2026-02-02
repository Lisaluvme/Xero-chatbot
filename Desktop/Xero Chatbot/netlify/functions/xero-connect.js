/**
 * Netlify Function: Xero OAuth Connect
 *
 * Initiates Xero OAuth authorization flow
 *
 * Usage: GET /.netlify/functions/xero-connect?session_id=xxx
 */

const xeroClient = require('../../backend/xeroClient');

// In-memory session storage (use Redis/database in production)
const sessions = new Map();

exports.handler = async (event, context) => {
  try {
    // Only allow GET requests
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({ success: false, error: 'Method not allowed' })
      };
    }

    const params = new URLSearchParams(event.queryStringParameters || '');
    const sessionId = params.get('session_id');

    if (!sessionId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          success: false,
          error: 'session_id is required'
        })
      };
    }

    // Generate Xero authorization URL
    const { url, state } = xeroClient.getAuthorizationUrl();

    // Store state for CSRF verification during callback
    sessions.set(sessionId, { oauthState: state });

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: true,
        authorization_url: url,
        message: 'Visit this URL to authorize Xero access'
      })
    };

  } catch (error) {
    console.error('Connect error:', error);
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
