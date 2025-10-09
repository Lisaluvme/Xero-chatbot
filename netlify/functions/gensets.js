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

exports.handler = async (event, context) => {
  try {
    // Only allow GET requests
    if (event.httpMethod !== 'GET') {
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

    // Get customer-specific credentials from headers - now supporting multiple
    let customerUtokens = [];
    let customerApiUrls = [];

    // Try to parse multiple utokens and api urls
    if (event.headers['x-customer-utokens']) {
      try {
        customerUtokens = JSON.parse(event.headers['x-customer-utokens']);
      } catch (e) {
        // Fallback to single utoken for backward compatibility
        customerUtokens = [event.headers['x-customer-utoken'] || event.headers['x-customer-utokens']].filter(Boolean);
      }
    } else if (event.headers['x-customer-utoken']) {
      // Backward compatibility
      customerUtokens = [event.headers['x-customer-utoken']];
    }

    if (event.headers['x-customer-api-urls']) {
      try {
        customerApiUrls = JSON.parse(event.headers['x-customer-api-urls']);
      } catch (e) {
        customerApiUrls = [event.headers['x-customer-api-url'] || event.headers['x-customer-api-urls']].filter(Boolean);
      }
    } else if (event.headers['x-customer-api-url']) {
      // Backward compatibility
      customerApiUrls = [event.headers['x-customer-api-url']];
    }

    if (customerUtokens.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: 'No utokens found. Please provide x-customer-utokens header or contact your administrator.'
        }),
      };
    }

    // If we have multiple utokens but only one api url, use the same api url for all
    if (customerApiUrls.length === 1 && customerUtokens.length > 1) {
      customerApiUrls = Array(customerUtokens.length).fill(customerApiUrls[0]);
    }

    // If we have multiple utokens but fewer api urls, use default for missing ones
    while (customerApiUrls.length < customerUtokens.length) {
      customerApiUrls.push('https://www.smartgencloudplus.com/yewu/third');
    }

    try {
      const allGensets = [];

      // Fetch gensets for each utoken
      for (let i = 0; i < customerUtokens.length; i++) {
        const utoken = customerUtokens[i];
        const apiUrl = customerApiUrls[i];

        try {
          const gensetResponse = await fetch(`${apiUrl}/genset/list?utoken=${utoken}`);

          if (gensetResponse.ok) {
            const gensetData = await gensetResponse.json();

            // Add gensets to the combined list
            if (Array.isArray(gensetData)) {
              // Add a source identifier to each genset
              const gensetsWithSource = gensetData.map(genset => ({
                ...genset,
                sourceUtoken: utoken.substring(0, 8) + '...', // Partial utoken for identification
                sourceApiUrl: apiUrl
              }));
              allGensets.push(...gensetsWithSource);
            }
          } else {
            console.warn(`Failed to fetch gensets for utoken ${utoken.substring(0, 8)}...: ${gensetResponse.status}`);
            // Continue with other utokens instead of failing completely
          }
        } catch (apiError) {
          console.error(`API call error for utoken ${utoken.substring(0, 8)}...:`, apiError);
          // Continue with other utokens
        }
      }

      // Return combined genset data
      return {
        statusCode: 200,
        body: JSON.stringify(allGensets),
      };

    } catch (apiError) {
      console.error('API call error:', apiError);
      return {
        statusCode: 200, // Return 200 to app, but indicate error in response
        body: JSON.stringify([]), // Return empty array on error
      };
    }

  } catch (error) {
    console.error('Gensets function error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
