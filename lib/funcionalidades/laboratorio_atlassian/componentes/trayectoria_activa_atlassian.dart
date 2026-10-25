import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';

/// Los detalles y herramientas leen la misma trayectoria que Inicio y Materias.
class TrayectoriaActivaAtlassian extends InheritedNotifier<Listenable> {
  const TrayectoriaActivaAtlassian({
    super.key,
    required this.trayectoria,
    required this.carreraSeleccionada,
    required Listenable cambios,
    required super.child,
  }) : super(notifier: cambios);

  final ValueListenable<TrayectoriaSageLaboratorio?> trayectoria;
  final ValueListenable<int> carreraSeleccionada;

  static TrayectoriaActivaAtlassian? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrayectoriaActivaAtlassian>();

  CarreraTrayectoriaSageLaboratorio? get carreraActual {
    final carreras = trayectoria.value?.carreras;
    if (carreras == null || carreras.isEmpty) return null;
    return carreras[carreraSeleccionada.value.clamp(0, carreras.length - 1)];
  }

  CarreraTrayectoriaSageLaboratorio? buscarCarrera(
    CarreraTrayectoriaSageLaboratorio anterior,
  ) => trayectoria.value?.carreras.where((carrera) {
    if (anterior.careerKey.isNotEmpty) {
      return carrera.careerKey == anterior.careerKey;
    }
    if (anterior.gridRowId.isNotEmpty) {
      return carrera.gridRowId == anterior.gridRowId;
    }
    return carrera.nombre == anterior.nombre &&
        carrera.institucion == anterior.institucion;
  }).firstOrNull;
}
