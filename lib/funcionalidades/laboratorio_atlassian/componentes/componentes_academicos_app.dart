import 'package:flutter/material.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/tema/tema_herramientas_app.dart';
import 'componentes_atlassian.dart';

Future<T?> mostrarHojaAcademicaAtlassian<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: temaHerramientasApp(context).colorScheme.surface,
  sheetAnimationStyle: AnimationStyle(
    duration: MovimientoApp.duracion(context, MovimientoApp.ruta),
    reverseDuration: MovimientoApp.duracion(context, MovimientoApp.salida),
  ),
  builder: (_) => TemaHerramientasApp(builder: builder),
);

(Color, Color) _coloresEtiquetaAcademica(
  BuildContext context,
  AparienciaLozengeAtlassian appearance,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (appearance) {
    AparienciaLozengeAtlassian.brand =>
      dark
          ? (const Color(0xFF223761), const Color(0xFFDDEAFF))
          : (const Color(0xFFE9F2FF), const Color(0xFF173D8F)),
    AparienciaLozengeAtlassian.success =>
      dark
          ? (const Color(0xFF143B32), const Color(0xFF9BE1D5))
          : (const Color(0xFFE1F5EF), const Color(0xFF0D5948)),
    AparienciaLozengeAtlassian.danger =>
      dark
          ? (const Color(0xFF321A1A), const Color(0xFFFFB4A9))
          : (const Color(0xFFFFEDEB), const Color(0xFF9E3025)),
    AparienciaLozengeAtlassian.warning =>
      dark
          ? (const Color(0xFF302710), const Color(0xFFFFD38A))
          : (const Color(0xFFFFF3D6), const Color(0xFF815000)),
    AparienciaLozengeAtlassian.discovery =>
      dark
          ? (const Color(0xFF352A53), const Color(0xFFE0D0FF))
          : (const Color(0xFFF1ECFF), const Color(0xFF51338A)),
    AparienciaLozengeAtlassian.neutral => (
      Theme.of(context).colorScheme.surfaceContainerLow,
      Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  };
}

class EtiquetaAcademicaAtlassian extends StatelessWidget {
  const EtiquetaAcademicaAtlassian({
    super.key,
    required this.label,
    this.appearance = AparienciaLozengeAtlassian.neutral,
    this.icon,
  });

  final String label;
  final AparienciaLozengeAtlassian appearance;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _coloresEtiquetaAcademica(
      context,
      appearance,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 15, color: foreground),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

double alturaEncabezadoAcademicoAtlassian(BuildContext context) {
  final theme = Theme.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final title = theme.textTheme.headlineSmall;
  final subtitle = theme.textTheme.bodySmall;
  final textHeight =
      (scaler.scale(title?.fontSize ?? 24) * (title?.height ?? 1.3))
          .ceilToDouble() +
      2 +
      (scaler.scale(subtitle?.fontSize ?? 12) * (subtitle?.height ?? 1.3))
          .ceilToDouble();
  return MediaQuery.paddingOf(context).top +
      (textHeight + 16 <= 72 ? 72 : textHeight + 24);
}

class EncabezadoAcademicoAtlassian extends StatelessWidget {
  const EncabezadoAcademicoAtlassian({
    super.key,
    required this.controller,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final ScrollController controller;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final amplio =
        alturaEncabezadoAcademicoAtlassian(context) -
            MediaQuery.paddingOf(context).top >
        72;
    return SizedBox(
      height: alturaEncabezadoAcademicoAtlassian(context),
      child: amplio
          ? EncabezadoPaginaAtlassian(
              title: title,
              subtitle: subtitle,
              centerTitle: true,
              actions: actions,
            )
          : EncabezadoSeccionAtlassianColapsable(
              scrollController: controller,
              title: title,
              subtitle: subtitle,
              actions: actions,
            ),
    );
  }
}

class FilaDatoAcademicoAtlassian extends StatelessWidget {
  const FilaDatoAcademicoAtlassian({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final titulo = Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
        final dato = Text(value, style: Theme.of(context).textTheme.bodyMedium);
        if (constraints.maxWidth < 380 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titulo, const SizedBox(height: 4), dato],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: titulo),
            const SizedBox(width: 12),
            Expanded(child: dato),
          ],
        );
      },
    ),
  );
}

class MensajeAcademicoAtlassian extends StatelessWidget {
  const MensajeAcademicoAtlassian({
    super.key,
    required this.title,
    required this.message,
    this.appearance = AparienciaLozengeAtlassian.brand,
    this.action,
    this.icon,
  });

  final String title;
  final String message;
  final AparienciaLozengeAtlassian appearance;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (_, foreground) = _coloresEtiquetaAcademica(context, appearance);
    return PanelAtlassian(
      ordenEntrada: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? Icons.info_outline_rounded, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(message, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class MetricaAcademicaAtlassian extends StatelessWidget {
  const MetricaAcademicaAtlassian({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.appearance = AparienciaLozengeAtlassian.neutral,
  });

  final String label;
  final String value;
  final IconData icon;
  final AparienciaLozengeAtlassian appearance;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _coloresEtiquetaAcademica(
      context,
      appearance,
    );
    final reducido = MediaQuery.disableAnimationsOf(context);
    final number = double.parse(value);
    return PanelAtlassian(
      padding: const EdgeInsets.all(14),
      ordenEntrada: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reducido ? number : 0, end: number),
                  duration: MovimientoApp.duracion(
                    context,
                    MovimientoApp.entrada,
                  ),
                  curve: MovimientoApp.curva,
                  builder: (context, value, _) => Text(
                    value.round().toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: foreground, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
