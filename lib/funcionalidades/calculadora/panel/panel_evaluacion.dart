import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/proveedores/estado_app.dart';

import '../pantalla/componentes/contenido_animado_calculadora.dart';
import 'panel_estilos.dart';
import 'panel_pd_especiales.dart';
import 'panel_requisitos.dart';
import 'panel_resultado.dart';

class PanelEvaluacion extends ConsumerWidget {
  const PanelEvaluacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(proveedorPlan)
        .maybeWhen(data: (p) => p, orElse: () => null);
    final selId = ref.watch(proveedorIdMateriaCalculadoraSeleccionada);
    final statusMap = ref.watch(proveedorMapaEstadosCorrelativas);

    if (plan == null || selId == null) return const SizedBox.shrink();

    final careerId = ref.watch(proveedorCarreraSeleccionada).id;

    final base = plan.materias.firstWhere((m) => m.id == selId);
    final course = PdEspeciales.prepararCurso(
      course0: base,
      careerId: careerId,
      all: plan.materias,
    );

    final reqBlock = PanelRequisitos.build(
      context: context,
      ref: ref,
      course: course,
      all: plan.materias,
      status: statusMap,
    );

    final res = evaluateCourse(course, statusMap, plan.materias);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        Widget requirementsCard() {
          return EstilosPanel.panelCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EstilosPanel.sectionHeader(context, 'Materias'),
                const SizedBox(height: 10),
                reqBlock ?? const SizedBox.shrink(),
              ],
            ),
          );
        }

        Widget resultCard() {
          return EstilosPanel.panelCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EstilosPanel.sectionHeader(context, 'Escenario actual'),
                const SizedBox(height: 10),
                ContenidoAnimadoCalculadora(
                  identidad: (
                    selId,
                    res.overallLabel,
                    res.activities,
                    res.activitiesRestricted,
                    res.exams,
                    res.examsRestricted,
                    res.promotion,
                    res.notes.join('|'),
                    res.detailedExplanation,
                    res.strategy,
                  ),
                  child: PanelResultado.build(context, res),
                ),
              ],
            ),
          );
        }

        if (!isDesktop || reqBlock == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reqBlock != null) ...[
                requirementsCard(),
                const SizedBox(height: 12),
              ],
              resultCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: requirementsCard()),
            const SizedBox(width: 16),
            Expanded(child: resultCard()),
          ],
        );
      },
    );
  }
}
