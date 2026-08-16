const mobileCallback = 'com.example.daegil_app://login-callback/';

Deno.serve((request) => {
  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ code: 'METHOD_NOT_ALLOWED' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const incoming = new URL(request.url);
  const params = new URLSearchParams();
  for (const name of [
    'code',
    'state',
    'error',
    'error_code',
    'error_description',
  ]) {
    const value = incoming.searchParams.get(name);
    if (value != null) params.set(name, value);
  }

  const query = params.toString();
  const location = query ? `${mobileCallback}?${query}` : mobileCallback;

  return new Response('', {
    status: 302,
    headers: {
      Location: location,
      'Cache-Control': 'no-store',
    },
  });
});
