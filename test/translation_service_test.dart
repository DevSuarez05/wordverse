import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/core/services/wordverse_translation_service.dart';
import 'package:wordverse/features/wordverse/meetings/networking_chat_sheet.dart';

void main() {
  group('Fase 3 — WV-301: WordverseTranslationService Unit Tests', () {
    late WordverseEventBus eventBus;
    late WordverseTranslationService service;

    setUp(() {
      eventBus = WordverseEventBus();
      service = WordverseTranslationService(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('Detección automática de idiomas (ES, EN, PT, ZH)', () {
      expect(service.detectLanguage('你好，欢迎参加会议'), 'zh');
      expect(service.detectLanguage('Olá a todos, obrigado pela reunião e pelo acordo'), 'pt');
      expect(service.detectLanguage('Hello everyone, let\'s review the Escrow agreement'), 'en');
      expect(service.detectLanguage('Hola a todos, bienvenidos a la sala privada'), 'es');
    });

    test('Traducción determinista de frases B2B / Escrow / Chat', () async {
      final TranslationResult resEn = await service.translate(
        text: 'Hola a todos, bienvenidos a la sala',
        targetLanguage: 'en',
      );
      expect(resEn.isSuccess, isTrue);
      expect(resEn.sourceLanguage, 'es');
      expect(resEn.targetLanguage, 'en');
      expect(resEn.translatedText, 'Hello everyone, welcome to the room');

      final TranslationResult resZh = await service.translate(
        text: 'Acuerdo confirmado y fondos en custodia',
        targetLanguage: 'zh',
      );
      expect(resZh.isSuccess, isTrue);
      expect(resZh.translatedText, '协议已确认，资金已托管');

      final TranslationResult resPt = await service.translate(
        text: 'Liberar pago del contrato Escrow',
        targetLanguage: 'pt',
      );
      expect(resPt.isSuccess, isTrue);
      expect(resPt.translatedText, 'Liberar pagamento do contrato Escrow');
    });

    test('Caché LRU en memoria retorna fromCache=true', () async {
      service.clearCache();
      expect(service.cacheSize, 0);

      const String text = 'Oferta de compra USDT disponible';
      final TranslationResult first = await service.translate(
        text: text,
        targetLanguage: 'en',
      );
      expect(first.fromCache, isFalse);
      expect(service.cacheSize, 1);

      final TranslationResult second = await service.translate(
        text: text,
        targetLanguage: 'en',
      );
      expect(second.fromCache, isTrue);
      expect(second.translatedText, first.translatedText);
      expect(service.cacheSize, 1);
    });

    test('Manejo de textos vacíos, mismo idioma y textos largos', () async {
      final TranslationResult emptyRes = await service.translate(
        text: '   ',
        targetLanguage: 'en',
      );
      expect(emptyRes.isSuccess, isTrue);
      expect(emptyRes.translatedText.trim(), isEmpty);

      final TranslationResult sameRes = await service.translate(
        text: 'Hello world',
        targetLanguage: 'en',
        sourceLanguage: 'en',
      );
      expect(sameRes.translatedText, 'Hello world');

      final String longInput = 'acuerdo ' * 400; // > 2000 chars
      final TranslationResult longRes = await service.translate(
        text: longInput,
        targetLanguage: 'en',
      );
      expect(longRes.isSuccess, isTrue);
      expect(longRes.translatedText, contains('agreement'));
    });

    test('Emisión de evento WordverseEventType.translationExecuted', () async {
      await service.translate(
        text: 'Minuta aprobada por la junta directiva',
        targetLanguage: 'en',
      );

      final List<WordverseEvent> events = eventBus.filterByType(
        WordverseEventType.translationExecuted,
      );
      expect(events.isNotEmpty, isTrue);
      expect(events.first.payload['targetLang'], 'en');
      expect(events.first.payload['sourceLang'], 'es');
    });

    test('Límite de tasa (Rate Limiting) previene saturación', () async {
      final WordverseTranslationService limitedService =
          WordverseTranslationService(maxRequestsPerMinute: 3);

      final TranslationResult r1 = await limitedService.translate(
        text: 'hola uno',
        targetLanguage: 'en',
        sourceLanguage: 'es',
        useCache: false,
      );
      final TranslationResult r2 = await limitedService.translate(
        text: 'hola dos',
        targetLanguage: 'en',
        sourceLanguage: 'es',
        useCache: false,
      );
      final TranslationResult r3 = await limitedService.translate(
        text: 'hola tres',
        targetLanguage: 'en',
        sourceLanguage: 'es',
        useCache: false,
      );
      final TranslationResult r4 = await limitedService.translate(
        text: 'hola cuatro',
        targetLanguage: 'en',
        sourceLanguage: 'es',
        useCache: false,
      );

      expect(r1.isSuccess, isTrue);
      expect(r2.isSuccess, isTrue);
      expect(r3.isSuccess, isTrue);
      expect(r4.isSuccess, isFalse);
      expect(r4.errorMessage, contains('Límite de traducciones'));
    });
  });

  group('Fase 3 — WV-301.1 & WV-303: NetworkingAndChatSheet Widget Integration', () {
    late WordverseEventBus eventBus;
    late ShestApiClient client;
    late ShestUser currentUser;

    setUp(() {
      eventBus = WordverseEventBus();
      client = ShestApiClient(eventBus: eventBus);
      currentUser = const ShestUser(
        id: 'usr_me',
        name: 'Daniel Directivo',
        company: 'WordVerse Corp',
        role: 'CEO',
        description: 'Fundador y Director Ejecutivo',
        avatarInitials: 'DD',
        avatarHexColor: 0xFFD4AF37,
        status: UserPresenceStatus.available,
      );
    });

    tearDown(() {
      eventBus.dispose();
    });

    testWidgets('NetworkingAndChatSheet expone selector de idioma y renderiza traducciones', (
      WidgetTester tester,
    ) async {
      await client.sendChatMessage(
        senderId: 'usr_partner',
        senderName: 'Carlos Mendoza',
        channelId: 'room_vip_boardroom',
        text: 'Hello everyone, welcome to the room',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkingAndChatSheet(
              apiClient: client,
              currentUser: currentUser,
              onUserUpdated: (_) {},
              channelId: 'room_vip_boardroom',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar controles de IA
      expect(find.byKey(const Key('dropdown_chat_language')), findsOneWidget);
      expect(find.byKey(const Key('btn_toggle_auto_translate')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is RichText &&
              w.text.toPlainText().contains('Hello everyone'),
        ),
        findsOneWidget,
      );

      // Esperar a que la promesa de traducción asíncrona resuelva
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Debe mostrar la traducción renderizada al español
      expect(find.textContaining('IA: EN ➔ ES'), findsOneWidget);
      expect(find.text('Hola a todos, bienvenidos a la sala'), findsOneWidget);

      // Toggle auto-translate
      await tester.tap(find.byKey(const Key('btn_toggle_auto_translate')));
      await tester.pumpAndSettle();
      expect(find.text('IA: EN ➔ ES'), findsNothing);
    });
  });
}
