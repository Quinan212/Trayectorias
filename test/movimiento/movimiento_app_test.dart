import 'package:correlativas_historia/compartido/movimiento/movimiento_app.dart';
import 'package:correlativas_historia/compartido/navegacion/transiciones_paginas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _PantallaPersistente extends StatefulWidget {
  const _PantallaPersistente({super.key});

  @override
  State<_PantallaPersistente> createState() => _PantallaPersistenteState();
}

class _PantallaPersistenteState extends State<_PantallaPersistente>
    with SingleTickerProviderStateMixin {
  final texto = TextEditingController();
  final scroll = ScrollController();
  final foco = FocusNode();
  late final reloj = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..addListener(() => cuadros++);
  int cuadros = 0;

  @override
  void initState() {
    super.initState();
    reloj.repeat();
  }

  @override
  void dispose() {
    reloj.dispose();
    texto.dispose();
    scroll.dispose();
    foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      controller: scroll,
      children: [
        TextField(controller: texto, focusNode: foco),
        FilledButton(
          onPressed: () => Navigator.of(context).push<void>(
            RutaMovimientoApp<void>(
              builder: (_) => const Scaffold(body: Text('Detalle con ñ y á')),
            ),
          ),
          child: const Text('Abrir detalle'),
        ),
        for (var i = 0; i < 40; i++)
          SizedBox(height: 60, child: Text('Fila $i')),
      ],
    ),
  );
}

void main() {
  testWidgets('cambios rápidos conservan texto, scroll y navegación', (
    tester,
  ) async {
    final seccion = ValueNotifier<int>(0);
    final pagina = GlobalKey<_PantallaPersistenteState>();
    final navegadores = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
    ];
    addTearDown(seccion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: seccion,
          builder: (context, index, _) => SeccionesMovimientoApp(
            index: index,
            children: [
              Navigator(
                key: navegadores[0],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => _PantallaPersistente(key: pagina),
                ),
              ),
              Navigator(
                key: navegadores[1],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Otra sección')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final estado = pagina.currentState!;
    await tester.enterText(find.byType(TextField), 'Educación Física');
    estado.foco.unfocus();
    await tester.pump();
    estado.scroll.jumpTo(420);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      seccion.value = i.isEven ? 1 : 0;
      await tester.pump(const Duration(milliseconds: 35));
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(pagina.currentState, same(estado));
    expect(estado.texto.text, 'Educación Física');
    expect(estado.scroll.offset, 420);
    estado.scroll.jumpTo(0);
    await tester.pump();
    await tester.tap(find.text('Abrir detalle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 480));
    expect(find.text('Detalle con ñ y á'), findsOneWidget);
    seccion.value = 1;
    await tester.pump(const Duration(milliseconds: 480));
    expect(find.text('Detalle con ñ y á'), findsNothing);
    seccion.value = 0;
    await tester.pump(const Duration(milliseconds: 480));
    expect(find.text('Detalle con ñ y á'), findsOneWidget);
    navegadores[0].currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 480));
    expect(estado.texto.text, 'Educación Física');
    expect(tester.takeException(), isNull);
  });

  testWidgets('la sección oculta pausa sus efectos y pierde el foco', (
    tester,
  ) async {
    final seccion = ValueNotifier<int>(0);
    final pagina = GlobalKey<_PantallaPersistenteState>();
    addTearDown(seccion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: seccion,
          builder: (context, index, _) => SeccionesMovimientoApp(
            index: index,
            children: [
              _PantallaPersistente(key: pagina),
              const Text('Datos'),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final estado = pagina.currentState!;
    estado.foco.requestFocus();
    await tester.pump();
    expect(estado.foco.hasFocus, isTrue);
    seccion.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final cuadros = estado.cuadros;
    await tester.pump(const Duration(seconds: 2));
    expect(estado.cuadros, cuadros);
    expect(estado.foco.hasFocus, isFalse);
    seccion.value = 0;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(estado.cuadros, greaterThan(cuadros));
  });

  testWidgets('reducir movimiento conserva el formulario y muestra todo', (
    tester,
  ) async {
    final reducido = ValueNotifier<bool>(false);
    final pagina = GlobalKey<_PantallaPersistenteState>();
    addTearDown(reducido.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reducido,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: value),
            child: SeccionesMovimientoApp(
              index: 0,
              children: [
                EntradaContenidoApp(child: _PantallaPersistente(key: pagina)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final estado = pagina.currentState!;
    estado.texto.text = '¿Cuándo rindo Filosofía?';
    reducido.value = true;
    await tester.pump();
    expect(pagina.currentState, same(estado));
    expect(estado.texto.text, '¿Cuándo rindo Filosofía?');
    for (final opacity in tester.widgetList<Opacity>(find.byType(Opacity))) {
      expect(opacity.opacity, 1);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar el toque restaura escala y teclado activa el botón', (
    tester,
  ) async {
    final foco = FocusNode();
    var pulsaciones = 0;
    addTearDown(foco.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ToqueMovimientoApp(
              child: FilledButton(
                focusNode: foco,
                onPressed: () => pulsaciones++,
                child: const Text('Sincronizar'),
              ),
            ),
          ),
        ),
      ),
    );
    final gesto = await tester.startGesture(
      tester.getCenter(find.text('Sincronizar')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.975,
    );
    await gesto.cancel();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(pulsaciones, 0);
    foco.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pulsaciones, 1);
    await tester.tap(find.text('Sincronizar'));
    expect(pulsaciones, 2);
  });

  testWidgets('rutas normales y herramientas usan el mismo ritmo y vuelven', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(pageTransitionsTheme: buildAppPageTransitionsTheme()),
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    final route = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Plan')),
    );
    navigator.currentState!.push<void>(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(route.transitionDuration, MovimientoApp.ruta);
    expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destino preparado queda opaco y conserva el regreso animado', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    final route = RutaMovimientoApp<void>(
      animarEntrada: false,
      builder: (_) => const Scaffold(body: Text('Calendario')),
    );
    navigator.currentState!.push<void>(route);
    await tester.pump();
    await tester.pump();
    expect(route.animation!.value, 1);
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Calendario'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(route.animation!.status, AnimationStatus.reverse);
    expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 200));
    await route.completed;
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Calendario'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la transición no transparenta el origen a través del destino', (
    tester,
  ) async {
    final captura = GlobalKey();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captura,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(backgroundColor: Colors.red),
        ),
      ),
    );
    final route = RutaMovimientoApp<void>(
      builder: (_) => const Scaffold(backgroundColor: Colors.blue),
    );
    navigator.currentState!.push<void>(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190));
    await tester.runAsync(() async {
      final boundary =
          captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await boundary.toImage();
      final pixeles = await imagen.toByteData();
      // El centro de la zona cubierta debe conservar el azul del destino,
      // sin mezclar el rojo de la página que está debajo.
      final muestra =
          (imagen.height ~/ 2 * imagen.width + imagen.width * 4 ~/ 5) * 4;
      final color = pixeles!.buffer.asUint8List(muestra, 4);
      expect(color, [33, 150, 243, 255]);
      imagen.dispose();
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
