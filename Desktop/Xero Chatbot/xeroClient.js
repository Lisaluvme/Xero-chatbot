/**
 * Xero API Client
 *
 * This module handles all Xero API interactions including:
 * - OAuth2 authentication
 * - Creating invoices and quotations
 * - Token refresh handling
 */

const axios = require('axios');
const crypto = require('crypto');

/**
 * Generate Xero OAuth2 authorization URL
 *
 * @returns {string} - Authorization URL for user to visit
 */
function getAuthorizationUrl() {
  const clientId = process.env.XERO_CLIENT_ID;
  const redirectUri = process.env.XERO_REDIRECT_URI;
  const scope = process.env.XERO_SCOPE || 'accounting.transactions accounting.contacts accounting.settings offline_access';

  // Generate state parameter for security
  const state = crypto.randomBytes(16).toString('hex');

  const authUrl = `https://login.xero.com/identity/connect/authorize?` +
    `response_type=code&` +
    `client_id=${clientId}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `scope=${encodeURIComponent(scope)}&` +
    `state=${state}`;

  return { url: authUrl, state: state };
}

/**
 * Exchange authorization code for access token
 *
 * @param {string} code - Authorization code from callback
 * @returns {Promise<Object>} - Token response with access_token, refresh_token, etc.
 */
async function exchangeCodeForToken(code) {
  try {
    const response = await axios.post(
      'https://identity.xero.com/oauth/token',
      new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: process.env.XERO_REDIRECT_URI,
        client_id: process.env.XERO_CLIENT_ID,
        client_secret: process.env.XERO_CLIENT_SECRET
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    const tokenData = {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresIn: response.data.expires_in,
      tokenType: response.data.token_type,
      expiresAt: Date.now() + (response.data.expires_in * 1000)
    };

    return {
      success: true,
      tokens: tokenData
    };

  } catch (error) {
    console.error('Token exchange error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

/**
 * Refresh access token using refresh token
 *
 * @param {string} refreshToken - Refresh token
 * @returns {Promise<Object>} - New token response
 */
async function refreshAccessToken(refreshToken) {
  try {
    const response = await axios.post(
      'https://identity.xero.com/oauth/token',
      new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
        client_id: process.env.XERO_CLIENT_ID,
        client_secret: process.env.XERO_CLIENT_SECRET
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    const tokenData = {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresIn: response.data.expires_in,
      tokenType: response.data.token_id,
      expiresAt: Date.now() + (response.data.expires_in * 1000)
    };

    return {
      success: true,
      tokens: tokenData
    };

  } catch (error) {
    console.error('Token refresh error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

/**
 * Get all tenants for the authenticated Xero organization
 *
 * @param {string} accessToken - Valid access token
 * @returns {Promise<Object>} - List of tenants
 */
async function getTenants(accessToken) {
  try {
    const response = await axios.get(
      'https://api.xero.com/Connections',
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return {
      success: true,
      tenants: response.data
    };

  } catch (error) {
    console.error('Get tenants error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

/**
 * Create an invoice or quotation in Xero
 *
 * @param {Object} invoiceData - Invoice/quotation data
 * @param {string} accessToken - Valid access token
 * @param {string} tenantId - Xero tenant ID
 * @returns {Promise<Object>} - Created invoice response
 */
async function createInvoice(invoiceData, accessToken, tenantId) {
  try {
    // Build Xero API invoice object
    const xeroInvoice = {
      Type: invoiceData.type || 'ACCREC', // ACCREC = Accounts Receivable
      Contact: {
        Name: invoiceData.customer_name || 'Customer',
        ContactNumber: invoiceData.customer_code || ''
      },
      Date: invoiceData.date || new Date().toISOString().split('T')[0],
      DueDate: invoiceData.due_date || invoiceData.date,
      LineItems: invoiceData.line_items.map(item => ({
        Description: item.description,
        Quantity: item.quantity || 1,
        UnitAmount: item.unit_amount || 0,
        TaxType: item.tax_type || 'NONE',
        AccountCode: item.account_code || '200'
      })),
      Status: invoiceData.status || 'DRAFT', // DRAFT or SUBMITTED
      Reference: invoiceData.reference || '',
      CurrencyCode: invoiceData.currency_code || 'MYR'
    };

    // Add line amount types if provided
    if (invoiceData.line_amount_types) {
      xeroInvoice.LineAmountTypes = invoiceData.line_amount_types;
    }

    // Make API request to create invoice
    const response = await axios.put(
      `https://api.xero.com/api.xro/2.0/Invoices`,
      { Invoices: [xeroInvoice] },
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Xero-tenant-id': tenantId,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      }
    );

    return {
      success: true,
      invoice: response.data.Invoices[0],
      message: 'Invoice/Quotation created successfully in Xero'
    };

  } catch (error) {
    console.error('Create invoice error:', error.response?.data || error.message);

    // Extract Xero error messages
    let errorMessage = 'Failed to create invoice in Xero';
    if (error.response?.data?.Problem) {
      const problems = error.response.data.Problem;
      if (Array.isArray(problems)) {
        errorMessage = problems.map(p => p.Message).join(', ');
      } else {
        errorMessage = problems.Message || errorMessage;
      }
    }

    return {
      success: false,
      error: errorMessage,
      details: error.response?.data
    };
  }
}

/**
 * Get contact by name or create new one
 *
 * @param {string} contactName - Contact name to search
 * @param {string} accessToken - Valid access token
 * @param {string} tenantId - Xero tenant ID
 * @returns {Promise<Object>} - Contact data
 */
async function getOrCreateContact(contactName, accessToken, tenantId) {
  try {
    // First, try to find existing contact
    const searchResponse = await axios.get(
      `https://api.xero.com/api.xro/2.0/Contacts?where=Name=="${encodeURIComponent(contactName)}"`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Xero-tenant-id': tenantId,
          'Accept': 'application/json'
        }
      }
    );

    if (searchResponse.data.Contacts && searchResponse.data.Contacts.length > 0) {
      return {
        success: true,
        contact: searchResponse.data.Contacts[0],
        created: false
      };
    }

    // If not found, create new contact
    const createResponse = await axios.put(
      `https://api.xero.com/api.xro/2.0/Contacts`,
      {
        Contacts: [{
          Name: contactName
        }]
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Xero-tenant-id': tenantId,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      }
    );

    return {
      success: true,
      contact: createResponse.data.Contacts[0],
      created: true
    };

  } catch (error) {
    console.error('Contact operation error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

/**
 * Get all invoices (with optional filtering)
 *
 * @param {string} accessToken - Valid access token
 * @param {string} tenantId - Xero tenant ID
 * @param {Object} filters - Optional filters (status, date, etc.)
 * @returns {Promise<Object>} - List of invoices
 */
async function getInvoices(accessToken, tenantId, filters = {}) {
  try {
    let url = 'https://api.xero.com/api.xro/2.0/Invoices';

    // Add query parameters if provided
    const params = [];
    if (filters.status) {
      params.push(`Status=${filters.status}`);
    }
    if (params.length > 0) {
      url += '?' + params.join('&');
    }

    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Xero-tenant-id': tenantId,
        'Accept': 'application/json'
      }
    });

    return {
      success: true,
      invoices: response.data.Invoices || []
    };

  } catch (error) {
    console.error('Get invoices error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

module.exports = {
  getAuthorizationUrl,
  exchangeCodeForToken,
  refreshAccessToken,
  getTenants,
  createInvoice,
  getOrCreateContact,
  getInvoices
};
