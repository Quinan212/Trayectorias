import 'package:correlativas_historia/compartido/navegacion/barra_busqueda_app.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la paleta React cambia superficies y texto con el brillo', (
    tester,
  ) async {
    late TemaReactDeveloper light;
    late TemaReactDeveloper dark;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            light = context.reactTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            dark = context.reactTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(light.isDark, isFalse);
    expect(dark.isDark, isTrue);
    expect(light.text.computeLuminance(), lessThan(0.25));
    expect(dark.text.computeLuminance(), greaterThan(0.70));
    expect(light.surfaceStrong.computeLuminance(), greaterThan(0.90));
    expect(light.canvas, const Color(0xFFF7FAFF));
    expect(light.surface.a, inInclusiveRange(0.82, 0.86));
    expect(light.border.a, greaterThan(0.48));
    expect(dark.resultSurface.computeLuminance(), lessThan(0.05));
  });

  testWidgets('el acceso compartido conserva contraste claro y oscuro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
    final loaded = ValueNotifier<bool>(true);
    final selectedCareer = ValueNotifier<int>(0);
    final reset = ValueNotifier<int>(0);
    final request = ValueNotifier<SolicitudInicioAtlassian?>(null);
    addTearDown(() {
      trajectory.dispose();
      loaded.dispose();
      selectedCareer.dispose();
      reset.dispose();
      request.dispose();
    });

    Future<Color> pump(Brightness brightness) async {
      final theme = brightness == Brightness.light
          ? ThemeData.light(useMaterial3: true)
          : ThemeData.dark(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: PantallaInicioReactDeveloper(
            trajectoryListenable: trajectory,
            localLoadedListenable: loaded,
            selectedCareerListenable: selectedCareer,
            resetListenable: reset,
            actionRequestListenable: request,
            onTrajectoryChanged: (_) {},
            onNavigate: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final surface = tester.widget<Material>(
        find.descendant(
          of: find.byType(BarraBusquedaApp),
          matching: find.byType(Material),
        ),
      );
      return surface.color!;
    }

    final light = await pump(Brightness.light);
    final dark = await pump(Brightness.dark);
    expect(light.computeLuminance(), greaterThan(0.75));
    expect(dark.computeLuminance(), lessThan(0.15));
    expect(find.text('todo lo que necesitás está acá'), findsOneWidget);
  });

  testWidgets('la búsqueda React reconstruye cards y SAGE en modo claro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
    final selectedCareer = ValueNotifier<int>(0);
    addTearDown(trajectory.dispose);
    addTearDown(selectedCareer.dispose);

    Future<(BoxDecoration, BoxDecoration, Color)> pump(
      Brightness brightness,
    ) async {
      final theme = brightness == Brightness.light
          ? ThemeData.light(useMaterial3: true)
          : ThemeData.dark(useMaterial3: true);
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
            key: ValueKey<Brightness>(brightness),
            theme: theme,
            home: PantallaBusquedaGlobalReactDeveloper(
              trajectoryListenable: trajectory,
              selectedCareerListenable: selectedCareer,
              onOpenDestination: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      final access = tester.widget<Container>(
        find.byKey(const ValueKey<String>('busqueda-react-access-Calendario')),
      );
      final search = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(BarraBusquedaApp),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        find.byKey(const ValueKey<String>('busqueda-react-bottom-fade')),
        findsNothing,
      );
      expect(find.byType(BarraBusquedaApp), findsOneWidget);
      expect(tester.getRect(find.byType(BarraBusquedaApp)).top, lessThan(100));

      await tester.drag(
        find.byKey(const ValueKey<String>('busqueda-react-landing')),
        const Offset(0, -560),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final sage = tester.widget<Container>(
        find.byKey(const ValueKey<String>('busqueda-react-sage-surface')),
      );

      final sageCard = find.byKey(
        const ValueKey<String>('busqueda-react-sage-card'),
      );
      await tester.ensureVisible(sageCard);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(sageCard);
      await tester.pump(const Duration(milliseconds: 300));

      if (brightness == Brightness.light) {
        final action = tester.widget<Ink>(
          find.byKey(
            const ValueKey<String>(
              'busqueda-react-sage-action-Sincronizar con SAGE',
            ),
          ),
        );
        final title = tester.widget<Text>(find.text('sincronizar con sage'));
        final icon = tester.widget<Icon>(
          find.byKey(
            const ValueKey<String>(
              'busqueda-react-sage-action-icon-Sincronizar con SAGE',
            ),
          ),
        );
        expect(action.height, 118);
        expect(title.maxLines, 2);
        expect(icon.color, const Color(0xFF6554C0));
      }

      return (
        access.decoration! as BoxDecoration,
        sage.decoration! as BoxDecoration,
        search.color!,
      );
    }

    final light = await pump(Brightness.light);
    final dark = await pump(Brightness.dark);

    final lightAccess = light.$1.gradient! as LinearGradient;
    final darkAccess = dark.$1.gradient! as LinearGradient;
    final lightSage = light.$2.gradient! as LinearGradient;
    final darkSage = dark.$2.gradient! as LinearGradient;

    expect(lightAccess.colors, hasLength(4));
    expect(lightAccess.colors.first.computeLuminance(), greaterThan(0.75));
    expect(lightAccess.colors.first.a, 1);
    expect(
      HSLColor.fromColor(lightAccess.colors.first).saturation,
      greaterThan(0.20),
    );
    expect(lightAccess.colors[1], Colors.white);
    expect(lightAccess.colors[2], Colors.white);
    expect(lightAccess.colors.last.computeLuminance(), greaterThan(0.85));
    expect(lightAccess.colors.last.a, 1);
    final lightAccessBorder = light.$1.border! as Border;
    expect(lightAccessBorder.top.color.a, greaterThan(0.58));
    expect(
      HSLColor.fromColor(lightAccessBorder.top.color).saturation,
      greaterThan(0.40),
    );
    expect(darkAccess.colors.last.computeLuminance(), lessThan(0.08));
    expect(lightSage.colors[1], Colors.white);
    expect(lightSage.colors[2], Colors.white);
    expect(lightSage.colors.last.computeLuminance(), greaterThan(0.90));
    expect(lightSage.colors.last.a, 1);
    expect(darkSage.colors.last.computeLuminance(), lessThan(0.04));
    expect(light.$3.computeLuminance(), greaterThan(0.75));
    expect(dark.$3.computeLuminance(), lessThan(0.15));
  });

  testWidgets(
    'el botón Volver claro usa una superficie circular sin sombra rectangular',
    (tester) async {
      tester.view.physicalSize = const Size(430, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
      final selectedCareer = ValueNotifier<int>(0);
      addTearDown(trajectory.dispose);
      addTearDown(selectedCareer.dispose);

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
            theme: ThemeData.light(useMaterial3: true),
            home: PantallaBusquedaGlobalReactDeveloper(
              trajectoryListenable: trajectory,
              selectedCareerListenable: selectedCareer,
              onOpenDestination: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      final material = tester.widget<Material>(
        find.byKey(const ValueKey<String>('busqueda-react-back-material')),
      );
      final shadow = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey<String>('busqueda-react-back-shadow')),
      );
      final shadowDecoration = shadow.decoration as BoxDecoration;
      expect(material.shape, isA<CircleBorder>());
      expect(material.clipBehavior, Clip.antiAlias);
      expect(material.elevation, 0);
      expect(material.color!.computeLuminance(), greaterThan(0.95));
      expect(shadowDecoration.shape, BoxShape.circle);
      expect(shadowDecoration.boxShadow, isNotEmpty);
    },
  );
}
