import 'package:flutter/material.dart';

import '../../../../compartido/tema/tema_herramientas_app.dart';

class EstilosCalculadora {
  static const kBordeClaro = Color(0xFF8291A6);

  static ThemeData tema(BuildContext context) => temaHerramientasApp(context);

  // ===== Paletas (match leyenda/grilla) =====
  // Formación (light)
  static const fgLBg = Color(0xFFE0E7FF);
  static const fgLBd = Color(0xFFC7D2FE);
  static const fgLFg = Color(0xFF1E40AF);

  static const feLBg = Color(0xFFD1FAE5);
  static const feLBd = Color(0xFFA7F3D0);
  static const feLFg = Color(0xFF065F46);

  static const ppLBg = Color(0xFFEDE9FE);
  static const ppLBd = Color(0xFFDDD6FE);
  static const ppLFg = Color(0xFF6B28D9);

  // Formato (light)
  static const asigLBg = Color(0xFFE0E7FF);
  static const asigLBd = Color(0xFFC7D2FE);
  static const asigLFg = Color(0xFF1D4ED8);

  static const semLBg = Color(0xFFD1FAE5);
  static const semLBd = Color(0xFFA7F3D0);
  static const semLFg = Color(0xFF065F46);

  static const stLBg = Color(0xFFEDE9FE);
  static const stLBd = Color(0xFFDDD6FE);
  static const stLFg = Color(0xFF6D28D9);

  static const tallerLBg = Color(0xFFFDEAD7);
  static const tallerLBd = Color(0xFFFED7AA);
  static const tallerLFg = Color(0xFF9A3412);

  // Dark (igual a PanelDetalleMateria)
  static const fgDBg = Color(0xFF223761);
  static const fgDBd = Color(0xFF3E60A4);
  static const fgDFg = Color(0xFFBFD4FF);

  static const feDBg = Color(0xFF1E4F45);
  static const feDBd = Color(0xFF2D8C78);
  static const feDFg = Color(0xFFBFEFE0);

  static const ppDBg = Color(0xFF3A2769);
  static const ppDBd = Color(0xFF7351D4);
  static const ppDFg = Color(0xFFE7D7FF);

  static const tallerDBg = Color(0xFF5A3027);
  static const tallerDBd = Color(0xFFB75B33);
  static const tallerDFg = Color(0xFFF4CBB5);

  static bool esOscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color fondoTarjeta(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return esOscuro(context) ? cs.surface : Colors.white;
  }

  static Color bordeTarjeta(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return esOscuro(context) ? cs.outlineVariant : kBordeClaro;
  }

  static Color textoPrincipal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return esOscuro(context) ? cs.onSurface : const Color(0xFF172B4D);
  }

  static Color textoSecundario(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return esOscuro(context) ? cs.onSurfaceVariant : const Color(0xFF44546F);
  }

  static Color oscurecer(Color c, [double t = 0.2]) =>
      Color.lerp(c, Colors.black, t)!;

  static BoxDecoration decoracionTarjeta(BuildContext context) {
    return BoxDecoration(
      color: fondoTarjeta(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: bordeTarjeta(context)),
      boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
    );
  }

  static InputDecoration decoracionInput(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = esOscuro(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textoSecundario(context)),
      filled: true,
      fillColor: isDark ? cs.surface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? cs.outlineVariant : kBordeClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? cs.outlineVariant : kBordeClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary),
      ),
    );
  }

  static ({Color bg, Color bd, Color fg}) estiloTipo(
    BuildContext context,
    String tipo,
  ) {
    final isDark = esOscuro(context);
    final cs = Theme.of(context).colorScheme;

    switch (tipo.trim()) {
      case 'Formación General':
        return (
          bg: isDark ? fgDBg : fgLBg,
          bd: isDark ? fgDBd : fgLBd,
          fg: isDark ? fgDFg : fgLFg,
        );
      case 'Formación Específica':
        return (
          bg: isDark ? feDBg : feLBg,
          bd: isDark ? feDBd : feLBd,
          fg: isDark ? feDFg : feLFg,
        );
      case 'Práctica Profesional':
        return (
          bg: isDark ? ppDBg : ppLBg,
          bd: isDark ? ppDBd : ppLBd,
          fg: isDark ? ppDFg : ppLFg,
        );
      default:
        return (
          bg: isDark ? cs.surface : const Color(0xFFF3F4F6),
          bd: isDark ? cs.outlineVariant : const Color(0xFFE5E7EB),
          fg: cs.onSurface,
        );
    }
  }

  static ({Color bg, Color bd, Color fg}) estiloFormato(
    BuildContext context,
    String formato,
  ) {
    final isDark = esOscuro(context);
    final cs = Theme.of(context).colorScheme;

    switch (formato.trim()) {
      case 'Asignatura':
        return (
          bg: isDark ? fgDBg : asigLBg,
          bd: isDark ? fgDBd : asigLBd,
          fg: isDark ? fgDFg : asigLFg,
        );
      case 'Seminario':
        return (
          bg: isDark ? feDBg : semLBg,
          bd: isDark ? feDBd : semLBd,
          fg: isDark ? feDFg : semLFg,
        );
      case 'Seminario-Taller':
        return (
          bg: isDark ? ppDBg : stLBg,
          bd: isDark ? ppDBd : stLBd,
          fg: isDark ? ppDFg : stLFg,
        );
      case 'Taller':
        return (
          bg: isDark ? tallerDBg : tallerLBg,
          bd: isDark ? tallerDBd : tallerLBd,
          fg: isDark ? tallerDFg : tallerLFg,
        );
      default:
        return (
          bg: isDark ? cs.surface : const Color(0xFFF3F4F6),
          bd: isDark ? cs.outlineVariant : const Color(0xFFE5E7EB),
          fg: cs.onSurface,
        );
    }
  }

  static ({Color bg, Color bd, Color fg}) estiloAnio(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = esOscuro(context);

    return (
      bg: isDark ? oscurecer(cs.surface) : const Color(0xFFF3F4F6),
      bd: isDark ? cs.outlineVariant : const Color(0xFFE5E7EB),
      fg: cs.onSurface,
    );
  }
}

class TemaCalculadora extends StatelessWidget {
  const TemaCalculadora({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Theme(
    data: EstilosCalculadora.tema(context),
    child: Builder(builder: builder),
  );
}
