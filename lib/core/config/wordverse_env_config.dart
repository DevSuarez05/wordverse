/// Configuración centralizada de entornos, variables `--dart-define`,
/// validación de entradas y enmascaramiento seguro de secretos (Fase 1 — WV-103).
library;

abstract final class WordverseEnvConfig {
  static const String clientVersion = '1.0.0+1';

  static const String defaultSupabaseUrl =
      'https://your-project.supabase.co/rest/v1';
  static const String defaultShestApiUrl = 'https://api.shestlabs.com/v1';

  static const String envSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: defaultSupabaseUrl,
  );

  static const String envSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String envShestApiUrl = String.fromEnvironment(
    'SHEST_API_URL',
    defaultValue: defaultShestApiUrl,
  );

  static const String envShestToken = String.fromEnvironment('SHEST_API_TOKEN');

  static const bool envStrictHttp = bool.fromEnvironment(
    'WORDVERSE_STRICT_HTTP',
    defaultValue: false,
  );

  static const String defaultAiLocale = String.fromEnvironment(
    'WORDVERSE_AI_DEFAULT_LOCALE',
    defaultValue: 'es',
  );

  static const bool envAiTranslateEnabled = bool.fromEnvironment(
    'WORDVERSE_AI_TRANSLATE_ENABLED',
    defaultValue: true,
  );

  static const String envAiTranslateEndpoint = String.fromEnvironment(
    'WORDVERSE_AI_TRANSLATE_ENDPOINT',
    defaultValue: '',
  );

  static const Duration defaultHttpTimeout = Duration(seconds: 5);
  static const Duration healthCheckTimeout = Duration(seconds: 6);

  /// Enmascara cualquier token JWT o API key para que nunca se filtre en logs
  /// ni en el bus de eventos (ej: `eyJhbG...9xK2`).
  static String maskSecret(String secret) {
    final String trimmed = secret.trim();
    if (trimmed.isEmpty) return '<empty>';
    if (trimmed.length <= 8) return '****';
    final String prefix = trimmed.substring(0, 4);
    final String suffix = trimmed.substring(trimmed.length - 4);
    return '$prefix...$suffix';
  }

  /// Verifica si una URL remota es sintácticamente válida (HTTP/HTTPS) y no es el placeholder por defecto.
  static bool isConfiguredRemoteUrl(String url) {
    final String clean = url.trim();
    if (clean.isEmpty ||
        clean.contains('your-project.supabase.co') ||
        clean.startsWith('mock://')) {
      return false;
    }
    final Uri? parsed = Uri.tryParse(clean);
    return parsed != null &&
        (parsed.scheme == 'https' || parsed.scheme == 'http') &&
        parsed.host.isNotEmpty;
  }

  /// Normaliza una URL base eliminando barras finales redundantes y añadiendo
  /// `/rest/v1` automáticamente para proyectos Supabase si se omitió.
  static String normalizeRestUrl(String rawUrl) {
    final String clean = rawUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (clean.contains('.supabase.co') && !clean.endsWith('/rest/v1')) {
      return '$clean/rest/v1';
    }
    return clean;
  }

  /// Genera un identificador de traza único para correlacionar llamadas Frontend -> Backend.
  static String generateTraceId([String prefix = 'WV-TRC']) {
    final int micros = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$micros';
  }
}
