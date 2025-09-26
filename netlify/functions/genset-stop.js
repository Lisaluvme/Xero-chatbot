export async function handler(event, context) {
  try {
    const url = "https://www.smartgencloudplus.com/yewu/third/genset/stop";
    const method = event.httpMethod || 'POST';
    const headers = { ...event.headers };
    delete headers['host']; // Remove host header as it's for the function

    const response = await fetch(url + (event.rawQuery ? '?' + event.rawQuery : ''), {
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
