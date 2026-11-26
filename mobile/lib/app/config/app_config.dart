const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  final value = _configuredApiBaseUrl.trim();
  final uri = Uri.tryParse(value);

  if (uri == null ||
      !uri.hasScheme ||
      !const {'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw StateError(
      'Configura una URL válida con --dart-define=API_BASE_URL=https://tu-api.example.com.',
    );
  }

  return value.replaceFirst(RegExp(r'/+$'), '');
}
