import 'dart:convert';
import 'dart:io';

import 'package:correlativas_historia/compartido/navegacion/barra_busqueda_app.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets(
    'el buscador mantiene el fondo negro bajo un tema exterior azul',
    (tester) async {
      await _montarEntrada(
        tester,
        parentTheme: ThemeData.dark(
          useMaterial3: true,
        ).copyWith(scaffoldBackgroundColor: const Color(0xFF000020)),
      );
      final scaffold = find.descendant(
        of: find.byType(PantallaBusquedaGlobalReactDeveloper),
        matching: find.byType(Scaffold),
      );
      expect(tester.widget<Scaffold>(scaffold).backgroundColor, Colors.black);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<Scaffold>(scaffold).backgroundColor, Colors.black);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'la espera baja un cuarto por visita hasta desaparecer sin parpadeo',
    (tester) async {
      await _montarEntrada(tester, openAsRoute: true);
      final skeleton = find.byKey(const ValueKey('busqueda-react-skeleton'));
      for (final milliseconds in <int>[2000, 1500, 1000, 500, 0, 0]) {
        await tester.tap(find.text('Abrir búsqueda'));
        await tester.pump();
        // Construye la ruta sin adelantar el reloj del skeleton.
        await tester.pump();
        expect(skeleton, findsOneWidget);
        expect(
          tester.widget<Skeletonizer>(skeleton).enabled,
          milliseconds > 0,
          reason:
              'Primera imagen de la apertura con espera de $milliseconds ms',
        );
        if (milliseconds > 0) {
          await tester.pump(Duration(milliseconds: milliseconds - 1));
          expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
          await tester.pump(const Duration(milliseconds: 1));
          expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
        }
        expect(find.byType(BarraBusquedaApp), findsOneWidget);
        Navigator.of(
          tester.element(find.byType(PantallaBusquedaGlobalReactDeveloper)),
        ).pop();
        await tester.pumpAndSettle();
        expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('el skeleton dura dos segundos y conserva barra y tarjetas', (
    tester,
  ) async {
    DestinoBusquedaAtlassian? opened;
    await _montarEntrada(
      tester,
      onOpen: (destination) async {
        opened = destination;
      },
    );
    final skeleton = find.byKey(const ValueKey('busqueda-react-skeleton'));
    final field = find.byKey(const ValueKey('busqueda-react-liquid-field'));
    final calendar = find.byKey(
      const ValueKey('busqueda-react-access-Calendario'),
    );
    final fieldElement = tester.element(field);
    final fieldRect = tester.getRect(field);
    final calendarElement = tester.element(calendar);
    final calendarRect = tester.getRect(calendar);
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
    expect(find.byType(BarraBusquedaApp), findsOneWidget);
    expect(find.ancestor(of: field, matching: skeleton), findsNothing);

    await tester.tap(calendar, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
    expect(opened, isNull);

    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
    expect(tester.element(field), same(fieldElement));
    expect(tester.getRect(field), fieldRect);
    expect(tester.element(calendar), same(calendarElement));
    expect(tester.getRect(calendar), calendarRect);
    await tester.tap(calendar);
    await tester.pump();
    expect(opened?.tipo, TipoDestinoBusquedaAtlassian.calendario);
    expect(tester.takeException(), isNull);
  });

  testWidgets('se puede escribir durante la entrada sin reiniciar el delay', (
    tester,
  ) async {
    await _montarEntrada(tester);
    final skeleton = find.byKey(const ValueKey('busqueda-react-skeleton'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'Educación Física');
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
    await tester.pump(const Duration(milliseconds: 810));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Educación Física',
    );
    await tester.enterText(find.byType(TextField), 'SAGE');
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
    expect(find.text('Abrir SAGE'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('con movimiento reducido el skeleton permanece estático', (
    tester,
  ) async {
    await _montarEntrada(tester, reducedMotion: true);
    final skeleton = find.byKey(const ValueKey('busqueda-react-skeleton'));
    final widget = tester.widget<Skeletonizer>(skeleton);
    expect(widget.enabled, isTrue);
    expect(widget.effect, isA<SolidColorEffect>());
    expect(widget.effect!.duration, Duration.zero);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'volver durante el skeleton cancela la espera y permite reentrar',
    (tester) async {
      await _montarEntrada(tester, openAsRoute: true);
      await tester.tap(find.text('Abrir búsqueda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final skeleton = find.byKey(const ValueKey('busqueda-react-skeleton'));
      expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
      await tester.tap(find.byKey(const ValueKey('busqueda-react-back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Abrir búsqueda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<Skeletonizer>(skeleton).enabled, isTrue);
      await tester.pump(const Duration(milliseconds: 1650));
      expect(tester.widget<Skeletonizer>(skeleton).enabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el clon React abre SAGE y separa cerrar sesión de Salir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const career = CarreraTrayectoriaSageLaboratorio(
      gridRowId: 'historia',
      careerKey: 'historia-pscs',
      nombre: 'Profesorado de Historia',
      institucion: 'Profesorado Superior de Ciencias Sociales',
      materias: <MateriaTrayectoriaSageLaboratorio>[
        MateriaTrayectoriaSageLaboratorio(
          idSage: '1',
          nombre: 'Historia de las Ideas',
          estadoOriginal: 'Aprobada',
          estado: EstadoMateriaSageLaboratorio.aprobada,
          anio: 1,
        ),
      ],
    );
    final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(
      TrayectoriaSageLaboratorio(
        perfil: const PerfilTrayectoriaSageLaboratorio(nombre: 'Alan'),
        carreras: const <CarreraTrayectoriaSageLaboratorio>[career],
        capturadaEn: DateTime(2026, 8, 21),
        sincronizadaEn: DateTime(2026, 8, 21, 15),
      ),
    );
    final selectedCareer = ValueNotifier<int>(0);
    addTearDown(trajectory.dispose);
    addTearDown(selectedCareer.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });

    DestinoBusquedaAtlassian? opened;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorTodosLosExamenes.overrideWith(
            (ref) async => const <EventoExamen>[],
          ),
          proveedorContenidosCurriculares.overrideWith(
            (ref) async => const <ContenidoCurricular>[],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: PantallaBusquedaGlobalReactDeveloper(
            trajectoryListenable: trajectory,
            selectedCareerListenable: selectedCareer,
            onOpenDestination: (destination) async {
              opened = destination;
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.byKey(const ValueKey('busqueda-react-magic-bento')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('busqueda-react-liquid-field')),
      findsOneWidget,
    );
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.filled, isFalse);
    expect(textField.decoration?.fillColor, Colors.transparent);
    expect(textField.decoration?.border, InputBorder.none);
    expect(textField.decoration?.enabledBorder, InputBorder.none);
    expect(textField.decoration?.focusedBorder, InputBorder.none);
    expect(textField.decoration?.contentPadding, EdgeInsets.zero);
    expect(textField.decoration?.isCollapsed, isTrue);
    expect(textField.decoration?.hintText, 'Buscar en Trayectorias…');

    await tester.tap(find.byKey(const ValueKey('busqueda-react-sage-card')));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('abrir sage'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abrir sage');
    await tester.pump(const Duration(milliseconds: 190));
    await tester.tap(find.text('Abrir SAGE').first);
    await tester.pump();
    expect(opened?.tipo, TipoDestinoBusquedaAtlassian.sage);

    opened = null;
    await tester.enterText(find.byType(TextField), 'cerrar sesión');
    await tester.pump(const Duration(milliseconds: 190));

    expect(find.text('Cerrar sesión de SAGE'), findsAtLeastNWidgets(1));
    expect(find.text('Salir'), findsNothing);
    expect(
      find.byKey(const ValueKey('busqueda-react-gooey-filter')),
      findsOneWidget,
    );

    opened = null;
    await tester.enterText(find.byType(TextField), 'el analitico academico');
    await tester.pump(const Duration(milliseconds: 190));
    expect(find.text('Analítico'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Analítico').first);
    await tester.pump();
    expect(opened?.tipo, TipoDestinoBusquedaAtlassian.documentoAcademico);
    expect(opened?.tipoDocumento, TipoDocumentoAcademicoSage.analitico);

    opened = null;
    await tester.enterText(find.byType(TextField), 'la libreta academica');
    await tester.pump(const Duration(milliseconds: 190));
    expect(find.text('Libreta'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Libreta').first);
    await tester.pump();
    expect(opened?.tipo, TipoDestinoBusquedaAtlassian.documentoAcademico);
    expect(opened?.tipoDocumento, TipoDocumentoAcademicoSage.libreta);

    opened = null;
    await tester.enterText(find.byType(TextField), 'resumen academico');
    await tester.pump(const Duration(milliseconds: 190));
    expect(find.text('Situación académica'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Situación académica').first);
    await tester.pump();
    expect(opened?.tipo, TipoDestinoBusquedaAtlassian.documentoAcademico);
    expect(
      opened?.tipoDocumento,
      TipoDocumentoAcademicoSage.situacionAcademica,
    );

    trajectory.value = null;
    await tester.enterText(find.byType(TextField), 'desincronizar');
    await tester.pump(const Duration(milliseconds: 190));
    expect(find.text('Desincronizar trayectoria'), findsNothing);
  });

  test('la búsqueda React corrige caché, teclado y sugerencias temporales', () {
    final source = File(
      'lib/funcionalidades/laboratorio_atlassian/busqueda/'
      'pantalla_busqueda_global_react_developer.dart',
    ).readAsStringSync(encoding: utf8);

    expect(source, contains('ValueListenableBuilder<int>'));
    expect(source, contains('_trajectoryFingerprint('));
    expect(source, contains('resizeToAvoidBottomInset: true'));
    expect(source, contains("title: 'Abrir SAGE'"));
    expect(source, contains("title: 'Situación académica'"));
    expect(source, contains("title: 'Analítico'"));
    expect(source, contains("title: 'Libreta'"));
    expect(source, contains('TipoDestinoBusquedaAtlassian.documentoAcademico'));
    expect(source, contains('if (!action.enabled) continue;'));
    expect(source, contains('monthNameAtlassian(targetMonth)'));
    expect(source, isNot(contains("'Mesas de agosto'")));
    expect(source, contains('busqueda-react-career-carousel'));
    expect(source, contains('busqueda-react-gooey-filter'));
    expect(source, contains('BarraBusquedaApp('));
    expect(source, contains('maxWidth: MediaQuery.sizeOf(context).width - 78'));
    expect(source, contains('overflow: TextOverflow.ellipsis'));
    expect(source, contains('assets/sage_wordmark_react.png'));
    expect(source, isNot(contains('Icons.hub_rounded')));
    expect(source, contains("subtitle: 'Mesas y fechas publicadas'"));
    expect(source, contains("subtitle: 'Mesas y llamados'"));
    expect(source, contains("subtitle: 'Materias y correlatividades'"));
    expect(source, contains("subtitle: 'Estados de tu trayectoria'"));
    expect(source, contains("subtitle: 'Perfil y carreras'"));
    expect(source, contains('action: data,\n                height: 148'));
    expect(
      source,
      contains(
        'action: plan,\n          height: 104,\n          horizontal: true',
      ),
    );
    expect(source, contains("primary: 'elegí la'"));
    expect(source, contains("accent: 'institución'"));
    expect(source, contains('logo_pscs_overlay_circular.png'));
    expect(source, contains('logo_artes_circular.png'));
    expect(source, contains('_careerWatermarkAsset(career)'));
    expect(source, contains('clipBehavior: Clip.antiAlias'));
    expect(source, contains('Positioned.fill('));
    expect(source, contains('Transform.translate('));
    expect(source, isNot(contains('EdgeInsets.only(right: -10)')));
    expect(source, isNot(contains('ClipOval(')));
    expect(
      source,
      isNot(contains('width: 50,\n                          height: 50')),
    );
  });
}

Future<void> _montarEntrada(
  WidgetTester tester, {
  Future<void> Function(DestinoBusquedaAtlassian)? onOpen,
  bool reducedMotion = false,
  bool openAsRoute = false,
  ThemeData? parentTheme,
}) async {
  tester.view.physicalSize = const Size(430, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
  final selectedCareer = ValueNotifier<int>(0);
  addTearDown(trajectory.dispose);
  addTearDown(selectedCareer.dispose);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  Widget search(BuildContext context) => PantallaBusquedaGlobalReactDeveloper(
    trajectoryListenable: trajectory,
    selectedCareerListenable: selectedCareer,
    onOpenDestination: onOpen ?? (_) async {},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorTodosLosExamenes.overrideWith(
          (ref) async => const <EventoExamen>[],
        ),
        proveedorContenidosCurriculares.overrideWith(
          (ref) async => const <ContenidoCurricular>[],
        ),
      ],
      child: MaterialApp(
        theme: parentTheme ?? ThemeData.dark(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: openAsRoute
            ? Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).push<void>(RutaBusquedaApp<void>(builder: search)),
                    child: const Text('Abrir búsqueda'),
                  ),
                ),
              )
            : Builder(builder: search),
      ),
    ),
  );
}
