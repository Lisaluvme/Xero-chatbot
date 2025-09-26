export async function handler(event, context) {
  try {
    const baseUrl = "https://www.smartgencloudplus.com/yewu/third/alarm/list";
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

    const data = await response.json();

    // Filter out Mains Failure alarms
    if (Array.isArray(data)) {
      const filteredData = data.filter(alarm =>
        !alarm.alarmType?.toLowerCase().includes('mains failure') &&
        !alarm.description?.toLowerCase().includes('mains failure') &&
        !alarm.message?.toLowerCase().includes('mains failure')
      );
      return {
        statusCode: response.status,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(filteredData, null, 2),
      };
    }

    return {
      statusCode: response.status,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data, null, 2),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
}
