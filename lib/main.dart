import 'package:flutter/material.dart';

import 'core/api_client/shest_api_client.dart';
import 'core/events/wordverse_events.dart';
import 'features/wordverse/3d_room/wordverse_module_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final WordverseEventBus eventBus = WordverseEventBus();
  final ShestApiClient apiClient = ShestApiClient(eventBus: eventBus);
  runApp(WordverseApp(apiClient: apiClient));
}

/// Aplicación anfitriona / módulo autónomo de WordVerse para integración con Shest Labs.
class WordverseApp extends StatelessWidget {
  const WordverseApp({
    super.key,
    required this.apiClient,
    this.startDirectlyInRoom = false,
  });

  final ShestApiClient apiClient;
  final bool startDirectlyInRoom;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shest Labs — WordVerse 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: WordverseModuleScreen(
        apiClient: apiClient,
        startDirectlyInRoom: startDirectlyInRoom,
      ),
    );
  }
}
