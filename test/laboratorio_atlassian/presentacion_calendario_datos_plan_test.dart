import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:correlativas_historia/compartido/movimiento/movimiento_app.dart';
import 'package:correlativas_historia/compartido/navegacion/barra_busqueda_app.dart';
import 'package:correlativas_historia/datos/cargador_fuente_html.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_datos_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:correlativas_historia/modelos/materia.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _fecha = DateTime(2026, 10, 7);

EventoExamen _examen() => EventoExamen(
  careerId: 'historia',
  anio: 1,
  fecha: _fecha,
  hora: '19:00',
  materia: 'Educación y filosofía',
  instancia: 'llamado_1',
  docentes: const ['María Pérez'],
  actaUrl: null,
);

CarreraTrayectoriaSageLaboratorio _carrera() =>
    const CarreraTrayectoriaSageLaboratorio(
      gridRowId: 'historia',
      careerKey: 'historia',
      nombre: 'Profesorado de Historia',
      institucion: 'Instituto Superior de Formación Docente',
      materias: [
        MateriaTrayectoriaSageLaboratorio(
          idSage: 'educacion',
          nombre: 'Educación y filosofía',
          estadoOriginal: 'Aprobada',
          estado: EstadoMateriaSageLaboratorio.aprobada,
          anio: 2,
          nota: '9',
          fecha: '07/10/2026',
        ),
      ],
    );

class _Datos {
  final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
    TrayectoriaSageLaboratorio(
      perfil: const PerfilTrayectoriaSageLaboratorio(
        nombre: 'José Muñoz',
        dni: '12345678',
        campos: {'Correo electrónico': 'josé@example.com'},
      ),
      carreras: [_carrera()],
      capturadaEn: _fecha,
      sincronizadaEn: _fecha,
    ),
  );
  final cargado = ValueNotifier(true);
  final seleccion = ValueNotifier(0);
  final solicitud = ValueNotifier<SolicitudPlanAtlassian?>(null);
  Widget datos() => PantallaDatosAtlassian(
    trajectoryListenable: trayectoria,
    localLoadedListenable: cargado,
    selectedCareerListenable: seleccion,
    onDesynchronize: () {},
    onNavigate: (_) {},
    onSearch: () {},
  );
  Widget plan() =>
      PantallaPlanAtlassian(onSearch: () {}, requestListenable: solicitud);
  Widget buscador(Future<void> Function(DestinoBusquedaAtlassian) abrir) =>
      PantallaBusquedaGlobalReactDeveloper(
        trajectoryListenable: trayectoria,
        selectedCareerListenable: seleccion,
        onOpenDestination: abrir,
      );
  void dispose() {
    trayectoria.dispose();
    cargado.dispose();
    seleccion.dispose();
    solicitud.dispose();
  }
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  Brightness brightness = Brightness.dark,
  double escala = 1,
  bool reducido = false,
  Future<List<EventoExamen>> Function()? cargar,
  GlobalKey? captura,
  Size size = const Size(360, 640),
  String? fuente,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorTodosLosExamenes.overrideWith(
          (ref) => cargar?.call() ?? Future.value([_examen()]),
        ),
        proveedorContenidosCurriculares.overrideWith(
          (ref) async => const <ContenidoCurricular>[],
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness, fontFamily: fuente),
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            textScaler: TextScaler.linear(escala),
            disableAnimations: reducido,
          ),
          child: child!,
        ),
        home: RepaintBoundary(key: captura, child: pantalla),
      ),
    ),
  );
  await _avanzar(tester);
}

Future<void> _avanzar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _centrar(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: scrollable,
      maxScrolls: 70,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 350));
}

double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

void _paleta(WidgetTester tester, Finder pantalla, Brightness brillo) {
  final scaffold = find
      .descendant(of: pantalla, matching: find.byType(Scaffold))
      .first;
  final widget = tester.widget<Scaffold>(scaffold);
  expect(
    widget.backgroundColor,
    brillo == Brightness.dark ? Colors.black : const Color(0xFFF5F7FA),
  );
  final theme = Theme.of(tester.element(scaffold));
  for (final fondo in [
    theme.colorScheme.surface,
    theme.colorScheme.surfaceContainerLow,
  ]) {
    expect(
      _contraste(theme.colorScheme.onSurface, fondo),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contraste(theme.colorScheme.onSurfaceVariant, fondo),
      greaterThanOrEqualTo(4.5),
    );
  }
}

