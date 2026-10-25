import 'package:correlativas_historia/compartido/movimiento/movimiento_app.dart';
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

Future<void> _montar(
  WidgetTester tester, {
  required Brightness brightness,
  required double escala,
  bool reducido = false,
  Future<void> Function(DestinoBusquedaAtlassian)? abrir,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
  final carrera = ValueNotifier(0);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(trayectoria.dispose);
  addTearDown(carrera.dispose);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
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
        theme: ThemeData(brightness: brightness),
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 640),
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            textScaler: TextScaler.linear(escala),
            disableAnimations: reducido,
          ),
          child: child!,
        ),
        home: PantallaBusquedaGlobalReactDeveloper(
          trajectoryListenable: trayectoria,
          selectedCareerListenable: carrera,
          onOpenDestination: abrir ?? (_) async {},
        ),
      ),
    ),
  );
  await tester.pump();
}

double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
        'accesos $brightness escala $escala: contraste, entrada y barra fija',
        (tester) async {
          await _montar(tester, brightness: brightness, escala: escala);
          expect(
            tester
                .getRect(find.byKey(const ValueKey('busqueda-react-landing')))
                .bottom,
            640 - 48,
          );
          final barra = find.byType(BarraBusquedaApp);
          final elemento = tester.element(barra);
          final rect = tester.getRect(barra);
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.element(barra), same(elemento));
          expect(tester.getRect(barra), rect);
          await tester.pumpAndSettle();
          for (final nombre in [
            'Calendario',
            'Exámenes',
            'Datos',
            'Mis materias',
            'Plan completo',
          ]) {
            final tarjeta = find.byKey(
              ValueKey('busqueda-react-access-$nombre'),
            );
            await Scrollable.ensureVisible(
              tester.element(tarjeta),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            final container = tester.widget<Container>(tarjeta);
            final gradient =
                (container.decoration! as BoxDecoration).gradient!
                    as LinearGradient;
            final textos = tester.widgetList<Text>(
              find.descendant(of: tarjeta, matching: find.byType(Text)),
            );
            for (final texto in textos) {
              for (final fondo in gradient.colors) {
                expect(
                  _contraste(texto.style!.color!, fondo),
                  greaterThanOrEqualTo(4.5),
                );
              }
            }
            expect(
              find.ancestor(
                of: tarjeta,
                matching: find.byType(ToqueMovimientoApp),
              ),
              findsOneWidget,
            );
            expect(
              find.ancestor(of: tarjeta, matching: find.byType(BackdropFilter)),
              findsNothing,
            );
            expect(tester.getRect(barra), rect);
            expect(tester.takeException(), isNull);
          }
          final herramientas = find.byKey(
            const ValueKey('busqueda-react-tools-dock'),
          );
          await Scrollable.ensureVisible(
            tester.element(herramientas),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          final herramienta = find.byKey(
            const ValueKey('busqueda-react-tool-Diseños curriculares'),
          );
          final container = tester.widget<Container>(herramienta);
          final fondo = (container.decoration! as BoxDecoration).color!;
          final texto = tester.widget<Text>(
            find.descendant(of: herramienta, matching: find.byType(Text)),
          );
          expect(
            _contraste(texto.style!.color!, fondo),
            greaterThanOrEqualTo(4.5),
          );
          expect(tester.getBottomRight(herramientas).dy, lessThan(640 - 48));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'toque comparte el ritmo y vuelve a su escala sin alterar destino',
    (tester) async {
      DestinoBusquedaAtlassian? destino;
      await _montar(
        tester,
        brightness: Brightness.dark,
        escala: 1,
        abrir: (d) async {
          destino = d;
        },
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final tarjeta = find.byKey(
        const ValueKey('busqueda-react-access-Exámenes'),
      );
      final toque = find.ancestor(
        of: tarjeta,
        matching: find.byType(ToqueMovimientoApp),
      );
      final escala = find
          .descendant(of: toque, matching: find.byType(AnimatedScale))
          .first;
      final gesto = await tester.startGesture(tester.getCenter(tarjeta));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widget<AnimatedScale>(escala).scale, 0.975);
      await gesto.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(escala).scale, 1);
      expect(destino?.tipo, TipoDestinoBusquedaAtlassian.seccion);
      expect(destino?.seccion, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'movimiento reducido mantiene tarjetas visibles al salir del skeleton',
    (tester) async {
      await _montar(
        tester,
        brightness: Brightness.dark,
        escala: 1,
        reducido: true,
      );
      await tester.pump(const Duration(seconds: 2));
      final tarjeta = find.byKey(
        const ValueKey('busqueda-react-access-Calendario'),
      );
      final opacidades = tester.widgetList<Opacity>(
        find.ancestor(of: tarjeta, matching: find.byType(Opacity)),
      );
      expect(opacidades.every((o) => o.opacity == 1), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
