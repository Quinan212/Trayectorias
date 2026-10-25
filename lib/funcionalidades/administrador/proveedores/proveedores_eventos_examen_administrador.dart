import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../compartido/supabase/supabase.dart';
import '../../examenes/proveedores/proveedores_examenes.dart';
import '../datos/repositorio_eventos_examen_administrador.dart';
import '../modelos/evento_examen_administrador.dart';

final proveedorRepositorioEventosExamenAdministrador =
    Provider<RepositorioEventosExamenAdministrador>((ref) {
      return const RepositorioEventosExamenAdministrador();
    });

final proveedorEventosExamenAdministrador =
    FutureProvider<List<EventoExamenAdministrador>>((ref) async {
      ref.watch(proveedorSincronizacionExamenes);
      ref.watch(proveedorRevisionExamenes);
      final bootstrap = ref.watch(proveedorArranqueSupabase);
      final client = ref.watch(proveedorClienteSupabase);

      if (!bootstrap.isReady || client == null) {
        return const <EventoExamenAdministrador>[];
      }

      try {
        final repo = ref.read(proveedorRepositorioEventosExamenAdministrador);
        return await repo.fetchAll(client: client);
      } on PostgrestException {
        rethrow;
      }
    });
