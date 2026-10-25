import 'package:flutter/material.dart';

import '../movimiento/movimiento_app.dart';

/// Conserva el destino de Volver para una pantalla abierta desde la búsqueda.
class RegresoBusquedaApp extends InheritedWidget {
  const RegresoBusquedaApp({
    super.key,
    required this.onVolver,
    required super.child,
  });

  final VoidCallback onVolver;

  static VoidCallback? de(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RegresoBusquedaApp>()
      ?.onVolver;

  @override
  bool updateShouldNotify(RegresoBusquedaApp oldWidget) =>
      onVolver != oldWidget.onVolver;
}

/// Renueva los Hero retenidos tras cerrar una búsqueda hacia otro destino.
class CicloBusquedaApp extends InheritedWidget {
  const CicloBusquedaApp({
    super.key,
    required this.revision,
    required super.child,
    this.barraExterna = false,
  });

  final int revision;
  final bool barraExterna;

  static bool barraExternaDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CicloBusquedaApp>()
          ?.barraExterna ??
      false;

  static int revisionDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CicloBusquedaApp>()
          ?.revision ??
      0;

  @override
  bool updateShouldNotify(CicloBusquedaApp oldWidget) =>
      revision != oldWidget.revision || barraExterna != oldWidget.barraExterna;
}

/// El acceso y el campo comparten superficie y vuelo entre ambas páginas.
class BarraBusquedaApp extends StatelessWidget {
  const BarraBusquedaApp({
    super.key,
    this.onTap,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = 'Buscar en Trayectorias…',
    this.enVuelo = false,
    this.textoEnVuelo = '',
    this.avanceCampo = 0,
  });

  static const etiqueta = 'busqueda-global-compartida';
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hintText;
  final bool enVuelo;
  final String textoEnVuelo;
  final double avanceCampo;

  @override
  Widget build(BuildContext context) {
    final superficie = _superficie(context);
    if (enVuelo) return superficie;
    return Hero(
      key: ValueKey(CicloBusquedaApp.revisionDe(context)),
      tag: etiqueta,
      reverseCurve: Curves.easeInOutCubic,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: (_, animation, direction, origen, destino) {
        final volviendo = direction == HeroFlightDirection.pop;
        final campoContext = volviendo ? origen : destino;
        final accesoContext = volviendo ? destino : origen;
        final campo = campoContext
            .findAncestorWidgetOfExactType<BarraBusquedaApp>()!;
        final acceso = accesoContext
            .findAncestorWidgetOfExactType<BarraBusquedaApp>()!;
        // Capturar el texto evita depender de un controlador que se dispone
        // al cerrar la página. El cambio a la etiqueta ocurre durante el vuelo.
        final texto = campo.controller?.text ?? '';
        return Theme(
          data: Theme.of(campoContext),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => BarraBusquedaApp(
              enVuelo: true,
              hintText: acceso.hintText,
              textoEnVuelo: texto,
              avanceCampo: const Interval(
                0.25,
                0.75,
              ).transform(animation.value),
            ),
          ),
        );
      },
      child: RepaintBoundary(child: superficie),
    );
  }

  Widget _superficie(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    final opacidadEtiqueta = textoEnVuelo.isEmpty
        ? 1.0
        : 1 - const Interval(0, 0.35).transform(avanceCampo);
    final opacidadConsulta = const Interval(0.65, 1).transform(avanceCampo);
    final contenido = SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0C66E4), Color(0xFF7C66E8)],
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: controller == null || enVuelo
                  ? Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Opacity(
                          opacity: opacidadEtiqueta,
                          child: Text(
                            hintText,
                            style: estilo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (textoEnVuelo.isNotEmpty)
                          Opacity(
                            opacity: opacidadConsulta,
                            child: Text(
                              textoEnVuelo,
                              style: estilo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    )
                  : TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: estilo,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      decoration:
                          InputDecoration.collapsed(
                            hintText: hintText,
                            hintStyle: estilo,
                          ).copyWith(
                            filled: false,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                    ),
            ),
            const SizedBox(width: 8),
            // Igual espacio para el botón, el campo y el vuelo: el texto y
            // los iconos no cambian de posición al entregar el Hero.
            SizedBox(
              width: 48,
              height: 48,
              child: controller == null || enVuelo
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: opacidadEtiqueta,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        if (textoEnVuelo.isNotEmpty)
                          Opacity(
                            opacity: opacidadConsulta,
                            child: Icon(
                              Icons.close_rounded,
                              color: scheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                      ],
                    )
                  : ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller!,
                      builder: (context, value, _) => IconButton(
                        tooltip: value.text.isEmpty
                            ? 'Escribir búsqueda'
                            : 'Limpiar búsqueda',
                        onPressed: value.text.isEmpty
                            ? focusNode?.requestFocus
                            : onClear,
                        color: scheme.onSurfaceVariant,
                        icon: Icon(
                          value.text.isEmpty
                              ? Icons.arrow_forward_rounded
                              : Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(31),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null || enVuelo
          ? contenido
          : Semantics(
              button: true,
              label: 'Buscar en Trayectorias',
              child: InkWell(onTap: onTap, child: contenido),
            ),
    );
  }
}

/// El Hero mueve la barra; la página no se desplaza por segunda vez.
class RutaBusquedaApp<T> extends RutaMovimientoApp<T> {
  RutaBusquedaApp({required super.builder});

  // El origen queda fijo mientras el Hero se mueve entre ambas superficies.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
