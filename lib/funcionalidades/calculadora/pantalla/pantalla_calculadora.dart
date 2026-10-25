import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/estado_app.dart';
import '../../../modelos/materia.dart';
import '../evaluation_panel.dart';
import 'componentes/banner_colapsable_calculadora.dart';
import 'componentes/bloque_selectores_calculadora.dart';
import 'componentes/contenido_animado_calculadora.dart';
import 'componentes/resumen_materia_calculadora.dart';
import 'componentes/tarjeta_espera_calculadora.dart';
import 'componentes/tarjeta_paso_calculadora.dart';
import 'tema/estilos_calculadora.dart';
import 'utilidades/iterables.dart';

class PantallaCalculadora extends ConsumerWidget {
  const PantallaCalculadora({super.key});

  static const kPageBgLight = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TemaCalculadora(builder: (context) => _contenido(context, ref));

  Widget _contenido(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(proveedorPlan);
    final hasSelectedCareer = ref.watch(proveedorTieneCarreraSeleccionada);
    final year = ref.watch(proveedorAnioEvaluacion);
    final selectedId = ref.watch(proveedorIdMateriaCalculadoraSeleccionada);
    final topInset = MediaQuery.of(context).viewPadding.top;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: BannerColapsableCalculadora(
                topInset: topInset,
                subtitle: 'Condiciones y posibilidades',
              ),
            ),
            SliverToBoxAdapter(
              child: planAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(child: Text('Error cargando plan: $e')),
                ),
                data: (plan) {
                  final materiasYear =
                      plan.materias.where((m) => m.anio == year).toList()
                        ..sort((a, b) => a.nombre.compareTo(b.nombre));

                  final Materia? course = selectedId == null
                      ? null
                      : firstWhereOrNull(
                          plan.materias,
                          (m) => m.id == selectedId,
                        );

                  if (selectedId != null && course == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                              .read(
                                proveedorIdMateriaCalculadoraSeleccionada
                                    .notifier,
                              )
                              .state =
                          null;
                      ref
                          .read(proveedorMapaEstadosCorrelativas.notifier)
                          .clear();
                    });
                  }

                  if (!isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntradaContenidoApp(
                            child: TarjetaPasoCalculadora(
                              numero: 1,
                              titulo: 'Elegí la carrera de referencia',
                              subtitulo:
                                  'La lectura cambia según el plan y la institución que tomás como referencia.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const EntradaContenidoApp(
                            child: TarjetaPasoCalculadora(
                              numero: 2,
                              titulo: 'Ubica el tramo del plan',
                              subtitulo:
                                  'Elegí el año donde se ubica la materia para leer sus condiciones de cursada.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const EntradaContenidoApp(
                            child: TarjetaPasoCalculadora(
                              numero: 3,
                              titulo: 'Pon la materia en contexto',
                              subtitulo:
                                  'Seleccioná la materia que querés revisar para ver qué escenario se abre hoy.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          BloqueSelectoresCalculadora(
                            materiasYear: materiasYear,
                          ),
                          const SizedBox(height: 16),
                          ContenidoAnimadoCalculadora(
                            identidad: course?.id ?? 'espera',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (course == null)
                                  TarjetaEsperaCalculadora(
                                    texto: hasSelectedCareer
                                        ? 'Seleccioná un año y una materia para leer las condiciones de cursada de ese tramo.'
                                        : 'Seleccioná una carrera para continuar.',
                                  )
                                else ...[
                                  ResumenMateriaCalculadora(materia: course),
                                  const SizedBox(height: 12),
                                  const PanelEvaluacion(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1520),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 360,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  EntradaContenidoApp(
                                    child: TarjetaPasoCalculadora(
                                      numero: 1,
                                      titulo: 'Elegí la carrera de referencia',
                                      subtitulo:
                                          'La lectura cambia según el plan y la institución que tomás como referencia.',
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  EntradaContenidoApp(
                                    child: TarjetaPasoCalculadora(
                                      numero: 2,
                                      titulo: 'Ubica el tramo del plan',
                                      subtitulo:
                                          'Elegí el año donde se ubica la materia para leer sus condiciones de cursada.',
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  EntradaContenidoApp(
                                    child: TarjetaPasoCalculadora(
                                      numero: 3,
                                      titulo: 'Pon la materia en contexto',
                                      subtitulo:
                                          'Seleccioná la materia que querés revisar para ver qué escenario se abre hoy.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BloqueSelectoresCalculadora(
                                    materiasYear: materiasYear,
                                  ),
                                  const SizedBox(height: 16),
                                  ContenidoAnimadoCalculadora(
                                    identidad: course?.id ?? 'espera',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (course == null)
                                          TarjetaEsperaCalculadora(
                                            texto: hasSelectedCareer
                                                ? 'Seleccioná un año y una materia para leer las condiciones de cursada de ese tramo.'
                                                : 'Seleccioná una carrera para continuar.',
                                          )
                                        else ...[
                                          ResumenMateriaCalculadora(
                                            materia: course,
                                          ),
                                          const SizedBox(height: 12),
                                          const PanelEvaluacion(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
