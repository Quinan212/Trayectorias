import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../datos/repositorio_examenes.dart';
import '../modelos/evento_examen.dart';
import 'servicio_sincronizacion_examenes.dart';

final proveedorRepositorioExamenes = Provider<RepositorioExamenes>(
  (ref) => const RepositorioExamenes(),
);

final proveedorRevisionExamenes = StateProvider<int>((ref) => 0);

final proveedorSincronizacionExamenes =
    Provider<ServicioSincronizacionExamenes>((ref) {
      final repo = ref.watch(proveedorRepositorioExamenes);
      final service = ServicioSincronizacionExamenes(
        cambios: repo.observarCambios(),
        actualizar: () => ref.read(proveedorRevisionExamenes.notifier).state++,
      );
      ref.onDispose(service.dispose);
      return service;
    });

enum ModoVistaExamenes { resumen, jerarquico }

final proveedorModoVistaExamenes = StateProvider<ModoVistaExamenes>(
  (_) => ModoVistaExamenes.resumen,
);

enum ModoEstiloExamenes { clasico, zeus }

final proveedorModoEstiloExamenes = StateProvider<ModoEstiloExamenes>(
  (_) => ModoEstiloExamenes.clasico,
);

void toggleExamenesStyle(WidgetRef ref) {
  final cur = ref.read(proveedorModoEstiloExamenes);
  ref
      .read(proveedorModoEstiloExamenes.notifier)
      .state = cur == ModoEstiloExamenes.clasico
      ? ModoEstiloExamenes.zeus
      : ModoEstiloExamenes.clasico;
}

final proveedorTodosLosExamenes = FutureProvider<List<EventoExamen>>((
  ref,
) async {
  final repo = ref.watch(proveedorRepositorioExamenes);
  ref.watch(proveedorSincronizacionExamenes);
  ref.watch(proveedorRevisionExamenes);
  return repo.cargarTodos();
});

final proveedorIdCarreraExamenes = StateProvider<String>((ref) => 'historia');
final proveedorInstanciaExamenes = StateProvider<String>((ref) => 'todos');

final proveedorExamenesFiltrados = FutureProvider<List<EventoExamen>>((
  ref,
) async {
  final careerId = ref.watch(proveedorIdCarreraExamenes);
  final instancia = ref.watch(proveedorInstanciaExamenes);

  final list = await ref.watch(proveedorTodosLosExamenes.future);

  var out = list.where((e) => e.careerId == careerId).toList(growable: false);
  out = out.where((e) => !e.legacy).toList(growable: false);
  if (instancia != 'todos') {
    out = out.where((e) => e.instancia == instancia).toList(growable: false);
  }
  return out;
});
