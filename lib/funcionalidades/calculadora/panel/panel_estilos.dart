import 'package:flutter/material.dart';

import '../pantalla/tema/estilos_calculadora.dart';

class EstilosPanel {
  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color darken(Color c, [double t = 0.2]) =>
      Color.lerp(c, Colors.black, t)!;

  static TextStyle gf({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static Color border(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.outlineVariant : EstilosCalculadora.kBordeClaro;
  }

  static Color titleColor(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.onSurface : const Color(0xFF111827);
  }

  static Color subtitleColor(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.onSurfaceVariant : const Color(0xFF44546F);
  }

  static Color chipBg(BuildContext c) {
    return isDark(c) ? const Color(0xFF111317) : const Color(0xFFF1F4F8);
  }

  static Color chipSelectedBg(BuildContext c) {
    return isDark(c) ? const Color(0xFF223761) : const Color(0xFFDBEAFE);
  }

  static Color chipFg(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.onSurface : const Color(0xFF374151);
  }

  static Color chipSelectedFg(BuildContext c) {
    return isDark(c) ? const Color(0xFFDDEAFF) : const Color(0xFF173D8F);
  }

  static BorderSide chipSide(BuildContext c, {required bool selected}) {
    if (selected) {
      return BorderSide(color: Theme.of(c).colorScheme.primary, width: 1.5);
    }
    return BorderSide(color: border(c));
  }

  static TextStyle chipTextStyle(BuildContext c, {required bool selected}) {
    return gf(
      size: 13,
      weight: FontWeight.w600,
      color: selected ? chipSelectedFg(c) : chipFg(c),
      height: 1.0,
    );
  }

  static String labelFor(String opt) {
    if (opt == 'no-regularizada') return 'no\u00A0regularizada';
    return opt;
  }

  static Widget sectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    final dot = isDark(context) ? cs.primary : const Color(0xFF005B7F);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: gf(
              size: 14.5,
              weight: FontWeight.w600,
              color: titleColor(context),
            ),
          ),
        ),
      ],
    );
  }

  static Widget panelCard(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border(context)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
