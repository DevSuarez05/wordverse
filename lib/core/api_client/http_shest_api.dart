import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/wordverse_env_config.dart';
import '../events/wordverse_events.dart';
import '../mocks/mock_shest_api.dart';
import '../models/shest_models.dart';
import 'shest_backend_adapter.dart';

/// Adaptador HTTP REST para conectar WordVerse con:
/// 1. Supabase PostgREST (`https://<project>.supabase.co/rest/v1`)
/// 2. Backend Productivo de Shest Labs en Java Spring Boot (`https://api.shestlabs.com/v1`)
///
/// Soporta lectura y escritura real sobre las tablas `users`, `wallets`, `meetings`
/// y `escrows` de [supabase_schema.sql], con fallback transparente a [MockShestApi]
/// cuando aún no se han ingresado credenciales remotas, o propagación estricta de
/// errores cuando [strictRemoteErrors] está habilitado (mitigación RSK-03).
class HttpShestApi implements ShestBackendAdapter {
  HttpShestApi({
    required this.baseUrl,
    required this.eventBus,
    required this.fallbackMock,
    this.apiKeyOrToken = '',
    this.environmentName = 'remote',
    this.strictRemoteErrors = WordverseEnvConfig.envStrictHttp,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  String baseUrl;
  String apiKeyOrToken;
  final String environmentName;
  bool strictRemoteErrors;
  final WordverseEventBus eventBus;
  final MockShestApi fallbackMock;
  final http.Client _http;

  bool get hasLiveCredentials =>
      WordverseEnvConfig.isConfiguredRemoteUrl(baseUrl) &&
      apiKeyOrToken.trim().isNotEmpty;

  bool get isSupabase =>
      _normalizedRestUrl.contains('supabase.co') ||
      _normalizedRestUrl.contains('/rest/v1');

  String? lastRefreshToken;

  String get maskedCredential => WordverseEnvConfig.maskSecret(apiKeyOrToken);

  String get _normalizedRestUrl => WordverseEnvConfig.normalizeRestUrl(baseUrl);

  Map<String, String> buildHeaders({String? traceId}) {
    final String activeTrace =
        traceId ?? WordverseEnvConfig.generateTraceId('WV-HTTP');
    return <String, String>{
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
      'X-WordVerse-Client-Version': WordverseEnvConfig.clientVersion,
      'X-WordVerse-Environment': environmentName,
      'X-WordVerse-Trace-Id': activeTrace,
      if (apiKeyOrToken.isNotEmpty) 'Authorization': 'Bearer $apiKeyOrToken',
      if (apiKeyOrToken.isNotEmpty && isSupabase) 'apikey': apiKeyOrToken,
    };
  }

  Map<String, String> get _headers => buildHeaders();

  Future<http.Response> _executeWith401Refresh({
    required Future<http.Response> Function(Map<String, String> headers) requestFn,
    required String operation,
    String? traceId,
  }) async {
    final String activeTrace =
        traceId ?? WordverseEnvConfig.generateTraceId('WV-HTTP');
    final http.Response res = await requestFn(buildHeaders(traceId: activeTrace));

    if (res.statusCode == 401 &&
        lastRefreshToken != null &&
        lastRefreshToken!.isNotEmpty) {
      eventBus.emit(
        WordverseEventType.authSessionChanged,
        'Token JWT expirado (HTTP 401 en $operation). Iniciando renovación automática...',
        <String, Object?>{'operation': operation, 'traceId': activeTrace},
      );
      try {
        await refreshSession(lastRefreshToken!);
        return await requestFn(buildHeaders(traceId: activeTrace));
      } catch (e) {
        eventBus.emit(
          WordverseEventType.apiError,
          'Renovación automática fallida tras 401 en $operation: $e',
          <String, Object?>{'operation': operation},
          WordverseEventSeverity.error,
          activeTrace,
        );
      }
    }

    return res;
  }

  void _handleRemoteHttpFailure({
    required String operation,
    required int statusCode,
    required String body,
    required String traceId,
  }) {
    eventBus.emit(
      WordverseEventType.apiError,
      '[$operation] HTTP $statusCode en $_normalizedRestUrl (cred: $maskedCredential)',
      <String, Object?>{
        'operation': operation,
        'statusCode': statusCode,
        'environment': environmentName,
        'maskedCredential': maskedCredential,
      },
      WordverseEventSeverity.error,
      traceId,
    );
    if (strictRemoteErrors) {
      final String code =
          (statusCode == 401 || statusCode == 403) ? 'UNAUTHORIZED' : 'HTTP_$statusCode';
      throw ShestApiException(
        code: code,
        userMessage:
            'Error del servidor Shest ($statusCode) en $operation.',
        statusCode: statusCode,
        traceId: traceId,
      );
    }
  }

  @override
  bool get simulateOffline => fallbackMock.simulateOffline;

  @override
  set simulateOffline(bool value) => fallbackMock.simulateOffline = value;

  void _checkOnline() {
    if (simulateOffline) {
      throw const ShestApiException(
        code: 'NETWORK_OFFLINE',
        userMessage:
            'Sin conexión con Shest API. Verifica tu red o usa Reconectar.',
      );
    }
  }

  ShestUser _parseUserRow(Map<String, Object?> row) {
    final String statusCode = (row['estado'] as String?) ?? 'AVAILABLE';
    final UserPresenceStatus status = UserPresenceStatus.values.firstWhere(
      (UserPresenceStatus s) => s.code == statusCode,
      orElse: () => UserPresenceStatus.available,
    );
    return ShestUser(
      id: (row['id'] as String?) ?? 'usr_1',
      name: (row['nombre'] as String?) ?? 'Usuario Shest',
      company: (row['empresa'] as String?) ?? 'Shest Partner',
      role: (row['cargo'] as String?) ?? 'Ejecutivo',
      description: (row['descripcion'] as String?) ?? '',
      avatarInitials: (row['avatar'] as String?) ?? 'US',
      avatarHexColor: (row['avatar_color'] as num?)?.toInt() ?? 0xFF00E5FF,
      status: status,
      isFavorite: (row['es_favorito'] as bool?) ?? false,
      isConnected: (row['conectado'] as bool?) ?? false,
    );
  }

  EscrowOperation _parseEscrowRow(Map<String, Object?> row) {
    final String stateStr = (row['estado'] as String?) ?? 'PENDING';
    final EscrowStatus status = EscrowStatus.values.firstWhere(
      (EscrowStatus s) => s.apiValue == stateStr,
      orElse: () => EscrowStatus.pending,
    );
    final String id = '${row['id'] ?? '45821'}';
    return EscrowOperation(
      id: id,
      creatorId: (row['creador_id'] as String?) ?? 'usr_1',
      creatorName: (row['creador_nombre'] as String?) ?? 'Daniel (Tú)',
      counterpartyId: (row['contraparte_id'] as String?) ?? 'usr_2',
      counterpartyName:
          (row['contraparte_nombre'] as String?) ?? 'Valeria Méndez',
      amount: (row['monto'] as num?)?.toDouble() ?? 0.0,
      currency: (row['moneda'] as String?) ?? 'USDT',
      description: (row['descripcion'] as String?) ?? '',
      conditions: (row['condiciones'] as String?) ?? '',
      status: status,
      createdAt:
          DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now(),
      historyLog: <String>['Sincronizado desde Supabase/Shest API ($stateStr)'],
    );
  }

  WordverseMeeting _parseMeetingRow(Map<String, Object?> row) {
    final String typeLabel = (row['tipo'] as String?) ?? 'Negocios';
    final MeetingType mType = MeetingType.values.firstWhere(
      (MeetingType t) => t.label.toLowerCase() == typeLabel.toLowerCase(),
      orElse: () => MeetingType.negocios,
    );
    return WordverseMeeting(
      id: '${row['id'] ?? 'mtg_1'}',
      code: (row['codigo'] as String?) ?? 'WV-45821',
      name: (row['nombre'] as String?) ?? 'Reunión WordVerse',
      type: mType,
      description: (row['descripcion'] as String?) ?? '',
      isPrivate: (row['es_privada'] as bool?) ?? false,
      creatorId: (row['creador'] as String?) ?? 'usr_1',
      creatorName: (row['creador_nombre'] as String?) ?? 'Usuario Shest',
      durationMinutes: (row['duracion_min'] as num?)?.toInt() ?? 45,
    );
  }

  @override
  Future<ShestAuthSession> loginWithShestSession({
    required String userId,
  }) async {
    _checkOnline();
    if (hasLiveCredentials) {
      final String traceId = WordverseEnvConfig.generateTraceId('WV-AUTH');
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/users?id=eq.$userId&select=*')
            : Uri.parse('$_normalizedRestUrl/users/me?userId=$userId');
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(WordverseEnvConfig.defaultHttpTimeout),
          operation: 'loginWithShestSession',
          traceId: traceId,
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final dynamic body = jsonDecode(res.body);
          final Map<String, Object?>? row = (body is List && body.isNotEmpty)
              ? (body.first as Map<String, Object?>)
              : (body is Map<String, Object?> ? body : null);
          if (row != null) {
            final ShestUser user = _parseUserRow(row);
            final String refreshToken = 'refresh_${user.id}';
            lastRefreshToken = refreshToken;
            return ShestAuthSession(
              accessToken: apiKeyOrToken,
              refreshToken: refreshToken,
              user: user,
              expiresAt: DateTime.now().add(const Duration(hours: 8)),
            );
          }
        } else {
          _handleRemoteHttpFailure(
            operation: 'loginWithShestSession',
            statusCode: res.statusCode,
            body: res.body,
            traceId: traceId,
          );
        }
      } on ShestApiException {
        rethrow;
      } catch (_) {
        // Fallback seguro al mock local si el servidor remoto no responde
      }
    }
    final ShestAuthSession session = await fallbackMock.loginWithShestSession(userId: userId);
    lastRefreshToken ??= session.refreshToken;
    return session;
  }

