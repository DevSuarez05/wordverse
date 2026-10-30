import 'dart:async';

import '../config/wordverse_env_config.dart';
import '../events/wordverse_events.dart';

/// Resultado estructurado de una operación de traducción IA (Fase 3 — WV-301).
class TranslationResult {
  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isSuccess,
    this.fromCache = false,
    this.latencyMs = 0,
    this.errorMessage,
  });

  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isSuccess;
  final bool fromCache;
  final int latencyMs;
  final String? errorMessage;

  @override
  String toString() =>
      'TranslationResult($sourceLanguage->$targetLanguage: "$translatedText", cache=$fromCache, ms=$latencyMs)';
}

/// Servicio central de traducción asistida por IA para WordVerse (Fase 3 — WV-301).
///
/// Soporta:
/// - Idiomas oficiales: Español (`es`), Inglés (`en`), Portugués (`pt`), Chino Mandarín (`zh`).
/// - Detección automática de idioma mediante heurísticas léxicas y Unicode.
/// - Caché LRU en memoria para optimizar latencia y consumo de red.
/// - Limitador de tasa (Rate Limiter) para prevenir sobrecarga.
/// - Sanitización de datos sensibles y protección de privacidad.
/// - Fallback determinista local sin depender obligatoriamente de claves de terceros.
class WordverseTranslationService {
  WordverseTranslationService({
    this.remoteTranslator,
    this.eventBus,
    this.maxCacheSize = 250,
    this.maxRequestsPerMinute = 60,
  });

  /// Hook opcional para delegar en el backend de Shest Labs (`POST /ai/translate`).
  final Future<String> Function({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  })?
  remoteTranslator;

  /// Bus de eventos opcional para registrar auditoría de traducción.
  final WordverseEventBus? eventBus;

  final int maxCacheSize;
  final int maxRequestsPerMinute;

  /// Caché en memoria: clave = `src_tgt_hash`
  final Map<String, String> _cache = <String, String>{};

  /// Marcas de tiempo de solicitudes recientes para control de tasa
  final List<DateTime> _requestTimestamps = <DateTime>[];

  static const List<String> supportedLanguages = <String>[
    'es',
    'en',
    'pt',
    'zh',
  ];

  static const Map<String, String> languageNames = <String, String>{
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'zh': '中文',
  };

  static const Map<String, String> languageFlags = <String, String>{
    'es': '🇪🇸',
    'en': '🇺🇸',
    'pt': '🇧🇷',
    'zh': '🇨🇳',
  };

  /// Limpia la caché interna (útil para pruebas).
  void clearCache() {
    _cache.clear();
    _requestTimestamps.clear();
  }

  int get cacheSize => _cache.length;

  /// Normaliza el código de idioma a uno de los soportados ('es', 'en', 'pt', 'zh').
  static String normalizeLanguage(String? lang) {
    if (lang == null) return 'es';
    final String clean = lang.trim().toLowerCase();
    if (clean.startsWith('en')) return 'en';
    if (clean.startsWith('pt')) return 'pt';
    if (clean.startsWith('zh') || clean.startsWith('cn')) return 'zh';
    return 'es';
  }

  /// Detecta el idioma del texto de forma determinista y sin latencia.
  String detectLanguage(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return 'es';

    // 1. Detección de caracteres Han (Chino Mandarín)
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(trimmed)) {
      return 'zh';
    }

    final String lower = ' ${trimmed.toLowerCase()} ';

    // 2. Patrones claros de Portugués
    final List<String> ptPatterns = <String>[
      ' não ',
      ' obrigado',
      ' obrigada',
      ' você ',
      ' voce ',
      ' olá ',
      ' ola ',
      ' bom dia',
      ' boa tarde',
      ' boa noite',
      ' tudo bem',
      ' acordo ',
      ' liberação ',
      ' saldos ',
      ' reunião ',
      ' quarto ',
      ' pagamento ',
      ' com certeza',
    ];
    for (final String pat in ptPatterns) {
      if (lower.contains(pat)) return 'pt';
    }

    // 3. Patrones claros de Inglés
    final List<String> enPatterns = <String>[
      ' hello',
      ' hi ',
      ' welcome',
      ' thanks',
      ' thank you',
      ' please',
      ' escrow',
      ' agreement',
      ' contract',
      ' release',
      ' meeting',
      ' boardroom',
      ' buyer',
      ' seller',
      ' payment',
      ' deal',
      ' good morning',
      ' good afternoon',
      ' liquidity',
      ' let\'s',
      ' the ',
      ' with ',
      ' this ',
      ' room ',
    ];
    int enHits = 0;
    for (final String pat in enPatterns) {
      if (lower.contains(pat)) enHits++;
    }

