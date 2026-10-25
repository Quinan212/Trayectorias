import 'dart:convert';
import 'dart:io';

import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'el Inicio React queda reducido al encabezado y al acceso al buscador',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
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
            nota: '10.00',
          ),
        ],
      );

      final trajectory = TrayectoriaSageLaboratorio(
        perfil: const PerfilTrayectoriaSageLaboratorio(nombre: 'Alan'),
        carreras: const <CarreraTrayectoriaSageLaboratorio>[career],
        capturadaEn: DateTime(2026, 8, 21),
        sincronizadaEn: DateTime(2026, 8, 21, 15),
      );

      final trajectoryListenable = ValueNotifier<TrayectoriaSageLaboratorio?>(
        trajectory,
      );
      final localLoadedListenable = ValueNotifier<bool>(true);
      final selectedCareerListenable = ValueNotifier<int>(0);
      final resetListenable = ValueNotifier<int>(0);
      final actionRequestListenable = ValueNotifier<SolicitudInicioAtlassian?>(
        null,
      );

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        trajectoryListenable.dispose();
        localLoadedListenable.dispose();
        selectedCareerListenable.dispose();
        resetListenable.dispose();
        actionRequestListenable.dispose();
      });

      var searchTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: PantallaInicioReactDeveloper(
            trajectoryListenable: trajectoryListenable,
            localLoadedListenable: localLoadedListenable,
            selectedCareerListenable: selectedCareerListenable,
            resetListenable: resetListenable,
            actionRequestListenable: actionRequestListenable,
            onTrajectoryChanged: (_) {},
            onNavigate: (_) {},
            onSearch: () => searchTaps++,
            onExit: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text('Hola, Alan'), findsOneWidget);
      expect(find.text('tu trayectoria'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('inicio-react-search-home-empty')),
        findsOneWidget,
      );
      expect(find.text('empezá buscando lo que quieras'), findsNothing);
      expect(find.text('todo lo que necesitás está acá'), findsNothing);
      expect(
        find.byKey(const ValueKey('inicio-react-sync-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('inicio-react-document-shortcuts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inicio-react-document-situacion_academica')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inicio-react-document-analitico')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inicio-react-document-libreta')),
        findsOneWidget,
      );
      expect(find.text('Situación académica'), findsOneWidget);
      expect(find.text('Analítico'), findsOneWidget);
      expect(find.text('Libreta'), findsOneWidget);
      expect(find.byKey(const ValueKey('inicio-react-hero')), findsNothing);
      expect(find.byKey(const ValueKey('inicio-react-progress')), findsNothing);
      expect(find.byKey(const ValueKey('inicio-react-docs')), findsNothing);
      expect(find.byKey(const ValueKey('inicio-react-tools')), findsNothing);
      expect(find.byKey(const ValueKey('inicio-react-activity')), findsNothing);
      expect(
        find.byKey(const ValueKey('inicio-react-liquid-search')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('inicio-react-liquid-search')),
      );
      await tester.pump();
      expect(searchTaps, 1);
    },
  );

  testWidgets(
    'sin trayectoria muestra sincronización al centro más prompt y búsqueda',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trajectoryListenable = ValueNotifier<TrayectoriaSageLaboratorio?>(
        null,
      );
      final localLoadedListenable = ValueNotifier<bool>(true);
      final selectedCareerListenable = ValueNotifier<int>(0);
      final resetListenable = ValueNotifier<int>(0);
      final actionRequestListenable = ValueNotifier<SolicitudInicioAtlassian?>(
        null,
      );

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        trajectoryListenable.dispose();
        localLoadedListenable.dispose();
        selectedCareerListenable.dispose();
        resetListenable.dispose();
        actionRequestListenable.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: PantallaInicioReactDeveloper(
            trajectoryListenable: trajectoryListenable,
            localLoadedListenable: localLoadedListenable,
            selectedCareerListenable: selectedCareerListenable,
            resetListenable: resetListenable,
            actionRequestListenable: actionRequestListenable,
            onTrajectoryChanged: (_) {},
            onNavigate: (_) {},
            onSearch: () {},
            onExit: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const ValueKey<String>('inicio-react-search-home-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('inicio-react-empty-state')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('inicio-react-connect-card')),
        findsNothing,
      );
      expect(find.text('empezá buscando lo que quieras'), findsOneWidget);
      expect(find.text('todo lo que necesitás está acá'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('inicio-react-sync-button')),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey<String>('inicio-react-sync-sage-logo')),
          matching: find.byKey(
            const ValueKey<String>('inicio-react-sync-button'),
          ),
        ),
        findsNothing,
      );
      expect(find.text('sincronizar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('inicio-react-liquid-search')),
        findsOneWidget,
      );
    },
  );

  test('05 usa la barra compartida inferior y conserva su callback', () {
    final source = File(
      'lib/funcionalidades/laboratorio_atlassian/pantallas/'
      'pantalla_inicio_react_developer.dart',
    ).readAsStringSync(encoding: utf8);

    expect(source, contains("inicio-react-liquid-search"));
    expect(source, contains('BarraBusquedaApp('));
    expect(source, contains('onTap: onTap'));
    expect(source, isNot(contains('BackdropFilter(')));
    expect(source, contains('onTap: widget.onSearch'));
    expect(source, isNot(contains("inicio-react-search'")));
    expect(source, contains("inicio-react-layout"));
    expect(source, contains("Expanded("));
    expect(source, isNot(contains("SliverFillRemaining(")));
    expect(source, isNot(contains("fillOverscroll: true")));
    expect(source, contains("inicio-react-search-home-empty"));
    expect(source, contains("empezá buscando lo que quieras"));
    expect(source, contains("todo lo que necesitás está acá"));
    expect(source, contains("inicio-react-sync-button"));
    expect(source, contains('width: busy ? 176 : 128'));
    expect(source, contains("busy ? 'sincronizando…' : 'sincronizar'"));
    expect(source, contains('softWrap: false'));
    expect(source, contains("inicio-react-document-shortcuts"));
    expect(source, contains('inicio-react-document-\${document.tipo.clave}'));
    expect(source, contains('TipoDocumentoAcademicoSage.situacionAcademica'));
    expect(source, contains('TipoDocumentoAcademicoSage.analitico'));
    expect(source, contains('TipoDocumentoAcademicoSage.libreta'));
    expect(source, isNot(contains("primary: 'explorá', accent: 'la app'")));
  });

  test('04B compacta Bento y Chroma y elimina iconos gigantes de fondo', () {
    final source = File(
      'lib/funcionalidades/laboratorio_atlassian/pantallas/'
      'pantalla_inicio_react_developer.dart',
    ).readAsStringSync(encoding: utf8);

    expect(source, contains('height: item.wide ? 116 : 136'));
    expect(source, contains('height: 128'));
    expect(source, contains('width: 184'));
    expect(source, contains('_friendlyCareerTitle(career.nombre)'));
    expect(source, contains("inicio-react-glass-\${widget.label}"));
    expect(source, contains("inicio-react-glass-front-\${widget.label}"));
    expect(source, contains("inicio-react-glass-back-\${widget.label}"));
    expect(source, isNot(contains('left: _pressed ? 5 : 7')));
    expect(source, isNot(contains('AnimatedSlide(')));
    expect(source, contains('turns: _pressed ? 0.018 : 0'));
    expect(source, contains('scale: _pressed ? 0.95 : 0.92'));
    expect(source, isNot(contains('size: item.wide ? 104 : 90')));
  });

  test('Developer expone el clon y el Inicio vigente conserva su layout', () {
    final developer = File(
      'lib/funcionalidades/laboratorio_atlassian/pantallas/'
      'pantalla_acceso_developer_atlassian.dart',
    ).readAsStringSync(encoding: utf8);
    final original = File(
      'lib/funcionalidades/laboratorio_atlassian/pantallas/'
      'pantalla_inicio_atlassian.dart',
    ).readAsStringSync(encoding: utf8);

    expect(developer, contains("label: 'Inicio React'"));
    expect(developer, contains('Clon experimental del Inicio'));
    expect(original, contains('_PanelPerfilAtlassian('));
    expect(original, isNot(contains("ValueKey<String>('inicio-react-hero')")));
  });
}
