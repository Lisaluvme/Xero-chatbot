/**
 * Netlify Function: Xero OAuth Callback
 *
 * Handles Xero OAuth callback, exchanges code for tokens
 *
 * Usage: GET /.netlify/functions/xero-callback?code=xxx&state=xxx
 */

const xeroClient = require('../../backend/xeroClient');

// In-memory session storage (use Redis/database in production)
const sessions = new Map();

function setSession(id, data) {
  sessions.set(id, data);
}

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
    const code = params.get('code');
    const state = params.get('state');

    if (!code) {
      console.error('Callback: Missing authorization code');
      return {
        statusCode: 400,
        body: 'Missing authorization code'
      };
    }

    console.log('Callback: Received code, exchanging for token...');

    // Exchange authorization code for tokens
    const tokenResult = await xeroClient.exchangeCodeForToken(code);

    if (!tokenResult.success) {
      console.error('Callback: Token exchange failed:', tokenResult.error);
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          error: tokenResult.error
        })
      };
    }

    console.log('Callback: Token received, fetching tenants...');

    // Get tenants (organizations)
    const tenantsResult = await xeroClient.getTenants(tokenResult.tokens.accessToken);

    if (!tenantsResult.success) {
      console.error('Callback: Get tenants failed:', tenantsResult.error);
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          error: tenantsResult.error
        })
      };
    }

    // Store tokens in session
    const tenantId = tenantsResult.tenants[0].tenantId;
    const sessionId = 'default';

    setSession(sessionId, {
      accessToken: tokenResult.tokens.accessToken,
      refreshToken: tokenResult.tokens.refreshToken,
      expiresAt: tokenResult.tokens.expiresAt,
      refreshAt: tokenResult.tokens.refreshAt,
      tenantId: tenantId,
      tenantName: tenantsResult.tenants[0].tenantName,
      connected: true
    });

    // Return HTML success page
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Xero Connected - Success</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }
          .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
          }
          .success-icon {
            font-size: 64px;
            margin-bottom: 20px;
          }
          h1 {
            color: #2D3748;
            margin-bottom: 10px;
            font-size: 28px;
          }
          .info-box {
            background: #F7FAFC;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
          }
          .info-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #E2E8F0;
          }
          .info-item:last-child {
            border-bottom: none;
          }
          .label {
            font-weight: 600;
            color: #4A5568;
          }
          .value {
            color: #667eea;
            font-weight: 500;
          }
          .note {
            color: #718096;
            font-size: 14px;
            line-height: 1.6;
            margin-top: 20px;
          }
          .btn-close {
            margin-top: 20px;
            padding: 12px 24px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
          }
          .btn-close:hover {
            background: #5568d3;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="success-icon">✅</div>
          <h1>Xero Account Connected!</h1>
          <div class="info-box">
            <div class="info-item">
              <span class="label">Organization:</span>
              <span class="value">${tenantsResult.tenants[0].tenantName}</span>
            </div>
            <div class="info-item">
              <span class="label">Tenant ID:</span>
              <span class="value">${tenantId.substring(0, 8)}...</span>
            </div>
            <div class="info-item">
              <span class="label">Status:</span>
              <span class="value">Ready</span>
            </div>
          </div>
          <p class="note">
            Your Xero account has been successfully connected.<br>
            You can now create invoices and quotations.
          </p>
          <p class="note">
            You can close this window and return to the chatbot.
          </p>
          <button class="btn-close" onclick="window.close()">Close Window</button>
        </div>
      </body>
      </html>
    `;

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'text/html',
        'Access-Control-Allow-Origin': '*'
      },
      body: html
    };

  } catch (error) {
    console.error('Callback error:', error);
    return {
      statusCode: 500,
      body: 'Authentication failed: ' + error.message
    };
  }
};
