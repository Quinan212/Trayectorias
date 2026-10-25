import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Un mismo ritmo para páginas, secciones, tarjetas y respuestas al toque.
abstract final class MovimientoApp {
  static const entrada = Duration(milliseconds: 240);
  static const ruta = Duration(milliseconds: 280);
  static const salida = Duration(milliseconds: 220);
  static const respuesta = Duration(milliseconds: 120);
  static const presion = Duration(milliseconds: 60);
  static const curva = Curves.easeOutCubic;

  static Duration duracion(BuildContext context, Duration normal) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;

  static void volverAlInicio(
    BuildContext context,
    ScrollController controller,
  ) {
    if (!controller.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(0);
    } else {
      unawaited(controller.animateTo(0, duration: salida, curve: curva));
    }
  }
}

class EntradaContenidoApp extends StatelessWidget {
  const EntradaContenidoApp({super.key, required this.child, this.orden = 0});

  final Widget child;
  final int orden;

  @override
  Widget build(BuildContext context) {
    final reducido = MediaQuery.disableAnimationsOf(context);
    final demora = reducido ? 0 : orden.clamp(0, 3) * 25;
    final total = MovimientoApp.entrada.inMilliseconds + demora;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reducido ? 1 : 0, end: 1),
      duration: reducido ? Duration.zero : Duration(milliseconds: total),
      child: child,
      builder: (context, tiempo, child) {
        final avance = reducido
            ? 1.0
            : ((tiempo * total - demora) / MovimientoApp.entrada.inMilliseconds)
                  .clamp(0.0, 1.0);
        final progreso = MovimientoApp.curva.transform(avance);
        return Opacity(
          opacity: progreso,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progreso)),
            child: Transform.scale(
              scale: 1,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ToqueMovimientoApp extends StatefulWidget {
  const ToqueMovimientoApp({
    super.key,
    required this.child,
    this.habilitado = true,
  });

  final Widget child;
  final bool habilitado;

  @override
  State<ToqueMovimientoApp> createState() => _ToqueMovimientoAppState();
}

class _ToqueMovimientoAppState extends State<ToqueMovimientoApp> {
  final Set<int> _punteros = <int>{};

  void _actualizar(int puntero, bool presionado) {
    if (!widget.habilitado) return;
    setState(() {
      if (presionado) {
        _punteros.add(puntero);
      } else {
        _punteros.remove(puntero);
      }
    });
  }

  @override
  void didUpdateWidget(ToqueMovimientoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.habilitado) _punteros.clear();
  }

  @override
  Widget build(BuildContext context) {
    final presionado = widget.habilitado && _punteros.isNotEmpty;
    return Listener(
      onPointerDown: (event) => _actualizar(event.pointer, true),
      onPointerUp: (event) => _actualizar(event.pointer, false),
      onPointerCancel: (event) => _actualizar(event.pointer, false),
      child: AnimatedScale(
        scale: presionado && !MediaQuery.disableAnimationsOf(context)
            ? 0.975
            : 1,
        duration: MovimientoApp.duracion(
          context,
          presionado ? MovimientoApp.presion : MovimientoApp.respuesta,
        ),
        curve: MovimientoApp.curva,
        child: widget.child,
      ),
    );
  }
}

/// Conserva cada navegador y su scroll; sólo anima y activa la sección visible.
class SeccionesMovimientoApp extends StatefulWidget {
  const SeccionesMovimientoApp({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<SeccionesMovimientoApp> createState() => _SeccionesMovimientoAppState();
}

class _SeccionesMovimientoAppState extends State<SeccionesMovimientoApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reloj = AnimationController(vsync: this);
  bool _reducido = false;
  double _direccion = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducido = MediaQuery.disableAnimationsOf(context);
    _reloj.duration = MovimientoApp.duracion(context, MovimientoApp.entrada);
    if (_reducido) {
      _reloj.value = 1;
    } else if (_reloj.value == 0 && !_reloj.isAnimating) {
      _reloj.forward();
    }
  }

  @override
  void didUpdateWidget(SeccionesMovimientoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _direccion = widget.index >= oldWidget.index ? 1 : -1;
    if (_reducido) {
      _reloj.value = 1;
    } else {
      _reloj.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var index = 0; index < widget.children.length; index++)
        Offstage(
          offstage: index != widget.index,
          child: TickerMode(
            enabled: index == widget.index,
            child: HeroMode(
              enabled: index == widget.index,
              child: ExcludeFocus(
                excluding: index != widget.index,
                child: AnimatedBuilder(
                  animation: _reloj,
                  child: widget.children[index],
                  builder: (context, child) {
                    final progreso = index != widget.index || _reducido
                        ? 1.0
                        : MovimientoApp.curva.transform(_reloj.value);
                    return Opacity(
                      opacity: 1,
                      child: Transform.translate(
                        offset: Offset(12 * _direccion * (1 - progreso), 0),
                        child: Transform.scale(scale: 1, child: child),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

Widget transicionPaginaApp(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final entrada = animation.drive(CurveTween(curve: Curves.easeInOutCubic));
  final salida = secondaryAnimation.drive(
    CurveTween(curve: Curves.easeInOutCubic),
  );
  // Las páginas conservan su fondo opaco: el desplazamiento evita mezclar
  // textos del origen y el destino. La aparición queda en el contenido.
  return SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(entrada),
    child: SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.025, 0),
      ).animate(salida),
      child: child,
    ),
  );
}

class RutaMovimientoApp<T> extends MaterialPageRoute<T> {
  RutaMovimientoApp({
    required super.builder,
    super.settings,
    this.animarEntrada = true,
  });

  final bool animarEntrada;

  @override
  Duration get transitionDuration => !animarEntrada
      ? Duration.zero
      : navigator == null
      ? MovimientoApp.ruta
      : MovimientoApp.duracion(navigator!.context, MovimientoApp.ruta);

  @override
  Duration get reverseTransitionDuration => navigator == null
      ? MovimientoApp.salida
      : MovimientoApp.duracion(navigator!.context, MovimientoApp.salida);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // El gesto de volver en iOS conserva su transición interactiva nativa.
    if (Theme.of(context).platform == TargetPlatform.iOS &&
        !MediaQuery.disableAnimationsOf(context)) {
      return const CupertinoPageTransitionsBuilder().buildTransitions<T>(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return transicionPaginaApp(context, animation, secondaryAnimation, child);
  }
}
