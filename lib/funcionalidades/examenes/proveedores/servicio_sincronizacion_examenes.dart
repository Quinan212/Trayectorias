import 'dart:async';

import 'package:flutter/widgets.dart';

/// Reúne cambios remotos y regresos a la app para todas las vistas de mesas.
class ServicioSincronizacionExamenes with WidgetsBindingObserver {
  ServicioSincronizacionExamenes({
    required Stream<void> cambios,
    required this.actualizar,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _subscription = cambios.listen((_) => _programarActualizacion());
  }

  final VoidCallback actualizar;
  late final StreamSubscription<void> _subscription;
  Timer? _debounce;
  bool _disposed = false;

  void _programarActualizacion() {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!_disposed) actualizar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _programarActualizacion();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    unawaited(_subscription.cancel());
  }
}