void main() {
  for (final brillo in Brightness.values) {
    for (final escala in [1.0, 2.0]) {
      testWidgets('calendario $brillo $escala: fechas legibles y área segura', (
        tester,
      ) async {
        await _montar(
          tester,
          PantallaCalendarioAtlassian(
            careerId: 'historia',
            initialDate: _fecha,
          ),
          brightness: brillo,
          escala: escala,
        );
        _paleta(tester, find.byType(PantallaCalendarioAtlassian), brillo);
        final listado = find.byKey(const ValueKey('calendario-contenido'));
        expect(tester.getRect(listado).bottom, 592);
        final hoy = find.widgetWithText(TextButton, 'Hoy');
        await _centrar(tester, hoy);
        final button = tester.widget<TextButton>(hoy);
        expect(
          _contraste(
            button.style!.foregroundColor!.resolve({})!,
            Theme.of(tester.element(hoy)).colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
        final celda = find.byKey(const ValueKey('calendario-dia-2026-10-7'));
        await _centrar(tester, celda);
        final container = tester.widget<AnimatedContainer>(celda);
        final fondo = (container.decoration! as BoxDecoration).color!;
        final numero = tester.widget<Text>(
          find.descendant(of: celda, matching: find.byType(Text)),
        );
        expect(
          _contraste(numero.style!.color!, fondo),
          greaterThanOrEqualTo(4.5),
        );
        final anterior = find.byKey(const ValueKey('calendario-dia-2026-9-30'));
        final n = tester.widget<Text>(
          find.descendant(of: anterior, matching: find.byType(Text)),
        );
        final c = tester.widget<AnimatedContainer>(anterior);
        expect(
          _contraste(n.style!.color!, (c.decoration! as BoxDecoration).color!),
          greaterThanOrEqualTo(4.5),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'Datos $brillo $escala: perfil, métricas y detalle adaptables',
        (tester) async {
          final datos = _Datos();
          addTearDown(datos.dispose);
          await _montar(
            tester,
            datos.datos(),
            brightness: brillo,
            escala: escala,
          );
          _paleta(tester, find.byType(PantallaDatosAtlassian), brillo);
          expect(
            tester
                .getRect(find.byKey(const ValueKey('datos-contenido')))
                .bottom,
            592,
          );
          for (final text in [
            'José Muñoz',
            'Correo electrónico',
            'josé@example.com',
            'Desincronizar',
          ]) {
            await _centrar(tester, find.text(text));
            expect(tester.takeException(), isNull);
          }
          final carrera = find.text('Profesorado de Historia');
          await _centrar(tester, carrera);
          await tester.tap(carrera);
          await _avanzar(tester);
          expect(find.byType(PantallaDetalleCarreraAtlassian), findsOneWidget);
          _paleta(tester, find.byType(PantallaDetalleCarreraAtlassian), brillo);
          final list = find.descendant(
            of: find.byType(PantallaDetalleCarreraAtlassian),
            matching: find.byType(ListView),
          );
          expect(tester.getRect(list).bottom, 592);
          final ultimo = find.text('Cursando');
          await _centrar(tester, ultimo);
          expect(tester.getRect(ultimo).bottom, lessThan(592));
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Plan completo $brillo $escala: filtros y tarjetas sin desbordes',
        (tester) async {
          final datos = _Datos();
          addTearDown(datos.dispose);
          await tester.runAsync(() async {
            await cargarPlanDesdeAssetHtml('assets/data/historia.json');
          });
          await _montar(
            tester,
            datos.plan(),
            brightness: brillo,
            escala: escala,
          );
          await tester.runAsync(() async {
            await tester
                .widget<FutureBuilder<DatosPlan>>(
                  find.byType(FutureBuilder<DatosPlan>),
                )
                .future;
          });
          await _avanzar(tester);
          _paleta(tester, find.byType(PantallaPlanAtlassian), brillo);
          final listado = find.byKey(const ValueKey('plan-contenido'));
          expect(
            listado,
            findsOneWidget,
            reason: tester
                .widgetList<Text>(find.byType(Text))
                .map((t) => t.data)
                .join(' | '),
          );
          expect(tester.getRect(listado).bottom, 592);
          final restablecer = find.widgetWithText(TextButton, 'Restablecer');
          final boton = tester.widget<TextButton>(restablecer);
          expect(
            _contraste(
              boton.style!.foregroundColor!.resolve({})!,
              Theme.of(tester.element(restablecer)).colorScheme.surface,
            ),
            greaterThanOrEqualTo(4.5),
          );
          await tester.enterText(find.byType(TextField), 'didáctica');
          await _avanzar(tester);
          await _centrar(tester, find.text('Didáctica General'));
          expect(tester.takeException(), isNull);
          await _centrar(tester, find.text('Restablecer'));
          await tester.tap(find.text('Restablecer'));
          await _avanzar(tester);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            isEmpty,
          );
          await _centrar(tester, find.text('Carrera'));
          await tester.tap(find.text('Carrera'));
          await _avanzar(tester);
          expect(find.text('Seleccionar carrera'), findsOneWidget);
          await _centrar(tester, find.text('Profesorado en Educación Física'));
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('plan detalle $brillo $escala: nombre largo y correlativas', (
        tester,
      ) async {
        final base = Materia(
          id: 'base',
          codigo: '1',
          nombre: 'Educación y filosofía',
          anio: 2,
          formato: 'Anual',
          tipo: 'Materia',
          correlativas: const [],
          correlativasDetalladas: const [],
        );
        final siguiente = Materia(
          id: 'siguiente',
          codigo: '2',
          nombre:
              'Problemáticas históricas y práctica docente en las instituciones',
          anio: 3,
          formato: 'Taller de práctica',
          tipo: 'Materia',
          correlativas: const ['base'],
          correlativasDetalladas: const [],
        );
        await _montar(
          tester,
          PantallaDetallePlanAtlassian(
            subject: base,
            allSubjects: [base, siguiente],
            careerName: 'Profesorado de Historia',
          ),
          brightness: brillo,
          escala: escala,
        );
        _paleta(tester, find.byType(PantallaDetallePlanAtlassian), brillo);
        final list = find.byType(ListView);
        expect(tester.getRect(list).bottom, 592);
        await _centrar(tester, find.text('Sin correlativas'));
        expect(find.text('Sin correlativas'), findsOneWidget);
        await _centrar(tester, find.text(siguiente.displayNombre));
        expect(
          tester.getRect(find.text(siguiente.displayNombre)).bottom,
          lessThan(592),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'institución $brillo $escala: logo separado, contraste y accesos simétricos',
        (tester) async {
          final datos = _Datos();
          addTearDown(datos.dispose);
          await _montar(
            tester,
            datos.buscador((_) async {}),
            brightness: brillo,
            escala: escala,
          );
          final barra = find.byType(BarraBusquedaApp);
          final elemento = tester.element(barra), rect = tester.getRect(barra);
          final tarjeta = find.byKey(
            const ValueKey('busqueda-react-career-historia'),
          );
          await _centrar(tester, tarjeta);
          final container = tester.widget<Container>(tarjeta);
          final gradient =
              (container.decoration! as BoxDecoration).gradient!
                  as LinearGradient;
          for (final text in tester.widgetList<Text>(
            find.descendant(of: tarjeta, matching: find.byType(Text)),
          )) {
            for (final fondo in gradient.colors) {
              expect(
                _contraste(text.style!.color!, fondo),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
          expect(
            find.ancestor(of: tarjeta, matching: find.byType(BackdropFilter)),
            findsNothing,
          );
          final logo = tester.widget<Image>(
            find.descendant(of: tarjeta, matching: find.byType(Image)),
          );
          expect(logo.fit, BoxFit.contain);
          expect(
            find.descendant(
              of: tarjeta,
              matching: find.byType(ToqueMovimientoApp),
            ),
            findsNWidgets(4),
          );
          final acciones = [
            for (final nombre in ['plan', 'mesas', 'calendario', 'diseños'])
              find.byKey(ValueKey('busqueda-react-career-historia-$nombre')),
          ];
          expect(tester.getSize(acciones[0]), tester.getSize(acciones[1]));
          expect(tester.getSize(acciones[2]), tester.getSize(acciones[3]));
          expect(
            tester.getTopLeft(acciones[0]).dy,
            tester.getTopLeft(acciones[1]).dy,
          );
          expect(
            tester.getTopLeft(acciones[2]).dy,
            tester.getTopLeft(acciones[3]).dy,
          );
          expect(tester.element(barra), same(elemento));
          expect(tester.getRect(barra), rect);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('meses y días cambian sin superponer títulos ni perder eventos', (
    tester,
  ) async {
    await _montar(
      tester,
      PantallaCalendarioAtlassian(careerId: 'historia', initialDate: _fecha),
    );
    await _centrar(tester, find.byTooltip('Mes siguiente'));
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Octubre 2026'), findsNothing);
    expect(find.text('Noviembre 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Noviembre 2026'), findsNothing);
    expect(find.text('Octubre 2026'), findsOneWidget);
    final siete = find.byKey(const ValueKey('calendario-dia-2026-10-7'));
    await _centrar(tester, siete);
    await tester.tap(siete);
    await _avanzar(tester);
    await _centrar(tester, find.text('Educación y filosofía'));
    expect(find.text('Educación y filosofía'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'calendario mantiene skeleton al actualizar y respeta movimiento reducido',
    (tester) async {
      final cargas = <Completer<List<EventoExamen>>>[];
      await _montar(
        tester,
        const PantallaCalendarioAtlassian(careerId: 'historia'),
        reducido: true,
        cargar: () {
          final c = Completer<List<EventoExamen>>();
          cargas.add(c);
          return c.future;
        },
      );
      final skeleton = find.byWidgetPredicate(
        (w) => w is Skeletonizer && w.enabled,
      );
      expect(skeleton, findsOneWidget);
      final grid = find.byType(GridView);
      expect(tester.widget<GridView>(grid).semanticChildCount, 42);
      cargas.single.complete([_examen()]);
      await _avanzar(tester);
      expect(skeleton, findsNothing);
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pump();
      await tester.pump();
      expect(skeleton, findsOneWidget);
      expect(cargas.length, 2);
      cargas.last.complete([]);
      await _avanzar(tester);
      expect(skeleton, findsNothing);
      for (final animated in tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      )) {
        expect(animated.duration, Duration.zero);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('los cuatro accesos de institución conservan destino y carrera', (
    tester,
  ) async {
    final datos = _Datos();
    addTearDown(datos.dispose);
    final destinos = <DestinoBusquedaAtlassian>[];
    await _montar(
      tester,
      datos.buscador((d) async => destinos.add(d)),
      reducido: true,
    );
    final tarjeta = find.byKey(
      const ValueKey('busqueda-react-career-historia'),
    );
    await _centrar(tester, tarjeta);
    for (final nombre in ['plan', 'mesas', 'calendario', 'diseños']) {
      final boton = find.byKey(
        ValueKey('busqueda-react-career-historia-$nombre'),
      );
      await _centrar(tester, boton);
      await tester.tap(boton);
      await tester.pump();
    }
    expect(destinos.map((d) => d.careerId), everyElement('historia'));
    expect(destinos.map((d) => d.tipo).toList(), [
      TipoDestinoBusquedaAtlassian.seccion,
      TipoDestinoBusquedaAtlassian.seccion,
      TipoDestinoBusquedaAtlassian.calendario,
      TipoDestinoBusquedaAtlassian.disenos,
    ]);
    expect(destinos.take(2).map((d) => d.seccion).toList(), [2, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'capturas con tipografía real de cada pantalla, sin usar el escritorio',
    (tester) async {
      await tester.runAsync(() async {
        final loader = FontLoader('Inter');
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              await File('assets/fonts/Inter_24pt-Regular.ttf').readAsBytes(),
            ),
          ),
        );
        await loader.load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await cargarPlanDesdeAssetHtml('assets/data/historia.json');
      });
      final datos = _Datos();
      addTearDown(datos.dispose);
      for (final brillo in Brightness.values) {
        final modo = brillo == Brightness.dark ? 'oscuro' : 'claro';
        for (final caso in ['datos', 'plan', 'calendario', 'institucion']) {
          final captura = GlobalKey();
          final pantalla = switch (caso) {
            'datos' => datos.datos(),
            'plan' => datos.plan(),
            'calendario' => PantallaCalendarioAtlassian(
              careerId: 'historia',
              initialDate: _fecha,
            ),
            _ => datos.buscador((_) async {}),
          };
          await _montar(
            tester,
            pantalla,
            brightness: brillo,
            captura: captura,
            size: const Size(430, 980),
            fuente: 'Inter',
          );
          if (caso == 'plan') {
            await tester.runAsync(() async {
              await tester
                  .widget<FutureBuilder<DatosPlan>>(
                    find.byType(FutureBuilder<DatosPlan>),
                  )
                  .future;
            });
          }
          await _avanzar(tester);
          if (caso == 'institucion') {
            await _centrar(
              tester,
              find.byKey(const ValueKey('busqueda-react-career-historia')),
            );
          }
          await tester.runAsync(() async {
            final boundary =
                captura.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              'build/qa/775_${caso}_${modo}_final.png',
            ).writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