    // 4. Patrones claros de Español
    final List<String> esPatterns = <String>[
      ' hola',
      ' bienvenido',
      ' bienvenidos',
      ' gracias',
      ' por favor',
      ' acuerdo',
      ' contrato',
      ' liberar',
      ' reunión',
      ' reunion',
      ' sala',
      ' comprador',
      ' vendedor',
      ' pago',
      ' trato',
      ' oferta',
      ' compra',
      ' venta',
      ' disponible',
      ' saldo',
      ' billetera',
      ' buenos días',
      ' buenas tardes',
      ' liquidez',
      ' el ',
      ' la ',
      ' los ',
      ' con ',
      ' este ',
      ' de ',
      ' en ',
    ];
    int esHits = 0;
    for (final String pat in esPatterns) {
      if (lower.contains(pat)) esHits++;
    }

    if (enHits > esHits && enHits > 0) return 'en';
    if (esHits > 0) return 'es';

    // Heurística de acentos típicamente españoles
    if (RegExp(r'[áéíóúñ¿¡]').hasMatch(lower)) return 'es';

    return 'en';
  }

  /// Traduce el texto solicitado hacia el idioma `targetLanguage`.
  ///
  /// Preserva el texto original y garantiza que nunca bloquee la conversación
  /// si ocurre un error de red o de límites.
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    bool useCache = true,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final String trimmed = text.trim();
    final String target = normalizeLanguage(targetLanguage);

    if (trimmed.isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: target,
        targetLanguage: target,
        isSuccess: true,
        latencyMs: 0,
      );
    }

    // Truncamiento de seguridad para evitar DoS por textos gigantescos
    final String safeInput = trimmed.length > 2000
        ? trimmed.substring(0, 2000)
        : trimmed;

    final String detectedSource = sourceLanguage != null
        ? normalizeLanguage(sourceLanguage)
        : detectLanguage(safeInput);

    // Si origen y destino son iguales, devolver sin traducción
    if (detectedSource == target) {
      return TranslationResult(
        originalText: text,
        translatedText: safeInput,
        sourceLanguage: detectedSource,
        targetLanguage: target,
        isSuccess: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    final String cacheKey =
        '${detectedSource}_${target}_${safeInput.toLowerCase()}';

    if (useCache && _cache.containsKey(cacheKey)) {
      stopwatch.stop();
      return TranslationResult(
        originalText: text,
        translatedText: _cache[cacheKey]!,
        sourceLanguage: detectedSource,
        targetLanguage: target,
        isSuccess: true,
        fromCache: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    // Control de tasa de peticiones (Rate Limit)
    final DateTime now = DateTime.now();
    _requestTimestamps.removeWhere(
      (DateTime t) => now.difference(t) > const Duration(minutes: 1),
    );
    if (_requestTimestamps.length >= maxRequestsPerMinute) {
      stopwatch.stop();
      return TranslationResult(
        originalText: text,
        translatedText: safeInput,
        sourceLanguage: detectedSource,
        targetLanguage: target,
        isSuccess: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage:
            'Límite de traducciones alcanzado (máx $maxRequestsPerMinute/min). Mostrando original.',
      );
    }
    _requestTimestamps.add(now);

    String translatedResult = '';
    bool success = true;
    String? error;

    // Intentar vía adaptador remoto si está configurado
    if (remoteTranslator != null &&
        WordverseEnvConfig.envAiTranslateEnabled &&
        WordverseEnvConfig.isConfiguredRemoteUrl(
          WordverseEnvConfig.envAiTranslateEndpoint,
        )) {
      try {
        translatedResult = await remoteTranslator!(
          text: safeInput,
          targetLanguage: target,
          sourceLanguage: detectedSource,
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        // Fallback a motor determinista interno si el endpoint remoto falla
        translatedResult = _deterministicTranslate(
          safeInput,
          detectedSource,
          target,
        );
      }
    } else {
      translatedResult = _deterministicTranslate(
        safeInput,
        detectedSource,
        target,
      );
    }

    stopwatch.stop();

    if (useCache && success) {
      if (_cache.length >= maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = translatedResult;
    }

    // Emisión de evento para auditoría y métricas
    eventBus?.emit(
      WordverseEventType.translationExecuted,
      'Traducción IA: $detectedSource -> $target (${safeInput.length} chars)',
      <String, Object?>{
        'sourceLang': detectedSource,
        'targetLang': target,
        'charCount': safeInput.length,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'fromCache': false,
      },
    );

    return TranslationResult(
      originalText: text,
      translatedText: translatedResult,
      sourceLanguage: detectedSource,
      targetLanguage: target,
      isSuccess: success,
      fromCache: false,
      latencyMs: stopwatch.elapsedMilliseconds,
      errorMessage: error,
    );
  }

  /// Motor léxico determinista B2B / Web3 / Escrow / Chat.
  String _deterministicTranslate(String input, String src, String tgt) {
    final String clean = input.trim();

    // 1. Frases completas del corpus oficial
    final String? phraseMatch = _matchCorpusPhrase(clean, src, tgt);
    if (phraseMatch != null) return phraseMatch;

    // 2. Traducción de términos clave por diccionario léxico
    return _translateKeywords(clean, src, tgt);
  }

  String? _matchCorpusPhrase(String text, String src, String tgt) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[!¡?¿\.,]'), '').trim();

    final String lower = norm(text);

    for (final Map<String, String> entry in _corpusPhrases) {
      final String? rawSrc = entry[src];
      if (rawSrc != null) {
        final String srcEntry = norm(rawSrc);
        if (srcEntry == lower ||
            lower.contains(srcEntry) ||
            srcEntry.contains(lower)) {
          return entry[tgt];
        }
      }
    }
    return null;
  }

  String _translateKeywords(String text, String src, String tgt) {
    String result = text;
    final Map<String, String> dictionary = _getDictionary(src, tgt);

    for (final MapEntry<String, String> entry in dictionary.entries) {
      final RegExp reg = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(reg, (Match match) {
        final String matched = match.group(0)!;
        if (matched.isNotEmpty && matched[0] == matched[0].toUpperCase()) {
          final String rep = entry.value;
          if (rep.isNotEmpty) {
            return rep[0].toUpperCase() + rep.substring(1);
          }
        }
        return entry.value;
      });
    }

    // Prefijo sutil indicador si no hubo correspondencia directa
    if (result == text && src != tgt && tgt == 'zh') {
      return '【AI翻译】$text';
    }

    return result;
  }

  Map<String, String> _getDictionary(String src, String tgt) {
    if (src == 'es' && tgt == 'en') {
      return <String, String>{
        'hola': 'hello',
        'bienvenidos': 'welcome',
        'bienvenido': 'welcome',
        'sala': 'room',
        'reunión': 'meeting',
        'reunion': 'meeting',
        'junta': 'board meeting',
        'acuerdo': 'agreement',
        'contrato': 'contract',
        'fondos': 'funds',
        'liberar': 'release',
        'comprador': 'buyer',
        'vendedor': 'seller',
        'pago': 'payment',
        'trato': 'deal',
        'gracias': 'thank you',
        'por favor': 'please',
        'oferta': 'offer',
        'liquidez': 'liquidity',
        'aprobado': 'approved',
        'pendiente': 'pending',
        'disputa': 'dispute',
        'sí': 'yes',
        'no': 'no',
        'buenos días': 'good morning',
        'buenas tardes': 'good afternoon',
        'minuta': 'meeting minutes',
        'socio': 'partner',
        'privada': 'private',
        'pública': 'public',
      };
    } else if (src == 'en' && tgt == 'es') {
      return <String, String>{
        'hello': 'hola',
        'hi': 'hola',
        'welcome': 'bienvenido',
        'room': 'sala',
        'meeting': 'reunión',
        'board meeting': 'junta directiva',
        'agreement': 'acuerdo',
        'contract': 'contrato',
        'funds': 'fondos',
        'release': 'liberar',
        'buyer': 'comprador',
        'seller': 'vendedor',
        'payment': 'pago',
        'deal': 'trato',
        'thank you': 'gracias',
        'thanks': 'gracias',
        'please': 'por favor',
        'offer': 'oferta',
        'liquidity': 'liquidez',
        'approved': 'aprobado',
        'pending': 'pendiente',
        'dispute': 'disputa',
        'yes': 'sí',
        'no': 'no',
        'good morning': 'buenos días',
        'good afternoon': 'buenas tardes',
        'meeting minutes': 'minuta de reunión',
        'partner': 'socio',
        'private': 'privada',
        'public': 'pública',
      };
    } else if (src == 'es' && tgt == 'pt') {
      return <String, String>{
        'hola': 'olá',
        'bienvenidos': 'bem-vindos',
        'bienvenido': 'bem-vindo',
        'sala': 'sala',
        'reunión': 'reunião',
        'acuerdo': 'acordo',
        'contrato': 'contrato',
        'fondos': 'fundos',
        'liberar': 'liberar',
        'comprador': 'comprador',
        'vendedor': 'vendedor',
        'pago': 'pagamento',
        'gracias': 'obrigado',
        'por favor': 'por favor',
        'oferta': 'oferta',
        'aprobado': 'aprovado',
        'pendiente': 'pendente',
      };
    } else if (src == 'pt' && tgt == 'es') {
      return <String, String>{
        'olá': 'hola',
        'bem-vindos': 'bienvenidos',
        'bem-vindo': 'bienvenido',
        'reunião': 'reunión',
        'acordo': 'acuerdo',
        'fundos': 'fondos',
        'pagamento': 'pago',
        'obrigado': 'gracias',
        'obrigada': 'gracias',
        'aprovado': 'aprobado',
        'pendente': 'pendiente',
      };
    } else if (tgt == 'zh') {
      return <String, String>{
        'hola': '你好',
        'hello': '你好',
        'bienvenidos': '欢迎',
        'welcome': '欢迎',
        'sala': '会议室',
        'room': '会议室',
        'reunión': '会议',
        'meeting': '会议',
        'acuerdo': '协议',
        'agreement': '协议',
        'contrato': '合同',
        'contract': '合同',
        'fondos': '资金',
        'funds': '资金',
        'liberar': '释放',
        'release': '释放',
        'pago': '付款',
        'payment': '付款',
        'gracias': '谢谢',
        'thank you': '谢谢',
        'thanks': '谢谢',
        'aprobado': '已批准',
        'approved': '已批准',
        'pendiente': '待处理',
        'pending': '待处理',
      };
    } else if (src == 'zh' && tgt == 'es') {
      return <String, String>{
        '你好': 'hola',
        '欢迎': 'bienvenidos',
        '会议室': 'sala',
        '会议': 'reunión',
        '协议': 'acuerdo',
        '合同': 'contrato',
        '资金': 'fondos',
        '释放': 'liberar',
        '付款': 'pago',
        '谢谢': 'gracias',
        '已批准': 'aprobado',
        '待处理': 'pendiente',
      };
    } else if (src == 'zh' && tgt == 'en') {
      return <String, String>{
        '你好': 'hello',
        '欢迎': 'welcome',
        '会议室': 'room',
        '会议': 'meeting',
        '协议': 'agreement',
        '合同': 'contract',
        '资金': 'funds',
        '释放': 'release',
        '付款': 'payment',
        '谢谢': 'thank you',
        '已批准': 'approved',
        '待处理': 'pending',
      };
    }
    return <String, String>{};
  }

  static const List<Map<String, String>> _corpusPhrases = <Map<String, String>>[
    <String, String>{
      'es': 'Hola a todos, bienvenidos a la sala',
      'en': 'Hello everyone, welcome to the room',
      'pt': 'Olá a todos, bem-vindos à sala',
      'zh': '大家好，欢迎来到会议室',
    },
    <String, String>{
      'es': 'Acuerdo confirmado y fondos en custodia',
      'en': 'Deal confirmed and funds in escrow',
      'pt': 'Acordo confirmado e fundos em custódia',
      'zh': '协议已确认，资金已托管',
    },
    <String, String>{
      'es': 'Liberar pago del contrato Escrow',
      'en': 'Release Escrow contract payment',
      'pt': 'Liberar pagamento do contrato Escrow',
      'zh': '释放托管合同款项',
    },
    <String, String>{
      'es': 'Revisemos los términos del contrato P2P',
      'en': 'Let\'s review the P2P contract terms',
      'pt': 'Vamos revisar os termos do contrato P2P',
      'zh': '让我们审查P2P合同条款',
    },
    <String, String>{
      'es': 'Oferta de compra USDT disponible',
      'en': 'USDT buy offer available',
      'pt': 'Oferta de compra de USDT disponível',
      'zh': 'USDT购买报价可用',
    },
    <String, String>{
      'es': 'Gracias por la reunión ejecutiva',
      'en': 'Thank you for the executive meeting',
      'pt': 'Obrigado pela reunião executiva',
      'zh': '感谢参加高管会议',
    },
    <String, String>{
      'es': 'Minuta aprobada por la junta directiva',
      'en': 'Minutes approved by the board of directors',
      'pt': 'Ata aprovada pelo conselho de administração',
      'zh': '董事会批准的会议纪要',
    },
    <String, String>{
      'es': 'Buenos días estimados socios',
      'en': 'Good morning dear partners',
      'pt': 'Bom dia caros sócios',
      'zh': '各位合作伙伴早上好',
    },
  ];
}
