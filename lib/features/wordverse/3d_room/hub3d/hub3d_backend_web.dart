import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'hub3d_backend.dart';

int _viewCounter = 0;

/// Aloja `web/hub3d/index.html` (Three.js) en un iframe y se comunica por postMessage.
Hub3DBackend? createBackend() => _WebHub3DBackend();

class _WebHub3DBackend implements Hub3DBackend {
  _WebHub3DBackend() : _viewType = 'wordverse-hub3d-${_viewCounter++}' {
    final int ts = DateTime.now().millisecondsSinceEpoch;
    _iframe = web.HTMLIFrameElement()
      ..src = 'hub3d/index.html?t=$ts'
      ..allow = 'fullscreen'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = '#050b18';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );
    _listener = ((web.MessageEvent event) {
      final JSAny? data = event.data;
      if (data == null) return;
      try {
        String? raw;
        if (data.isA<JSString>()) {
          raw = (data as JSString).toDart;
        } else {
          final Object? dartObj = data.dartify();
          if (dartObj is Map && dartObj['source'] == 'hub3d') {
            _controller.add(Map<String, Object?>.from(dartObj));
            return;
          }
        }
        if (raw != null) {
          final Object? decoded = jsonDecode(raw);
          if (decoded is Map<String, Object?> && decoded['source'] == 'hub3d') {
            _controller.add(decoded);
          }
        }
      } catch (_) {
        // Mensaje ajeno al protocolo: se ignora.
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  final String _viewType;
  late final web.HTMLIFrameElement _iframe;
  late final JSFunction _listener;
  final StreamController<Map<String, Object?>> _controller =
      StreamController<Map<String, Object?>>.broadcast();

  @override
  Widget get view => HtmlElementView(viewType: _viewType);

  @override
  Stream<Map<String, Object?>> get messages => _controller.stream;

  @override
  void send(Map<String, Object?> message) {
    final web.Window? target = _iframe.contentWindow;
    if (target == null) return;
    final String payload = jsonEncode(<String, Object?>{
      'source': 'wordverse',
      ...message,
    });
    target.postMessage(payload.toJS, '*'.toJS);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _controller.close();
  }
}
