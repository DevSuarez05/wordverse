import 'package:flutter/widgets.dart';

import 'hub3d_backend_stub.dart'
    if (dart.library.js_interop) 'hub3d_backend_web.dart'
    as impl;

/// Canal con la escena 3D. En plataformas sin soporte (VM de tests, móvil)
/// [createHub3DBackend] devuelve `null` y la UI usa el visor 2.5D de respaldo.
abstract class Hub3DBackend {
  /// Widget que aloja la escena (iframe en web).
  Widget get view;

  /// Mensajes JSON recibidos de la escena.
  Stream<Map<String, Object?>> get messages;

  void send(Map<String, Object?> message);

  void dispose();
}

Hub3DBackend? createHub3DBackend() => impl.createBackend();
