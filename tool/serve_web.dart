// Minimal static file server for the release web build (build/web).
//
// The `web-server` device only works in debug mode with the Dart Debug
// browser extension, which headless preview browsers do not have. Serving the
// AOT release build statically lets any browser run the app directly.
//
// Usage: dart tool/serve_web.dart [port]
import 'dart:io';

const _mimeTypes = <String, String>{
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args.first) : 8080;
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web not found — run `flutter build web` first.');
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Serving build/web at http://localhost:$port');

  await for (final request in server) {
    var path = request.uri.path;
    if (path == '/' || path.isEmpty) {
      path = '/index.html';
    }

    var file = File('${root.path}$path');
    // SPA fallback: unknown routes (e.g. /auth/callback) load the shell.
    if (!file.existsSync()) {
      file = File('${root.path}/index.html');
    }

    final ext = file.path.contains('.')
        ? file.path.substring(file.path.lastIndexOf('.'))
        : '';
    request.response.headers.contentType =
        ContentType.parse(_mimeTypes[ext] ?? 'application/octet-stream');
    request.response.headers.set('Cache-Control', 'no-store');

    try {
      await request.response.addStream(file.openRead());
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
    }
    await request.response.close();
  }
}
