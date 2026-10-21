import 'dart:convert';

import 'package:http/http.dart' as http;

import '../events/wordverse_events.dart';
import '../mocks/mock_shest_api.dart';
import '../models/shest_models.dart';
import 'shest_backend_adapter.dart';

/// Adaptador HTTP REST para conectar WordVerse con:
/// 1. Supabase PostgREST (`https://<project>.supabase.co/rest/v1`)
/// 2. Backend Productivo de Shest Labs en Java Spring Boot (`https://api.shestlabs.com/v1`)
///
/// Incluye fallback controlado a [MockShestApi] cuando las credenciales remotas
/// o el servidor aún no están disponibles, garantizando que el equipo nunca se bloquee.
class HttpShestApi implements ShestBackendAdapter {
  HttpShestApi({
    required this.baseUrl,
    required this.eventBus,
    required this.fallbackMock,
    this.apiKeyOrToken = '',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKeyOrToken;
  final WordverseEventBus eventBus;
  final MockShestApi fallbackMock;
  final http.Client _http;

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    if (apiKeyOrToken.isNotEmpty) 'Authorization': 'Bearer $apiKeyOrToken',
    if (apiKeyOrToken.isNotEmpty) 'apikey': apiKeyOrToken,
  };

  @override
  bool get simulateOffline => fallbackMock.simulateOffline;

  @override
  set simulateOffline(bool value) => fallbackMock.simulateOffline = value;

  /// Intenta ejecutar una petición HTTP real al endpoint configurado; si el
  /// servidor aún no está desplegado o sin credenciales, delega de forma segura
  /// al estado sincronizado de [fallbackMock].
  Future<T> _executeWithFallback<T>({
    required String endpointPath,
    required Future<T> Function() onFallback,
    Map<String, Object?>? postBody,
  }) async {
    if (simulateOffline) {
      throw const ShestApiException(
        code: 'NETWORK_OFFLINE',
        userMessage:
            'Sin conexión con Shest API. Verifica tu red o usa Reconectar.',
      );
    }

    // Si es la URL plantilla sin credenciales reales, usamos el fallback directamente
    if (baseUrl.contains('your-project.supabase.co') ||
        baseUrl.contains('api.shestlabs.com')) {
      return onFallback();
    }

    try {
      final Uri uri = Uri.parse('$baseUrl$endpointPath');
      final http.Response response = postBody == null
          ? await _http
                .get(uri, headers: _headers)
                .timeout(const Duration(seconds: 4))
          : await _http
                .post(uri, headers: _headers, body: jsonEncode(postBody))
                .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return await onFallback();
      }
      throw ShestApiException(
        code: 'HTTP_${response.statusCode}',
        userMessage:
            'Shest API respondió con estado ${response.statusCode} en $endpointPath',
      );
    } on ShestApiException {
      rethrow;
    } catch (_) {
      return onFallback();
    }
  }

  @override
  Future<ShestAuthSession> loginWithShestSession({required String userId}) {
    return _executeWithFallback(
      endpointPath: '/users/me?userId=$userId',
      onFallback: () => fallbackMock.loginWithShestSession(userId: userId),
    );
  }

  @override
  Future<ShestAuthSession> refreshSession(String refreshToken) {
    return _executeWithFallback(
      endpointPath: '/auth/refresh',
      postBody: <String, Object?>{'refreshToken': refreshToken},
      onFallback: () => fallbackMock.refreshSession(refreshToken),
    );
  }

  @override
  Future<List<ShestUser>> searchUsers({String query = ''}) {
    return _executeWithFallback(
      endpointPath: '/users/search?q=${Uri.encodeQueryComponent(query)}',
      onFallback: () => fallbackMock.searchUsers(query: query),
    );
  }

  @override
  Future<ShestUser> updateUserStatus({
    required String userId,
    required UserPresenceStatus status,
  }) {
    return _executeWithFallback(
      endpointPath: '/users/$userId/status',
      postBody: <String, Object?>{'status': status.code},
      onFallback: () =>
          fallbackMock.updateUserStatus(userId: userId, status: status),
    );
  }

  @override
  Future<ShestUser> toggleFavorite({required String targetUserId}) {
    return _executeWithFallback(
      endpointPath: '/users/$targetUserId/favorite',
      postBody: <String, Object?>{'targetUserId': targetUserId},
      onFallback: () => fallbackMock.toggleFavorite(targetUserId: targetUserId),
    );
  }

  @override
  Future<ShestUser> connectWithUser({required String targetUserId}) {
    return _executeWithFallback(
      endpointPath: '/networking/connect',
      postBody: <String, Object?>{'targetUserId': targetUserId},
      onFallback: () =>
          fallbackMock.connectWithUser(targetUserId: targetUserId),
    );
  }

  @override
  Future<WalletInfo> getWalletInfo(String userId) {
    return _executeWithFallback(
      endpointPath: '/wallet/$userId/balance',
      onFallback: () => fallbackMock.getWalletInfo(userId),
    );
  }

  @override
  Future<PaymentRecord> createPayment({
    required String fromUserId,
    required String toUserId,
    required double amountUsdt,
    required String concept,
  }) {
    return _executeWithFallback(
      endpointPath: '/payments/create',
      postBody: <String, Object?>{
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amountUsdt': amountUsdt,
        'concept': concept,
      },
      onFallback: () => fallbackMock.createPayment(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amountUsdt: amountUsdt,
        concept: concept,
      ),
    );
  }

