import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/navegacion/barra_busqueda_app.dart';
import '../../administrador/pantallas/acceso_administrador_pantalla.dart';
import '../tema/tema_atlassian.dart';

void volverPantallaAtlassian(BuildContext context) {
  final volver = RegresoBusquedaApp.de(context);
  if (volver != null) {
    volver();
  } else {
    Navigator.of(context).pop();
  }
}

String primerNombreAtlassian(String? nombreCompleto) {
  final normalizado = nombreCompleto?.trim() ?? '';
  if (normalizado.isEmpty) return '';
  return normalizado.split(RegExp(r'\s+')).first;
}

String saludoAtlassian(String? nombreCompleto) {
  final nombre = primerNombreAtlassian(nombreCompleto);
  return nombre.isEmpty ? '¡Bienvenido!' : 'Hola, $nombre';
}

enum AparienciaLozengeAtlassian {
  neutral,
  brand,
  success,
  warning,
  danger,
  discovery,
}

class PanelAtlassian extends StatelessWidget {
  const PanelAtlassian({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EspacioAtlassian.md),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = RadioAtlassian.large,
    this.selected = false,
    this.ordenEntrada = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool selected;
  final int ordenEntrada;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.surface;
    final borderSide = BorderSide(
      color: borderColor ?? (selected ? scheme.primary : scheme.outlineVariant),
      width: selected ? 2 : 1,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderSide,
    );

    if (onTap == null) {
      return EntradaContenidoApp(
        orden: ordenEntrada,
        child: Material(
          color: bg,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return EntradaContenidoApp(
      orden: ordenEntrada,
      child: ToqueMovimientoApp(
        child: Material(
          color: bg,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap!();
            },
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class EncabezadoPaginaAtlassian extends StatelessWidget {
  const EncabezadoPaginaAtlassian({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
    this.compact = false,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final bool compact;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 8 : 12,
            compact ? 8 : 12,
            bottom == null ? (compact ? 8 : 12) : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (leading != null || actions.isNotEmpty)
                            ? 56
                            : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: centerTitle
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: centerTitle
                                ? TextAlign.center
                                : TextAlign.start,
                            style:
                                (compact
                                        ? Theme.of(context).textTheme.titleLarge
                                        : Theme.of(
                                            context,
                                          ).textTheme.headlineSmall)
                                    ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: centerTitle
                                  ? TextAlign.center
                                  : TextAlign.start,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (leading != null) Positioned(left: 0, child: leading!),
                  if (actions.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _separate(actions, const SizedBox(width: 4)),
                      ),
                    ),
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 12), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

class EncabezadoSeccionAtlassianColapsable extends StatefulWidget {
  const EncabezadoSeccionAtlassianColapsable({
    super.key,
    required this.scrollController,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
  });

  final ScrollController scrollController;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  State<EncabezadoSeccionAtlassianColapsable> createState() =>
      _EncabezadoSeccionAtlassianColapsableState();
}

class _EncabezadoSeccionAtlassianColapsableState
    extends State<EncabezadoSeccionAtlassianColapsable> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(
    covariant EncabezadoSeccionAtlassianColapsable oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) return;
    oldWidget.scrollController.removeListener(_handleScroll);
    widget.scrollController.addListener(_handleScroll);
    _handleScroll();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    final offset = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    final next = (offset / 72).clamp(0.0, 1.0).toDouble();
    if ((next - _progress).abs() < 0.01) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_progress - next).abs() >= 0.01) {
        setState(() => _progress = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = Curves.easeOutCubic.transform(_progress);
    final contentOpacity = (1 - progress * 1.35).clamp(0.0, 1.0).toDouble();
    final backgroundAlpha = (1 - progress).clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: theme.scaffoldBackgroundColor.withValues(
            alpha: backgroundAlpha,
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 72,
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(
                      alpha: backgroundAlpha,
                    ),
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: contentOpacity,
                    child: Transform.translate(
                      offset: Offset(-18 * progress, 0),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 56),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.subtitle != null &&
                                  widget.subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.leading != null)
                    Positioned(
                      left: 0,
                      child: IgnorePointer(
                        ignoring: contentOpacity <= 0.1,
                        child: Opacity(
                          opacity: contentOpacity,
                          child: widget.leading!,
                        ),
                      ),
                    ),
                  if (widget.actions.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: IgnorePointer(
                        ignoring: contentOpacity <= 0.1,
                        child: Opacity(
                          opacity: contentOpacity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _separate(
                              widget.actions,
                              const SizedBox(width: 4),
                            ).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AccesoBusquedaAtlassian extends StatelessWidget {
  const AccesoBusquedaAtlassian({
    super.key,
    required this.onTap,
    this.hintText = 'Buscar materias y carreras…',
  });

  final VoidCallback onTap;
  final String hintText;

  @override
  Widget build(BuildContext context) => BarraBusquedaApp(onTap: onTap);
}

class BotonAtlassian extends StatelessWidget {
  const BotonAtlassian({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.danger = false,
    this.expanded = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool danger;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 17 : 19),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 9 : 12,
    );

    Widget button;
    if (danger) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: PaletaAtlassian.danger,
          foregroundColor: Colors.white,
          padding: padding,
        ),
        child: child,
      );
    } else if (primary) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(padding: padding),
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: padding),
        child: child,
      );
    }

    final animated = ToqueMovimientoApp(
      habilitado: onPressed != null,
      child: button,
    );
    return expanded
        ? SizedBox(width: double.infinity, child: animated)
        : animated;
  }
}

class BotonIconoAtlassian extends StatelessWidget {
  const BotonIconoAtlassian({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = danger
        ? PaletaAtlassian.danger
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final background = selected ? scheme.primaryContainer : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          minimumSize: const Size(45, 45),
          side: selected ? BorderSide(color: scheme.primary) : null,
        ),
        icon: Icon(icon, size: 26),
      ),
    );
  }
}

class LozengeAtlassian extends StatelessWidget {
  const LozengeAtlassian({
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = switch (appearance) {
      AparienciaLozengeAtlassian.brand => (
        dark ? PaletaAtlassian.brandSubtleDark : PaletaAtlassian.brandSubtle,
        dark ? const Color(0xFFCCE0FF) : const Color(0xFF09326C),
      ),
      AparienciaLozengeAtlassian.success => (
        dark
            ? PaletaAtlassian.successSubtleDark
            : PaletaAtlassian.successSubtle,
        dark ? const Color(0xFFBAF3DB) : const Color(0xFF164B35),
      ),
      AparienciaLozengeAtlassian.warning => (
        dark
            ? PaletaAtlassian.warningSubtleDark
            : PaletaAtlassian.warningSubtle,
        dark ? const Color(0xFFF8E6A0) : const Color(0xFF5F3811),
      ),
      AparienciaLozengeAtlassian.danger => (
        dark ? PaletaAtlassian.dangerSubtleDark : PaletaAtlassian.dangerSubtle,
        dark ? const Color(0xFFFFD2CC) : const Color(0xFF5D1F1A),
      ),
      AparienciaLozengeAtlassian.discovery => (
        dark
            ? PaletaAtlassian.discoverySubtleDark
            : PaletaAtlassian.discoverySubtle,
        dark ? const Color(0xFFDFD8FD) : const Color(0xFF352C63),
      ),
      AparienciaLozengeAtlassian.neutral => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(RadioAtlassian.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.$2),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.$2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class CampoBusquedaAtlassian extends StatelessWidget {
  const CampoBusquedaAtlassian({
    super.key,
    required this.controller,
    this.hintText = 'Buscar…',
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.focusNode,
    this.pill = true,
    this.backgroundColor,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool pill;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF282C34) : scheme.surface;
    final borderColor = isDark
        ? const Color(0xFF3B404A)
        : scheme.outlineVariant;

    final radius = BorderRadius.circular(
      pill ? RadioAtlassian.pill : RadioAtlassian.medium,
    );
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor),
    );
    return Semantics(
      textField: true,
      label: hintText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: backgroundColor ?? defaultBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: pill ? 18 : 12,
            vertical: pill ? 14 : 12,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF1E88E5) : const Color(0xFF0E5E86),
            size: 21,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class SelectorAtlassian extends StatelessWidget {
  const SelectorAtlassian({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.expanded = true,
    this.enabled = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool expanded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: enabled ? scheme.surface : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RadioAtlassian.medium),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
    final semanticContent = Semantics(
      button: true,
      enabled: enabled,
      label: '$label: $value',
      child: content,
    );
    return expanded
        ? SizedBox(width: double.infinity, child: semanticContent)
        : semanticContent;
  }
}

class SegmentoAtlassian<T> {
  const SegmentoAtlassian({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class ControlSegmentadoAtlassian<T> extends StatelessWidget {
  const ControlSegmentadoAtlassian({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final T value;
  final List<SegmentoAtlassian<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: Semantics(
                selected: segment.value == value,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(segment.value),
                  borderRadius: BorderRadius.circular(RadioAtlassian.small),
                  child: AnimatedContainer(
                    duration: MovimientoApp.duracion(
                      context,
                      MovimientoApp.respuesta,
                    ),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: segment.value == value
                          ? scheme.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(RadioAtlassian.small),
                      boxShadow:
                          segment.value == value &&
                              Theme.of(context).brightness == Brightness.light
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (segment.icon != null) ...[
                          Icon(
                            segment.icon,
                            size: 17,
                            color: segment.value == value
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            segment.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: segment.value == value
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                  fontWeight: segment.value == value
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TarjetaAccionAtlassian extends StatelessWidget {
  const TarjetaAccionAtlassian({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.description,
    this.badge,
    this.compact = false,
  });

  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: description == null ? label : '$label. $description',
      child: SizedBox(
        height: compact ? 126.0 : 154.0,
        child: PanelAtlassian(
          onTap: onTap,
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        RadioAtlassian.medium,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : scheme.primary,
                      size: compact ? 19 : 21,
                    ),
                  ),
                  const Spacer(),
                  if (badge != null)
                    LozengeAtlassian(
                      label: badge!,
                      appearance: AparienciaLozengeAtlassian.brand,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              if (description != null && description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    description!,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MensajeSeccionAtlassian extends StatelessWidget {
  const MensajeSeccionAtlassian({
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = switch (appearance) {
      AparienciaLozengeAtlassian.success => (
        dark
            ? PaletaAtlassian.successSubtleDark
            : PaletaAtlassian.successSubtle,
        PaletaAtlassian.success,
      ),
      AparienciaLozengeAtlassian.warning => (
        dark
            ? PaletaAtlassian.warningSubtleDark
            : PaletaAtlassian.warningSubtle,
        PaletaAtlassian.warning,
      ),
      AparienciaLozengeAtlassian.danger => (
        dark ? PaletaAtlassian.dangerSubtleDark : PaletaAtlassian.dangerSubtle,
        PaletaAtlassian.danger,
      ),
      AparienciaLozengeAtlassian.discovery => (
        dark
            ? PaletaAtlassian.discoverySubtleDark
            : PaletaAtlassian.discoverySubtle,
        PaletaAtlassian.discovery,
      ),
      _ => (
        dark ? PaletaAtlassian.brandSubtleDark : PaletaAtlassian.brandSubtle,
        PaletaAtlassian.brand,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        border: Border.all(color: colors.$2.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colors.$2,
              borderRadius: BorderRadius.circular(RadioAtlassian.pill),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon ?? Icons.info_outline_rounded, color: colors.$2, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 10), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricaAtlassian extends StatelessWidget {
  const MetricaAtlassian({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.appearance = AparienciaLozengeAtlassian.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final AparienciaLozengeAtlassian appearance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (appearance) {
      AparienciaLozengeAtlassian.success => PaletaAtlassian.success,
      AparienciaLozengeAtlassian.warning => PaletaAtlassian.warning,
      AparienciaLozengeAtlassian.danger => PaletaAtlassian.danger,
      AparienciaLozengeAtlassian.discovery => PaletaAtlassian.discovery,
      AparienciaLozengeAtlassian.brand => PaletaAtlassian.brand,
      AparienciaLozengeAtlassian.neutral => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };

    return PanelAtlassian(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(RadioAtlassian.medium),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EstadoVacioAtlassian extends StatelessWidget {
  const EstadoVacioAtlassian({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(EspacioAtlassian.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RadioAtlassian.large),
                ),
                child: Icon(icon, color: scheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class BarraNavegacionAtlassian extends StatelessWidget {
  const BarraNavegacionAtlassian({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const destinations = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.event_note_outlined, Icons.event_note_rounded, 'Exámenes'),
    (Icons.account_tree_outlined, Icons.account_tree_rounded, 'Plan'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Materias'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Datos'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _DestinoNavegacionAtlassian(
                    icon: selectedIndex == index
                        ? destinations[index].$2
                        : destinations[index].$1,
                    label: destinations[index].$3,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinoNavegacionAtlassian extends StatelessWidget {
  const _DestinoNavegacionAtlassian({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: MovimientoApp.duracion(
                context,
                MovimientoApp.respuesta,
              ),
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(RadioAtlassian.medium),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavegacionLateralAtlassian extends StatelessWidget {
  const NavegacionLateralAtlassian({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.hidden,
    this.onExit,
    this.nombreEstudiante,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool hidden;
  final VoidCallback? onExit;
  final String? nombreEstudiante;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = hidden ? 0.0 : 180.0;

    return AnimatedContainer(
      duration: MovimientoApp.duracion(context, MovimientoApp.respuesta),
      curve: Curves.easeInOut,
      width: width,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 180.0,
          maxWidth: 180.0,
          child: SizedBox(
            width: 180.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(right: BorderSide(color: scheme.outlineVariant)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                  height: 56,
                                ), // Espacio para el botón de menú flotante
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    4,
                                    8,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            RadioAtlassian.medium,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.school_rounded,
                                          color: Colors.white,
                                          size: 21,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Trayectorias',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                            ),
                                            Text(
                                              saludoAtlassian(nombreEstudiante),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index <
                                      BarraNavegacionAtlassian
                                          .destinations
                                          .length;
                                  index++
                                ) ...[
                                  if (index == 4)
                                    Row(
                                      children: [
                                        Semantics(
                                          button: true,
                                          label: 'Acceso Admin',
                                          child: Tooltip(
                                            message: 'Acceso Administrador',
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    RadioAtlassian.medium,
                                                  ),
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const AccesoAdministradorPantalla(),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: scheme.primary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        RadioAtlassian.medium,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .admin_panel_settings_rounded,
                                                  size: 18,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _DestinoLateralAtlassian(
                                            icon: selectedIndex == index
                                                ? BarraNavegacionAtlassian
                                                      .destinations[index]
                                                      .$2
                                                : BarraNavegacionAtlassian
                                                      .destinations[index]
                                                      .$1,
                                            label: BarraNavegacionAtlassian
                                                .destinations[index]
                                                .$3,
                                            selected: selectedIndex == index,
                                            onTap: () => onSelected(index),
                                            collapsed: false,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    _DestinoLateralAtlassian(
                                      icon: selectedIndex == index
                                          ? BarraNavegacionAtlassian
                                                .destinations[index]
                                                .$2
                                          : BarraNavegacionAtlassian
                                                .destinations[index]
                                                .$1,
                                      label: BarraNavegacionAtlassian
                                          .destinations[index]
                                          .$3,
                                      selected: selectedIndex == index,
                                      onTap: () => onSelected(index),
                                      collapsed: false,
                                    ),
                                  const SizedBox(height: 4),
                                ],
                                const Spacer(),
                                if (onExit != null) ...[
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  _DestinoLateralAtlassian(
                                    icon: Icons.close_rounded,
                                    label: 'Cerrar laboratorio',
                                    selected: false,
                                    onTap: onExit!,
                                    collapsed: false,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinoLateralAtlassian extends StatelessWidget {
  const _DestinoLateralAtlassian({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        child: AnimatedContainer(
          duration: MovimientoApp.duracion(context, MovimientoApp.respuesta),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(RadioAtlassian.medium),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? scheme.primary : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SeparadorTituloAtlassian extends StatelessWidget {
  const SeparadorTituloAtlassian({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

PageRoute<T> rutaAtlassian<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool animarEntrada = true,
}) {
  return RutaMovimientoApp<T>(
    builder: builder,
    settings: settings,
    animarEntrada: animarEntrada,
  );
}

Future<T?> mostrarHojaAtlassian<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: AnimationStyle(
      duration: MovimientoApp.duracion(context, MovimientoApp.ruta),
      reverseDuration: MovimientoApp.duracion(context, MovimientoApp.salida),
    ),
    builder: builder,
  );
}

List<Widget> _separate(List<Widget> items, Widget separator) {
  if (items.length < 2) return items;
  return <Widget>[
    for (var index = 0; index < items.length; index++) ...[
      if (index > 0) separator,
      items[index],
    ],
  ];
}
