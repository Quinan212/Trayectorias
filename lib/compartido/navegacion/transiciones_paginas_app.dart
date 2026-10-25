import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../movimiento/movimiento_app.dart';

class TransicionesPaginasApp extends PageTransitionsBuilder {
  const TransicionesPaginasApp();

  @override
  Duration get transitionDuration => MovimientoApp.ruta;

  @override
  Duration get reverseTransitionDuration => MovimientoApp.salida;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Theme.of(context).platform == TargetPlatform.iOS &&
        !MediaQuery.disableAnimationsOf(context)) {
      return const CupertinoPageTransitionsBuilder().buildTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return transicionPaginaApp(context, animation, secondaryAnimation, child);
  }
}

PageTransitionsTheme buildAppPageTransitionsTheme() {
  const PageTransitionsBuilder builder = TransicionesPaginasApp();
  return const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: builder,
      TargetPlatform.iOS: builder,
      TargetPlatform.macOS: builder,
      TargetPlatform.windows: builder,
      TargetPlatform.linux: builder,
      TargetPlatform.fuchsia: builder,
    },
  );
}
