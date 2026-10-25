import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/estado_app.dart';
import '../../../modelos/materia.dart';

import 'panel_estilos.dart';

class PanelRequisitos {
  static Widget? build({
    required BuildContext context,
    required WidgetRef ref,
    required Materia course,
    required List<Materia> all,
    required Map<String, String> status,
  }) {
    final notifier = ref.read(proveedorMapaEstadosCorrelativas.notifier);

    bool isPracticaIVEspecial(CorrelativaDetallada c) {
      final n = course.nombre.toLowerCase();
      final isPDIV =
          n.contains('práctica docente iv') ||
          n.contains('practica docente iv');
      final sName = (c.nombre ?? '').toLowerCase();
      return isPDIV &&
          c.isSpecial == true &&
          c.type.toUpperCase() == 'A' &&
          sName.contains('todas las uc');
    }

    String? nombreMateria(String id) {
      final hit = all.where((m) => m.id == id);
      if (hit.isEmpty) return null;
      return hit.first.nombre;
    }

    final seen = <String>{};
    final uniqueDet = <CorrelativaDetallada>[];

    for (final c in course.correlativasDetalladas) {
      final tipo = c.type.toUpperCase();
      final title =
          (c.isSpecial == true && (c.nombre?.trim().isNotEmpty ?? false))
          ? c.nombre!.trim()
          : (nombreMateria(c.id) ?? c.id).trim();

      final key = '${title.toLowerCase()}|$tipo';
      if (seen.add(key)) uniqueDet.add(c);
    }

    if (uniqueDet.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(uniqueDet.length, (i) {
        final c = uniqueDet[i];

        final title =
            (c.isSpecial == true && (c.nombre?.trim().isNotEmpty ?? false))
            ? c.nombre!
            : (nombreMateria(c.id) ?? c.id);

        final tipo = c.type.toUpperCase();
        final esSpecial = c.isSpecial == true;
        final esPDIV = isPracticaIVEspecial(c);

        final usarDosOpciones = esSpecial && tipo == 'A';

        final subtitle = (tipo == 'A')
            ? ((esSpecial || esPDIV)
                  ? 'Deben estar APROBADAS (A)'
                  : 'Debe estar APROBADA (A)')
            : (tipo == 'R' ? 'Debe estar REGULARIZADA (R)' : '');

        final opciones = usarDosOpciones
            ? const ['no-regularizada', 'aprobada']
            : const ['no-regularizada', 'regularizada', 'aprobada'];

        var value = status[c.id] ?? 'no-regularizada';

        if (usarDosOpciones && value == 'regularizada') {
          value = 'no-regularizada';
          notifier.setStatus(c.id, value);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: i == uniqueDet.length - 1 ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: EstilosPanel.gf(
                  size: 15.5,
                  weight: FontWeight.w500,
                  color: EstilosPanel.titleColor(context),
                  height: 1.15,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: EstilosPanel.gf(
                    size: 12.5,
                    weight: FontWeight.w400,
                    color: EstilosPanel.subtitleColor(context),
                    height: 1.25,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                runSpacing: 6,
                children: List.generate(opciones.length, (j) {
                  final opt = opciones[j];
                  final selected = value == opt;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: j == opciones.length - 1 ? 0 : 10,
                    ),
                    child: ToqueMovimientoApp(
                      child: ChoiceChip(
                        chipAnimationStyle: ChipAnimationStyle(
                          enableAnimation: AnimationStyle(
                            duration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                            reverseDuration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                          ),
                          avatarDrawerAnimation: AnimationStyle(
                            duration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                            reverseDuration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                          ),
                          selectAnimation: AnimationStyle(
                            duration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                            reverseDuration: MovimientoApp.duracion(
                              context,
                              MovimientoApp.respuesta,
                            ),
                          ),
                        ),
                        showCheckmark: false,
                        avatar: SizedBox(
                          width: 18,
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: selected
                                ? EstilosPanel.chipSelectedFg(context)
                                : EstilosPanel.chipFg(context),
                          ),
                        ),
                        checkmarkColor: selected
                            ? EstilosPanel.chipSelectedFg(context)
                            : EstilosPanel.chipFg(context),
                        label: Text(
                          EstilosPanel.labelFor(opt),
                          maxLines: 1,
                          softWrap: false,
                        ),
                        selected: selected,
                        onSelected: (_) => notifier.setStatus(c.id, opt),
                        backgroundColor: EstilosPanel.chipBg(context),
                        selectedColor: EstilosPanel.chipSelectedBg(context),
                        side: EstilosPanel.chipSide(
                          context,
                          selected: selected,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: EstilosPanel.chipTextStyle(
                          context,
                          selected: selected,
                        ),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        visualDensity: VisualDensity.standard,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }
}