  @override
  Future<ShestAuthSession> refreshSession(String refreshToken) async {
    _checkOnline();
    if (hasLiveCredentials) {
      final String traceId = WordverseEnvConfig.generateTraceId('WV-REFRESH');
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/auth/v1/token?grant_type=refresh_token')
            : Uri.parse('$_normalizedRestUrl/auth/refresh');
        final Map<String, Object?> payload = isSupabase
            ? <String, Object?>{'refresh_token': refreshToken}
            : <String, Object?>{'refreshToken': refreshToken};
        final http.Response res = await _http
            .post(
              uri,
              headers: buildHeaders(traceId: traceId),
              body: jsonEncode(payload),
            )
            .timeout(WordverseEnvConfig.defaultHttpTimeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final Map<String, Object?> data =
              jsonDecode(res.body) as Map<String, Object?>;
          final String newAccess = (data['accessToken'] as String?) ??
              (data['access_token'] as String?) ??
              apiKeyOrToken;
          final String newRefresh = (data['refreshToken'] as String?) ??
              (data['refresh_token'] as String?) ??
              refreshToken;
          apiKeyOrToken = newAccess;
          lastRefreshToken = newRefresh;
          eventBus.emit(
            WordverseEventType.authSessionChanged,
            'Token JWT renovado exitosamente ($maskedCredential)',
            <String, Object?>{'refreshed': true},
          );
          return await loginWithShestSession(userId: 'usr_1');
        } else {
          _handleRemoteHttpFailure(
            operation: 'refreshSession',
            statusCode: res.statusCode,
            body: res.body,
            traceId: traceId,
          );
        }
      } on ShestApiException {
        rethrow;
      } catch (_) {}
    }
    final ShestAuthSession session = await fallbackMock.refreshSession(refreshToken);
    lastRefreshToken = session.refreshToken;
    return session;
  }

  @override
  Future<List<ShestUser>> searchUsers({String query = ''}) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/users?select=*')
            : Uri.parse(
                '$_normalizedRestUrl/users/search?q=${Uri.encodeComponent(query)}',
              );
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(const Duration(seconds: 5)),
          operation: 'searchUsers',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
          final List<ShestUser> users = rows
              .whereType<Map<String, Object?>>()
              .map(_parseUserRow)
              .toList();
          if (!isSupabase) return users;
          final String q = query.trim().toLowerCase();
          if (q.isEmpty) return users;
          return users
              .where(
                (ShestUser u) =>
                    u.name.toLowerCase().contains(q) ||
                    u.company.toLowerCase().contains(q),
              )
              .toList();
        }
      } catch (_) {}
    }
    return fallbackMock.searchUsers(query: query);
  }

  @override
  Future<ShestUser> updateUserStatus({
    required String userId,
    required UserPresenceStatus status,
  }) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/users?id=eq.$userId');
        await _http
            .patch(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{'estado': status.code}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    return fallbackMock.updateUserStatus(userId: userId, status: status);
  }

  @override
  Future<ShestUser> toggleFavorite({required String targetUserId}) async {
    _checkOnline();
    final ShestUser updated = await fallbackMock.toggleFavorite(
      targetUserId: targetUserId,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse(
          '$_normalizedRestUrl/users?id=eq.$targetUserId',
        );
        await _http
            .patch(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{
                'es_favorito': updated.isFavorite,
              }),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    return updated;
  }

  @override
  Future<ShestUser> connectWithUser({required String targetUserId}) async {
    _checkOnline();
    final ShestUser updated = await fallbackMock.connectWithUser(
      targetUserId: targetUserId,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse(
          '$_normalizedRestUrl/users?id=eq.$targetUserId',
        );
        await _http
            .patch(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{'conectado': true}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    return updated;
  }

  @override
  Future<WalletInfo> getWalletInfo(String userId) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/wallets?user_id=eq.$userId&select=*')
            : Uri.parse('$_normalizedRestUrl/wallet/$userId/balance');
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(const Duration(seconds: 5)),
          operation: 'getWalletInfo',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final dynamic body = jsonDecode(res.body);
          if (isSupabase && body is List && body.isNotEmpty) {
            final Map<String, Object?> row = body.first as Map<String, Object?>;
            return WalletInfo(
              userId: userId,
              usdtBalance: (row['balance_usdt'] as num?)?.toDouble() ?? 0.0,
              trc20Address: (row['trc20_address'] as String?) ??
                  'TShestWordVerseTRC20Address',
              recentTransactions: const <String>[
                'Balance sincronizado en tiempo real con Supabase/Shest',
              ],
            );
          } else if (!isSupabase && body is Map<String, Object?>) {
            return WalletInfo(
              userId: userId,
              usdtBalance: (body['balance_usdt'] as num?)?.toDouble() ?? 0.0,
              trc20Address: (body['trc20_address'] as String?) ??
                  'TShestWordVerseTRC20Address',
              recentTransactions: (body['recentTransactions'] as List<dynamic>?)
                      ?.map((dynamic e) => e.toString())
                      .toList() ??
                  const <String>['Balance sincronizado con Spring Boot API'],
            );
          }
        }
      } catch (_) {}
    }
    return fallbackMock.getWalletInfo(userId);
  }

  @override
  Future<PaymentRecord> createPayment({
    required String fromUserId,
    required String toUserId,
    required double amountUsdt,
    required String concept,
  }) async {
    _checkOnline();
    if (hasLiveCredentials && !isSupabase) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/payments/create');
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => _http
              .post(
                uri,
                headers: h,
                body: jsonEncode(<String, Object?>{
                  'fromUserId': fromUserId,
                  'toUserId': toUserId,
                  'amountUsdt': amountUsdt,
                  'concept': concept,
                }),
              )
              .timeout(const Duration(seconds: 5)),
          operation: 'createPayment',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final Map<String, Object?> data =
              jsonDecode(res.body) as Map<String, Object?>;
          return PaymentRecord(
            id: (data['id'] as String?) ?? 'PAY-SPRING',
            fromUserId: fromUserId,
            toUserId: toUserId,
            toUserName: (data['toUserName'] as String?) ?? toUserId,
            amountUsdt: amountUsdt,
            concept: concept,
            status: (data['status'] as String?) ?? 'CONFIRMED',
            timestamp: DateTime.now(),
          );
        }
      } catch (_) {}
    }
    return fallbackMock.createPayment(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amountUsdt: amountUsdt,
      concept: concept,
    );
  }

  @override
  Future<List<PaymentRecord>> getPaymentHistory(String userId) =>
      fallbackMock.getPaymentHistory(userId);

  P2POperation _parseP2PRow(Map<String, Object?> row) {
    final String stateStr = (row['estado'] as String?) ?? 'OPEN';
    final String? typeCode =
        (row['tipo'] as String?) ?? (row['type'] as String?);
    return P2POperation(
      id: (row['id'] as String?) ?? 'p2p_901',
      makerId: (row['maker_id'] as String?) ?? 'usr_2',
      makerName: (row['maker_nombre'] as String?) ?? 'Valeria Méndez',
      amountUsdt: (row['monto_usdt'] as num?)?.toDouble() ?? 1000.0,
      rateUsd: (row['tasa_usd'] as num?)?.toDouble() ?? 1.0,
      paymentMethod:
          (row['metodo_pago'] as String?) ?? 'Transferencia Bancaria',
      status: stateStr,
      type: P2POperationType.fromCode(typeCode),
    );
  }

  /// Verifica en vivo la conexión contra Supabase PostgREST o el Backend Java de Shest.
  Future<({bool ok, String message})> verifyRemoteConnection() async {
    final String traceId = WordverseEnvConfig.generateTraceId('WV-PROBE');
    if (!hasLiveCredentials) {
      return (
        ok: false,
        message:
            'Falta ingresar la URL de tu proyecto Supabase y el SUPABASE_ANON_KEY (actualmente usando fallback Mock local).',
      );
    }
    final Stopwatch sw = Stopwatch()..start();
    try {
      final Uri uri = Uri.parse('$_normalizedRestUrl/users?select=id,nombre');
      final http.Response res = await _http
          .get(uri, headers: buildHeaders(traceId: traceId))
          .timeout(WordverseEnvConfig.healthCheckTimeout);
      sw.stop();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
        return (
          ok: true,
          message:
              'Conectado en vivo a $_normalizedRestUrl (${rows.length} usuarios sincronizados • ${sw.elapsedMilliseconds} ms).',
        );
      } else if (res.statusCode == 404 || res.body.contains('42P01')) {
        _handleRemoteHttpFailure(
          operation: 'verifyRemoteConnection',
          statusCode: res.statusCode,
          body: res.body,
          traceId: traceId,
        );
        return (
          ok: false,
          message:
              'Conectado al servidor (HTTP ${res.statusCode}), pero faltan las tablas. Copia y ejecuta supabase_schema.sql en el SQL Editor de Supabase.',
        );
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        _handleRemoteHttpFailure(
          operation: 'verifyRemoteConnection',
          statusCode: res.statusCode,
          body: res.body,
          traceId: traceId,
        );
        return (
          ok: false,
          message:
              'Credenciales rechazadas (HTTP ${res.statusCode}). Verifica tu SUPABASE_ANON_KEY o Bearer Token ($maskedCredential).',
        );
      } else {
        _handleRemoteHttpFailure(
          operation: 'verifyRemoteConnection',
          statusCode: res.statusCode,
          body: res.body,
          traceId: traceId,
        );
        return (
          ok: false,
          message: 'Respuesta HTTP ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      sw.stop();
      eventBus.emit(
        WordverseEventType.apiError,
        '[verifyRemoteConnection] Excepción de red en $_normalizedRestUrl',
        <String, Object?>{'error': '$e', 'environment': environmentName},
        WordverseEventSeverity.error,
        traceId,
      );
      return (
        ok: false,
        message: 'No se pudo conectar a $_normalizedRestUrl: $e',
      );
    }
  }

  @override
  Future<List<P2POperation>> listOperations({
    P2POperationType? typeFilter,
    String? paymentMethodFilter,
    String? query,
  }) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse(
                '$_normalizedRestUrl/p2p_operations?select=*&order=created_at.desc',
              )
            : Uri.parse('$_normalizedRestUrl/p2p/orders');
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(const Duration(seconds: 5)),
          operation: 'listOperations',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
          Iterable<P2POperation> list = rows
              .whereType<Map<String, Object?>>()
              .map(_parseP2PRow);
          if (typeFilter != null) {
            list = list.where((P2POperation o) => o.type == typeFilter);
          }
          if (paymentMethodFilter != null &&
              paymentMethodFilter.isNotEmpty &&
              paymentMethodFilter != 'ALL') {
            list = list.where(
              (P2POperation o) => o.paymentMethod.toLowerCase().contains(
                paymentMethodFilter.toLowerCase(),
              ),
            );
          }
          if (query != null && query.trim().isNotEmpty) {
            final String q = query.trim().toLowerCase();
            list = list.where(
              (P2POperation o) =>
                  o.makerName.toLowerCase().contains(q) ||
                  o.id.toLowerCase().contains(q),
            );
          }
          return list.toList();
        }
      } catch (_) {}
    }
    return fallbackMock.listOperations(
      typeFilter: typeFilter,
      paymentMethodFilter: paymentMethodFilter,
      query: query,
    );
  }

  @override
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
    P2POperationType type = P2POperationType.sell,
    double? minAmountUsdt,
    double? maxAmountUsdt,
    String? notes,
  }) async {
    _checkOnline();
    final P2POperation createdLocal = await fallbackMock.createOperation(
      makerId: makerId,
      amountUsdt: amountUsdt,
      rateUsd: rateUsd,
      paymentMethod: paymentMethod,
      type: type,
      minAmountUsdt: minAmountUsdt,
      maxAmountUsdt: maxAmountUsdt,
      notes: notes,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/p2p_operations')
            : Uri.parse('$_normalizedRestUrl/p2p/orders');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => _http
              .post(
                uri,
                headers: h,
                body: jsonEncode(isSupabase
                    ? <String, Object?>{
                        'id': createdLocal.id,
                        'maker_id': createdLocal.makerId,
                        'maker_nombre': createdLocal.makerName,
                        'monto_usdt': createdLocal.amountUsdt,
                        'tasa_usd': createdLocal.rateUsd,
                        'metodo_pago': createdLocal.paymentMethod,
                        'tipo': createdLocal.type.code,
                        'estado': 'OPEN',
                      }
                    : <String, Object?>{
                        'makerId': createdLocal.makerId,
                        'amountUsdt': createdLocal.amountUsdt,
                        'rateUsd': createdLocal.rateUsd,
                        'paymentMethod': createdLocal.paymentMethod,
                        'type': createdLocal.type.code,
                      }),
              )
              .timeout(const Duration(seconds: 5)),
          operation: 'createOperation',
        );
      } catch (_) {}
    }
    return createdLocal;
  }

  @override
  Future<P2POperation> acceptOperation({
    required String operationId,
    required String takerId,
  }) async {
    _checkOnline();
    final P2POperation acceptedLocal = await fallbackMock.acceptOperation(
      operationId: operationId,
      takerId: takerId,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/p2p_operations?id=eq.$operationId')
            : Uri.parse('$_normalizedRestUrl/p2p/orders/$operationId/accept');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => isSupabase
              ? _http
                  .patch(
                    uri,
                    headers: h,
                    body: jsonEncode(<String, Object?>{
                      'estado': 'COMPLETED',
                      'taker_id': takerId,
                    }),
                  )
                  .timeout(const Duration(seconds: 5))
              : _http
                  .post(
                    uri,
                    headers: h,
                    body: jsonEncode(<String, Object?>{'takerId': takerId}),
                  )
                  .timeout(const Duration(seconds: 5)),
          operation: 'acceptOperation',
        );
      } catch (_) {}
    }
    return acceptedLocal;
  }

  @override
  Future<P2POperation> cancelOperation(String operationId) async {
    _checkOnline();
    final P2POperation cancelledLocal = await fallbackMock.cancelOperation(
      operationId,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/p2p_operations?id=eq.$operationId')
            : Uri.parse('$_normalizedRestUrl/p2p/orders/$operationId/cancel');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => isSupabase
              ? _http
                  .patch(
                    uri,
                    headers: h,
                    body: jsonEncode(<String, Object?>{'estado': 'CANCELLED'}),
                  )
                  .timeout(const Duration(seconds: 5))
              : _http
                  .post(uri, headers: h, body: jsonEncode(<String, Object?>{}))
                  .timeout(const Duration(seconds: 5)),
          operation: 'cancelOperation',
        );
      } catch (_) {}
    }
    return cancelledLocal;
  }

  @override
  Future<List<EscrowOperation>> listEscrows(String userId) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/escrows?select=*&order=created_at.desc')
            : Uri.parse('$_normalizedRestUrl/escrows?userId=$userId');
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(const Duration(seconds: 5)),
          operation: 'listEscrows',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
          return rows
              .whereType<Map<String, Object?>>()
              .map(_parseEscrowRow)
              .toList();
        }
      } catch (_) {}
    }
    return fallbackMock.listEscrows(userId);
  }

  @override
  Future<EscrowOperation> createEscrow({
    required String creatorId,
    required String counterpartyId,
    required double amount,
    String currency = 'USDT',
    required String description,
    required String conditions,
  }) async {
    _checkOnline();
    final EscrowOperation createdLocal = await fallbackMock.createEscrow(
      creatorId: creatorId,
      counterpartyId: counterpartyId,
      amount: amount,
      currency: currency,
      description: description,
      conditions: conditions,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/escrows');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => _http
              .post(
                uri,
                headers: h,
                body: jsonEncode(isSupabase
                    ? <String, Object?>{
                        'id': createdLocal.id,
                        'creador_id': createdLocal.creatorId,
                        'creador_nombre': createdLocal.creatorName,
                        'contraparte_id': createdLocal.counterpartyId,
                        'contraparte_nombre': createdLocal.counterpartyName,
                        'monto': createdLocal.amount,
                        'moneda': createdLocal.currency,
                        'descripcion': createdLocal.description,
                        'condiciones': createdLocal.conditions,
                        'estado': createdLocal.status.apiValue,
                      }
                    : <String, Object?>{
                        'creatorId': createdLocal.creatorId,
                        'counterpartyId': createdLocal.counterpartyId,
                        'amount': createdLocal.amount,
                        'currency': createdLocal.currency,
                        'description': createdLocal.description,
                        'conditions': createdLocal.conditions,
                      }),
              )
              .timeout(const Duration(seconds: 5)),
          operation: 'createEscrow',
        );
      } catch (_) {}
    }
    return createdLocal;
  }

  @override
  Future<EscrowOperation> transitionEscrowState({
    required String escrowId,
    required String actorUserId,
    required EscrowStatus targetStatus,
  }) async {
    _checkOnline();
    final EscrowOperation updatedLocal = await fallbackMock
        .transitionEscrowState(
          escrowId: escrowId,
          actorUserId: actorUserId,
          targetStatus: targetStatus,
        );
    if (hasLiveCredentials) {
      try {
        final Uri uri = isSupabase
            ? Uri.parse('$_normalizedRestUrl/escrows?id=eq.$escrowId')
            : Uri.parse('$_normalizedRestUrl/escrows/$escrowId/state');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => _http
              .patch(
                uri,
                headers: h,
                body: jsonEncode(isSupabase
                    ? <String, Object?>{'estado': targetStatus.apiValue}
                    : <String, Object?>{
                        'actorUserId': actorUserId,
                        'targetStatus': targetStatus.apiValue,
                      }),
              )
              .timeout(const Duration(seconds: 5)),
          operation: 'transitionEscrowState',
        );
      } catch (_) {}
    }
    return updatedLocal;
  }

  /// Actualiza o registra la presencia del usuario en la sala multiplayer (WV-601).
  Future<void> updateRoomPresence({
    required String userId,
    required String roomName,
    required double posX,
    required double posZ,
    required double rotation,
    String? emote,
    bool online = true,
  }) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/room_presence');
        await _executeWith401Refresh(
          requestFn: (Map<String, String> h) => _http
              .post(
                uri,
                headers: <String, String>{
                  ...h,
                  'Prefer': 'resolution=merge-duplicates',
                },
                body: jsonEncode(<String, Object?>{
                  'user_id': userId,
                  'sala': roomName,
                  'pos_x': posX,
                  'pos_z': posZ,
                  'rotacion': rotation,
                  'emote': ?emote,
                  'online': online,
                  'updated_at': DateTime.now().toIso8601String(),
                }),
              )
              .timeout(const Duration(seconds: 4)),
          operation: 'updateRoomPresence',
        );
      } catch (_) {}
    }
  }

  /// Consulta la presencia de avatares en una sala específica (WV-601).
  Future<List<Map<String, Object?>>> getRoomPresence({
    required String roomName,
  }) async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse(
          '$_normalizedRestUrl/room_presence?sala=eq.$roomName&online=eq.true&select=*',
        );
        final http.Response res = await _executeWith401Refresh(
          requestFn: (Map<String, String> h) =>
              _http.get(uri, headers: h).timeout(const Duration(seconds: 4)),
          operation: 'getRoomPresence',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
          return rows.whereType<Map<String, Object?>>().toList();
        }
      } catch (_) {}
    }
    return const <Map<String, Object?>>[];
  }

  @override
  Future<WordverseMeeting> createMeeting({
    required String creatorId,
    required String name,
    required MeetingType type,
    required String description,
    required bool isPrivate,
    int durationMinutes = 45,
  }) async {
    _checkOnline();
    final WordverseMeeting createdLocal = await fallbackMock.createMeeting(
      creatorId: creatorId,
      name: name,
      type: type,
      description: description,
      isPrivate: isPrivate,
      durationMinutes: durationMinutes,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/meetings');
        await _http
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{
                'id': createdLocal.id,
                'codigo': createdLocal.code,
                'nombre': createdLocal.name,
                'tipo': createdLocal.type.label,
                'descripcion': createdLocal.description,
                'es_privada': createdLocal.isPrivate,
                'duracion_min': createdLocal.durationMinutes,
                'creador': createdLocal.creatorId,
                'creador_nombre': createdLocal.creatorName,
              }),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    return createdLocal;
  }

  @override
  Future<List<WordverseMeeting>> listMeetings() async {
    _checkOnline();
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse(
          '$_normalizedRestUrl/meetings?select=*&order=created_at.desc',
        );
        final http.Response res = await _http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 5));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<Object?> rows = jsonDecode(res.body) as List<Object?>;
          return rows
              .whereType<Map<String, Object?>>()
              .map(_parseMeetingRow)
              .toList();
        }
      } catch (_) {}
    }
    return fallbackMock.listMeetings();
  }

  @override
  Future<Map<String, Object?>> validateAndResolveQr({
    required String qrOrCode,
    required String scannerUserId,
  }) => fallbackMock.validateAndResolveQr(
    qrOrCode: qrOrCode,
    scannerUserId: scannerUserId,
  );

  @override
  List<WordverseChatMessage> getChatMessages(String channelId) =>
      fallbackMock.getChatMessages(channelId);

  @override
  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  }) async {
    _checkOnline();
    final WordverseChatMessage msg = await fallbackMock.sendChatMessage(
      senderId: senderId,
      senderName: senderName,
      channelId: channelId,
      text: text,
    );
    if (hasLiveCredentials) {
      try {
        final Uri uri = Uri.parse('$_normalizedRestUrl/chat_messages');
        await _http
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{
                'id': msg.id,
                'channel_id': msg.channelId,
                'sender_id': msg.senderId,
                'sender_name': msg.senderName,
                'texto': msg.text,
              }),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    return msg;
  }

  @override
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    _checkOnline();
    if (hasLiveCredentials &&
        WordverseEnvConfig.envAiTranslateEnabled &&
        WordverseEnvConfig.isConfiguredRemoteUrl(
          WordverseEnvConfig.envAiTranslateEndpoint,
        )) {
      try {
        final Uri uri = Uri.parse(WordverseEnvConfig.envAiTranslateEndpoint);
        final http.Response response = await _http
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(<String, Object?>{
                'text': text,
                'targetLanguage': targetLanguage,
                'sourceLanguage': sourceLanguage,
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic data = jsonDecode(response.body);
          if (data is Map && data['translatedText'] != null) {
            return data['translatedText'].toString();
          }
        }
      } catch (_) {
        // Fallback resiliente al mock determinista
      }
    }

    return fallbackMock.translateText(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
  }
}