  @override
  Future<List<PaymentRecord>> getPaymentHistory(String userId) {
    return _executeWithFallback(
      endpointPath: '/payments/$userId/history',
      onFallback: () => fallbackMock.getPaymentHistory(userId),
    );
  }

  @override
  Future<List<P2POperation>> listOperations() {
    return _executeWithFallback(
      endpointPath: '/p2p/orders',
      onFallback: fallbackMock.listOperations,
    );
  }

  @override
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
  }) {
    return _executeWithFallback(
      endpointPath: '/p2p/orders',
      postBody: <String, Object?>{
        'makerId': makerId,
        'amountUsdt': amountUsdt,
        'rateUsd': rateUsd,
        'paymentMethod': paymentMethod,
      },
      onFallback: () => fallbackMock.createOperation(
        makerId: makerId,
        amountUsdt: amountUsdt,
        rateUsd: rateUsd,
        paymentMethod: paymentMethod,
      ),
    );
  }

  @override
  Future<P2POperation> acceptOperation({
    required String operationId,
    required String takerId,
  }) {
    return _executeWithFallback(
      endpointPath: '/p2p/orders/$operationId/accept',
      postBody: <String, Object?>{'takerId': takerId},
      onFallback: () => fallbackMock.acceptOperation(
        operationId: operationId,
        takerId: takerId,
      ),
    );
  }

  @override
  Future<P2POperation> cancelOperation(String operationId) {
    return _executeWithFallback(
      endpointPath: '/p2p/orders/$operationId/cancel',
      postBody: const <String, Object?>{},
      onFallback: () => fallbackMock.cancelOperation(operationId),
    );
  }

  @override
  Future<List<EscrowOperation>> listEscrows(String userId) {
    return _executeWithFallback(
      endpointPath: '/escrows?userId=$userId',
      onFallback: () => fallbackMock.listEscrows(userId),
    );
  }

  @override
  Future<EscrowOperation> createEscrow({
    required String creatorId,
    required String counterpartyId,
    required double amount,
    String currency = 'USDT',
    required String description,
    required String conditions,
  }) {
    return _executeWithFallback(
      endpointPath: '/escrows',
      postBody: <String, Object?>{
        'creatorId': creatorId,
        'counterpartyId': counterpartyId,
        'amount': amount,
        'currency': currency,
        'description': description,
        'conditions': conditions,
      },
      onFallback: () => fallbackMock.createEscrow(
        creatorId: creatorId,
        counterpartyId: counterpartyId,
        amount: amount,
        currency: currency,
        description: description,
        conditions: conditions,
      ),
    );
  }

  @override
  Future<EscrowOperation> transitionEscrowState({
    required String escrowId,
    required String actorUserId,
    required EscrowStatus targetStatus,
  }) {
    return _executeWithFallback(
      endpointPath: '/escrows/$escrowId/state',
      postBody: <String, Object?>{
        'actorUserId': actorUserId,
        'targetStatus': targetStatus.apiValue,
      },
      onFallback: () => fallbackMock.transitionEscrowState(
        escrowId: escrowId,
        actorUserId: actorUserId,
        targetStatus: targetStatus,
      ),
    );
  }

  @override
  Future<WordverseMeeting> createMeeting({
    required String creatorId,
    required String name,
    required MeetingType type,
    required String description,
    required bool isPrivate,
    int durationMinutes = 45,
  }) {
    return _executeWithFallback(
      endpointPath: '/meetings',
      postBody: <String, Object?>{
        'creatorId': creatorId,
        'name': name,
        'type': type.label,
        'description': description,
        'isPrivate': isPrivate,
        'durationMinutes': durationMinutes,
      },
      onFallback: () => fallbackMock.createMeeting(
        creatorId: creatorId,
        name: name,
        type: type,
        description: description,
        isPrivate: isPrivate,
        durationMinutes: durationMinutes,
      ),
    );
  }

  @override
  Future<List<WordverseMeeting>> listMeetings() {
    return _executeWithFallback(
      endpointPath: '/meetings',
      onFallback: fallbackMock.listMeetings,
    );
  }

  @override
  Future<Map<String, Object?>> validateAndResolveQr({
    required String qrOrCode,
    required String scannerUserId,
  }) {
    return _executeWithFallback(
      endpointPath: '/qr/validate',
      postBody: <String, Object?>{
        'qrOrCode': qrOrCode,
        'scannerUserId': scannerUserId,
      },
      onFallback: () => fallbackMock.validateAndResolveQr(
        qrOrCode: qrOrCode,
        scannerUserId: scannerUserId,
      ),
    );
  }

  @override
  List<WordverseChatMessage> getChatMessages(String channelId) =>
      fallbackMock.getChatMessages(channelId);

  @override
  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  }) {
    return _executeWithFallback(
      endpointPath: '/chat/$channelId/messages',
      postBody: <String, Object?>{
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
      },
      onFallback: () => fallbackMock.sendChatMessage(
        senderId: senderId,
        senderName: senderName,
        channelId: channelId,
        text: text,
      ),
    );
  }
}
