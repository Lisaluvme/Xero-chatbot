const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
    }),
    databaseURL: process.env.FIREBASE_DATABASE_URL
  });
}

const db = admin.firestore();

exports.handler = async (event, context) => {
  try {
    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({ error: 'Method not allowed' }),
      };
    }

    // Verify Firebase authentication
    const authHeader = event.headers.authorization || event.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized: No token provided' }),
      };
    }

    const idToken = authHeader.split('Bearer ')[1];
    let decodedToken;

    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized: Invalid token' }),
      };
    }

    const userEmail = decodedToken.email;
    if (!userEmail) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'User email not found in token' }),
      };
    }

    // Get customer-specific credentials from headers
    const customerUtoken = event.headers['x-customer-utoken'];
    const customerApiUrl = event.headers['x-customer-api-url'];

    if (!customerUtoken) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          success: false,
          message: 'No UToken found. Please contact your administrator to get access to genset data.',
          gensetData: null
        }),
      };
    }

    // Use customer-specific API URL or default
    const baseUrl = customerApiUrl || 'https://www.smartgencloudplus.com/yewu/third';

    try {
      // Call the actual genset API with customer's credentials
      const gensetResponse = await fetch(`${baseUrl}/genset/list?utoken=${customerUtoken}`);

      if (!gensetResponse.ok) {
        return {
          statusCode: 200, // Return 200 to app, but indicate error in response
          body: JSON.stringify({
            success: false,
            message: `Failed to fetch genset data: ${gensetResponse.status} ${gensetResponse.statusText}`,
            gensetData: null
          }),
        };
      }

      const gensetData = await gensetResponse.json();

      // Process and return the genset data
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: true,
          message: 'Genset data retrieved successfully',
          gensetData: Array.isArray(gensetData) ? gensetData : []
        }),
      };

    } catch (apiError) {
      console.error('API call error:', apiError);
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: false,
          message: `API connection error: ${apiError.message}`,
          gensetData: null
        }),
      };
    }

  } catch (error) {
    console.error('Sync function error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        message: `Internal server error: ${error.message}`,
        gensetData: null
      }),
    };
  }
};
