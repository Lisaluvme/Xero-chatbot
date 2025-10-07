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

    const body = JSON.parse(event.body);
    const { adminEmail, userEmail, operation, utoken, newUtokens, confirm } = body;

    // Verify admin status
    if (!adminEmail) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Admin email required' }),
      };
    }

    const adminDoc = await db.collection('users').doc(adminEmail).get();
    if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
      return {
        statusCode: 403,
        body: JSON.stringify({ error: 'Unauthorized: Admin access required' }),
      };
    }

    // Step 1: Get user document
    const userDoc = await db.collection('users').doc(userEmail).get();
    if (!userDoc.exists) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: 'User not found' }),
      };
    }

    const userData = userDoc.data();
    const currentUtokens = userData.utokens || [];

    // If just retrieving current state
    if (!operation) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          userEmail,
          currentUtokens,
          message: 'Current utokens retrieved. Choose operation: add, remove, replace, or no'
        }),
      };
    }

    // Step 4: Handle operation
    let updateData = {};
    let needsConfirmation = false;
    let proposedUtokens = [...currentUtokens];

    switch (operation.toLowerCase()) {
      case 'add':
        if (!utoken) {
          return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Utoken required for add operation' }),
          };
        }
        updateData = {
          utokens: admin.firestore.FieldValue.arrayUnion(utoken),
          updatedAt: new Date().toISOString(),
        };
        proposedUtokens.push(utoken);
        needsConfirmation = true;
        break;

      case 'remove':
        if (!utoken) {
          return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Utoken required for remove operation' }),
          };
        }
        updateData = {
          utokens: admin.firestore.FieldValue.arrayRemove(utoken),
          updatedAt: new Date().toISOString(),
        };
        proposedUtokens = currentUtokens.filter(u => u !== utoken);
        needsConfirmation = true;
        break;

      case 'replace':
        if (!Array.isArray(newUtokens)) {
          return {
            statusCode: 400,
            body: JSON.stringify({ error: 'newUtokens array required for replace operation' }),
          };
        }
        updateData = {
          utokens: newUtokens,
          updatedAt: new Date().toISOString(),
        };
        proposedUtokens = newUtokens;
        needsConfirmation = true;
        break;

      case 'no':
        return {
          statusCode: 200,
          body: JSON.stringify({ message: 'Operation cancelled' }),
        };

      default:
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Invalid operation. Use: add, remove, replace, or no' }),
        };
    }

    // Step 8: Confirmation
    if (needsConfirmation && !confirm) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          userEmail,
          currentUtokens,
          proposedUtokens,
          message: 'Proposed changes ready. Set confirm=true to finalize'
        }),
      };
    }

    if (needsConfirmation && confirm) {
      // Apply changes using safe update methods
      await db.collection('users').doc(userEmail).update(updateData);

      // Return final result
      const finalDoc = await db.collection('users').doc(userEmail).get();
      const finalData = finalDoc.data();

      return {
        statusCode: 200,
        body: JSON.stringify({
          userEmail,
          updatedUtokens: finalData.utokens,
          createdAt: finalData.createdAt,
          updatedAt: finalData.updatedAt,
        }),
      };
    }

    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid request' }),
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
