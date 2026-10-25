import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/estado_app.dart';
import '../../laboratorio_atlassian/tema/tema_atlassian.dart';

/// Tema visual único para el área administrativa.
///
/// Se apoya en los mismos tokens usados por la interfaz Atlassian del resto de
/// la aplicación y respeta automáticamente el modo claro u oscuro activo.
ThemeData temaAdministradorAtlassian(BuildContext context) {
  return temaLaboratorioAtlassian(context);
}

/// Envuelve una pantalla administrativa para que también conserve el tema
/// cuando se abre de forma directa, desde accesos alternativos o desde pruebas.
class TemaAdministradorAtlassian extends ConsumerWidget {
  const TemaAdministradorAtlassian({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(proveedorModoTema);
    return Theme(data: temaAdministradorAtlassian(context), child: child);
  }
}

/// Ruta estándar para toda navegación interna del panel administrativo.
///
/// Captura el tema actual antes de crear la ruta. Esto evita que una pantalla
/// secundaria vuelva accidentalmente al tema global cuando fue abierta desde
/// una ruta administrativa que ya tenía el tema Atlassian aplicado.
MaterialPageRoute<T> rutaAdministradorAtlassian<T>(
  BuildContext context,
  Widget child,
) {
  return RutaMovimientoApp<T>(
    builder: (_) => TemaAdministradorAtlassian(child: child),
  );
}

Future<T?> abrirPantallaAdministradorAtlassian<T>(
  BuildContext context,
  Widget child,
) {
  return Navigator.of(
    context,
  ).push<T>(rutaAdministradorAtlassian<T>(context, child));
}
