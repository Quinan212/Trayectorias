import 'package:flutter/material.dart';

import '../../../../compartido/movimiento/movimiento_app.dart';

/// Sólo conserva el contenido actual: no superpone el resultado anterior.
class ContenidoAnimadoCalculadora extends StatelessWidget {
  const ContenidoAnimadoCalculadora({
    super.key,
    required this.identidad,
    required this.child,
  });

  final Object identidad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: MovimientoApp.duracion(context, MovimientoApp.entrada),
      reverseDuration: MovimientoApp.duracion(context, MovimientoApp.salida),
      curve: MovimientoApp.curva,
      alignment: Alignment.topCenter,
      child: EntradaContenidoApp(key: ValueKey(identidad), child: child),
    );
  }
}
