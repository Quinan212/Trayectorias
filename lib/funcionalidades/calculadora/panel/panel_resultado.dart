import 'package:flutter/material.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/estado_app.dart';
import 'panel_estilos.dart';

class PanelResultado {
  static Widget build(BuildContext context, EvalResult res) {
    final cs = Theme.of(context).colorScheme;
    final dark = EstilosPanel.isDark(context);

    String contextLabel(String label) {
      switch (label) {
        case 'No puede cursar':
        case 'Todavía no podés cursar':
          return 'Con las condiciones formales actuales del plan, esta cursada todavía no aparece habilitada.';
        case 'Cursada condicional':
        case 'Cursada condicionada':
        case 'Cursa con restricciones':
        case 'Podés cursar con restricciones':
          return 'Con las condiciones formales actuales del plan, esta cursada aparece habilitada con algunas restricciones.';
        case 'Puede cursar sin restricciones':
        case 'Podés cursar':
          return 'Con las condiciones formales actuales del plan, esta cursada aparece habilitada.';
        default:
          return label;
      }
    }

    Color colorFor(String label) {
      switch (label) {
        case 'No puede cursar':
        case 'Todavía no podés cursar':
          return dark ? const Color(0xFFFFB4A9) : const Color(0xFF9E3025);
        case 'Cursada condicional':
        case 'Cursada condicionada':
        case 'Cursa con restricciones':
        case 'Podés cursar con restricciones':
          return dark ? const Color(0xFFFFD38A) : const Color(0xFF815000);
        case 'Puede cursar sin restricciones':
        case 'Podés cursar':
          return dark ? const Color(0xFF9BE1D5) : const Color(0xFF005B7F);
        default:
          return dark ? cs.onSurface : const Color(0xFF374151);
      }
    }

    Widget cap(String title, bool on, {bool restricted = false}) {
      final bg = on
          ? (restricted
                ? (dark
                      ? EstilosPanel.darken(const Color(0xFFD9A35F), 0.78)
                      : const Color(0xFFF6E7CC))
                : (dark
                      ? EstilosPanel.darken(const Color(0xFF63A8AE), 0.78)
                      : const Color(0xFFDDECEF)))
          : (dark
                ? EstilosPanel.darken(cs.surface, 0.30)
                : const Color(0xFFF3F4F6));

      final fg = on
          ? (restricted
                ? (dark ? const Color(0xFFFFD38A) : const Color(0xFF815000))
                : (dark ? const Color(0xFF9BE1D5) : const Color(0xFF005B7F)))
          : EstilosPanel.subtitleColor(context);

      return AnimatedContainer(
        duration: MovimientoApp.duracion(context, MovimientoApp.respuesta),
        curve: MovimientoApp.curva,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EstilosPanel.border(context)),
        ),
        child: Text(
          title,
          style: EstilosPanel.gf(
            size: 12,
            weight: FontWeight.w600,
            color: fg,
            height: 1.0,
          ),
        ),
      );
    }

    String stripLeadBullet(String? s) {
      if (s == null) return '';
      var t = s.trimLeft();
      while (t.startsWith('-') || t.startsWith('*')) {
        t = t.substring(1).trimLeft();
      }
      return t;
    }

    final noteColor = dark ? cs.onSurface : const Color(0xFF111827);
    final muted = dark ? cs.onSurfaceVariant : const Color(0xFF4B5563);

    final explanation = res.detailedExplanation?.trim();
    final strategy = res.strategy?.trim();
    final hasExplanation = explanation != null && explanation.isNotEmpty;
    final hasStrategy = strategy != null && strategy.isNotEmpty;

    final noteWidgets = <Widget>[];
    for (final raw in res.notes) {
      final clean = stripLeadBullet(raw);
      if (clean.trim().isEmpty) continue;

      noteWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '-',
                style: EstilosPanel.gf(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: noteColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clean,
                  style: EstilosPanel.gf(
                    size: 13.5,
                    weight: FontWeight.w400,
                    color: noteColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lectura del escenario actual',
          style: EstilosPanel.gf(
            size: 12.5,
            weight: FontWeight.w700,
            color: muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contextLabel(res.overallLabel),
          style: EstilosPanel.gf(
            size: 17,
            weight: FontWeight.w600,
            color: colorFor(res.overallLabel),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Esta lectura ordena condiciones formales del plan. Igual, conviene cruzarla con la propuesta de cátedra, los cronogramas y las condiciones institucionales de este año.',
          style: EstilosPanel.gf(
            size: 13,
            weight: FontWeight.w400,
            color: muted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            cap(
              'Actividades de cursada',
              res.activities,
              restricted: res.activitiesRestricted,
            ),
            cap('Parciales', res.exams, restricted: res.examsRestricted),
            cap('Promoción', res.promotion),
          ],
        ),
        if (noteWidgets.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...noteWidgets,
        ],
        if (hasExplanation) ...[
          const SizedBox(height: 8),
          Text(
            explanation,
            style: EstilosPanel.gf(
              size: 13.5,
              weight: FontWeight.w400,
              color: muted,
              height: 1.35,
            ),
          ),
        ],
        if (hasStrategy) ...[
          const SizedBox(height: 10),
          Text(
            'Sugerencia de recorrido: $strategy',
            style: EstilosPanel.gf(
              size: 13.5,
              weight: FontWeight.w600,
              color: noteColor,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}
