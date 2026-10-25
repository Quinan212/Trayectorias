import 'dart:async';

import 'package:flutter/services.dart';

/// Controla únicamente la WebView de SAGE; nunca pausa otros navegadores.
class ActividadWebViewSage {
  ActividadWebViewSage({required this.identificador});

  final int identificador;
  static const _canal = MethodChannel(
    'ar.maillet.correlativas_historia/sage_webview_activity',
  );
  Future<void> _pendiente = Future<void>.value();
  bool? _actividadSolicitada;
  bool _liberada = false;

  Future<void> actualizar(bool activa) {
    if (_liberada || _actividadSolicitada == activa) return _pendiente;
    _actividadSolicitada = activa;
    return _encolar(
      'setActive',
      {'active': activa},
      alFallar: () {
        if (_actividadSolicitada == activa) _actividadSolicitada = null;
      },
    );
  }

  Future<void> liberar() {
    if (_liberada) return _pendiente;
    _liberada = true;
    return _encolar('release', const {});
  }

  Future<void> _encolar(
    String metodo,
    Map<String, Object> argumentos, {
    void Function()? alFallar,
  }) {
    return _pendiente = _pendiente.then((_) async {
      try {
        final aplicada = await _canal
            .invokeMethod<bool>(metodo, {
              'identifier': identificador,
              ...argumentos,
            })
            .timeout(const Duration(seconds: 1));
        if (aplicada != true) alFallar?.call();
      } on MissingPluginException {
        alFallar?.call();
      } on PlatformException {
        alFallar?.call();
      } on TimeoutException {
        alFallar?.call();
      }
    });
  }
}
