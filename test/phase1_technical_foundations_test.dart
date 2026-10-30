import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wordverse/core/api_client/http_shest_api.dart';
import 'package:wordverse/core/config/wordverse_env_config.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/mocks/mock_shest_api.dart';
import 'package:wordverse/core/models/shest_models.dart';

void main() {
  group('Fase 1 (WV-103): Fundamentos Técnicos, Configuración, Trazabilidad y Manejo de Errores', () {
    test('WordverseEnvConfig enmascara secretos, normaliza URLs y valida endpoints remotos', () {
      expect(WordverseEnvConfig.maskSecret(''), equals('<empty>'));
      expect(WordverseEnvConfig.maskSecret('short'), equals('****'));
      expect(
        WordverseEnvConfig.maskSecret('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.9xK2'),
        equals('eyJh...9xK2'),
      );

      expect(
        WordverseEnvConfig.isConfiguredRemoteUrl('https://your-project.supabase.co/rest/v1'),
        isFalse,
      );
      expect(WordverseEnvConfig.isConfiguredRemoteUrl('mock://shest.local'), isFalse);
      expect(
        WordverseEnvConfig.isConfiguredRemoteUrl('https://api.shestlabs.com/v1'),
        isTrue,
      );
      expect(
        WordverseEnvConfig.normalizeRestUrl('https://abcxyz.supabase.co/'),
        equals('https://abcxyz.supabase.co/rest/v1'),
      );
    });

    test('WordverseEventBus genera traceId y permite filtrar por severidad y tipo', () {
      final WordverseEventBus bus = WordverseEventBus();
      addTearDown(bus.dispose);

      bus.emit(
        WordverseEventType.userJoinedRoom,
        'Ingreso a Sala Principal',
        const <String, Object?>{'room': 'Sala Principal'},
      );
      bus.emit(
        WordverseEventType.apiError,
        'Fallo HTTP 401 simulado',
        const <String, Object?>{'statusCode': 401},
        WordverseEventSeverity.error,
        'WV-TRC-CUSTOM-01',
      );

      expect(bus.history, hasLength(2));
      expect(bus.history.first.traceId, equals('WV-TRC-CUSTOM-01'));
      expect(bus.filterBySeverity(WordverseEventSeverity.error), hasLength(1));
      expect(bus.filterByType(WordverseEventType.userJoinedRoom), hasLength(1));
    });

    test('HttpShestApi propaga cabeceras de trazabilidad, enmascara secretos y soporta modo estricto (RSK-03)', () async {
      final WordverseEventBus bus = WordverseEventBus();
      addTearDown(bus.dispose);
      final MockShestApi mock = MockShestApi(eventBus: bus);

      http.Request? capturedRequest;
      final MockClient mockHttp = MockClient((http.Request req) async {
        capturedRequest = req;
        return http.Response('{"error":"invalid_token"}', 401);
      });

      final HttpShestApi adapter = HttpShestApi(
        baseUrl: 'https://api.shestlabs.com/v1',
        apiKeyOrToken: 'secret_jwt_token_value_1234',
        environmentName: 'production',
        strictRemoteErrors: true,
        eventBus: bus,
        fallbackMock: mock,
        httpClient: mockHttp,
      );

      expect(adapter.hasLiveCredentials, isTrue);
      expect(adapter.maskedCredential, equals('secr...1234'));

      await expectLater(
        () => adapter.loginWithShestSession(userId: 'usr_1'),
        throwsA(
          isA<ShestApiException>()
              .having((ShestApiException e) => e.statusCode, 'statusCode', 401)
              .having((ShestApiException e) => e.isUnauthorized, 'isUnauthorized', isTrue),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.headers['X-WordVerse-Environment'],
        equals('production'),
      );
      expect(
        capturedRequest!.headers['X-WordVerse-Trace-Id'],
        startsWith('WV-AUTH-'),
      );

      // Verificar que el evento de error nunca expone el token en texto plano
      final List<WordverseEvent> errorEvents =
          bus.filterBySeverity(WordverseEventSeverity.error);
      expect(errorEvents, isNotEmpty);
      expect(errorEvents.first.summary, contains('secr...1234'));
      expect(errorEvents.first.summary, isNot(contains('secret_jwt_token_value_1234')));
    });
  });
}
