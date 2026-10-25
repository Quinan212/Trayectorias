import 'dart:convert';
import 'dart:io';

import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sin trayectoria centra la sincronización y conserva solo la búsqueda inferior',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
      final localLoaded = ValueNotifier<bool>(true);
      final selectedCareer = ValueNotifier<int>(0);
      final reset = ValueNotifier<int>(0);
      final actionRequest = ValueNotifier<SolicitudInicioAtlassian?>(null);

      addTearDown(() {
        trajectory.dispose();
        localLoaded.dispose();
        selectedCareer.dispose();
        reset.dispose();
        actionRequest.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: PantallaInicioReactDeveloper(
            trajectoryListenable: trajectory,
            localLoadedListenable: localLoaded,
            selectedCareerListenable: selectedCareer,
            resetListenable: reset,
            actionRequestListenable: actionRequest,
            onTrajectoryChanged: (_) {},
            onNavigate: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pump();

      final sageLogo = find.byKey(
        const ValueKey<String>('inicio-react-sync-sage-logo'),
      );
      final syncButton = find.byKey(
        const ValueKey<String>('inicio-react-sync-button'),
      );

      expect(sageLogo, findsOneWidget);
      expect(syncButton, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('inicio-react-liquid-search')),
        findsOneWidget,
      );
      expect(find.text('explorá'), findsNothing);
      expect(find.text('la app'), findsNothing);
      expect(find.text('mi registro'), findsNothing);
      expect(
        tester.getSize(sageLogo).width,
        greaterThan(tester.getSize(syncButton).width),
      );
      expect(
        tester.getCenter(sageLogo).dy,
        closeTo(tester.getCenter(syncButton).dy, 1),
      );
    },
  );

  test('el campo compartido usa una única superficie', () {
    final source = File(
      'lib/compartido/navegacion/barra_busqueda_app.dart',
    ).readAsStringSync(encoding: utf8);

    expect(source, contains('filled: false'));
    expect(source, contains('fillColor: Colors.transparent'));
    expect(source, contains('enabledBorder: InputBorder.none'));
    expect(source, contains('focusedBorder: InputBorder.none'));
    expect(source, contains('contentPadding: EdgeInsets.zero'));
  });
}
