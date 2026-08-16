import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Receives the OAuth code that Supabase redirects to the Windows Site URL.
///
/// Supabase Flutter does not register a Windows deep-link listener for the
/// custom URI scheme used by mobile builds. A loopback callback keeps the
/// Windows flow local while allowing the SDK to exchange the PKCE code in the
/// same process that created the verifier.
class WindowsOAuthCallbackServer {
  WindowsOAuthCallbackServer._(this._server);

  static const host = 'localhost';
  static const port = 3000;

  final HttpServer _server;

  static Future<WindowsOAuthCallbackServer?> start() async {
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
        shared: true,
      );
      final callbackServer = WindowsOAuthCallbackServer._(server);
      server.listen(callbackServer._handleRequest);
      return callbackServer;
    } on SocketException {
      // A second app instance may already own the callback port. Keep the
      // process alive; the first instance can still finish the OAuth flow.
      return null;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final uri = request.uri;
    if (uri.path != '/' || !uri.queryParameters.containsKey('code')) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.text
        ..write('Not found');
      await request.response.close();
      return;
    }

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(
          '<!doctype html><title>대길 로그인 완료</title>'
          '<p>대길 앱으로 돌아가도 됩니다.</p>',
        );
    } on AuthException {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType.text
        ..write('로그인 처리에 실패했습니다. 앱에서 다시 시도해 주세요.');
    } catch (_) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.text
        ..write('로그인 처리 중 오류가 발생했습니다.');
    }
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}
