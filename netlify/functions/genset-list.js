export async function handler(event, context) {
  try {
    const baseUrl = "https://www.smartgencloudplus.com/yewu/third/genset/list";
    const method = event.httpMethod || 'GET';
    const headers = { ...event.headers };
    delete headers['host']; // Remove host header as it's for the function

    // Build query params with utoken
    const params = new URLSearchParams(event.queryStringParameters || {});
    params.set('utoken', process.env.SMARTGEN_UTOKEN);
    const queryString = params.toString();
    const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;

    const response = await fetch(url, {
      method: method,
      headers: headers,
      body: event.body,
    });

    const data = await response.text();
    return {
      statusCode: response.status,
      headers: {
        'Content-Type': response.headers.get('content-type') || 'application/json',
      },
      body: data,
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
}
