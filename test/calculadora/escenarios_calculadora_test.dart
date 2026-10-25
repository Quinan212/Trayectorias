import 'package:correlativas_historia/compartido/proveedores/estado_app.dart';
import 'package:correlativas_historia/datos/cargador_fuente_html.dart';
import 'package:correlativas_historia/funcionalidades/calculadora/panel/panel_evaluacion.dart';
import 'package:correlativas_historia/funcionalidades/calculadora/panel/panel_resultado.dart';
import 'package:correlativas_historia/funcionalidades/calculadora/pantalla/componentes/contenido_animado_calculadora.dart';
import 'package:correlativas_historia/funcionalidades/calculadora/pantalla/pantalla_calculadora.dart';
import 'package:correlativas_historia/funcionalidades/calculadora/pantalla/tema/estilos_calculadora.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart';
import 'package:correlativas_historia/modelos/materia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _previa = Materia(
  id: 'previa',
  codigo: '01',
  nombre: 'Historia y educación',
  anio: 1,
  tipo: 'Formación General',
  formato: 'Asignatura',
  correlativas: [],
  correlativasDetalladas: [],
);
final _materia = Materia(
  id: 'materia',
  codigo: '02',
  nombre: 'Práctica y reflexión pedagógica',
  anio: 2,
  tipo: 'Formación General',
  formato: 'Asignatura',
  correlativas: ['previa'],
  correlativasDetalladas: [CorrelativaDetallada(id: 'previa', type: 'A')],
);
final _plan = DatosPlan(materias: [_previa, _materia], pdfUrl: null);
final _carrera = kCareers.firstWhere((career) => !career.hidden);

void main() {
  for (final dark in [false, true]) {
    for (final legacy in [false, true]) {
      for (final bottom in [24.0, 48.0]) {
        testWidgets(
          '${legacy ? 'Calculadora' : 'Escenarios'}: último resultado fuera de la navegación, ${dark ? 'oscuro' : 'claro'}, $bottom',
          (tester) async {
            final container = await _montar(
              tester,
              dark: dark,
              legacy: legacy,
              bottom: bottom,
            );
            final scroll = _scrollPrincipal(legacy);
            await tester.drag(scroll, const Offset(0, -6000));
            await tester.pumpAndSettle();
            final result = find.byType(ContenidoAnimadoCalculadora).last;
            expect(
              tester.getBottomRight(result).dy,
              lessThanOrEqualTo(640 - bottom - 8),
            );
            expect(tester.takeException(), isNull);
            expect(
              container.read(proveedorIdMateriaCalculadoraSeleccionada),
              'materia',
            );
          },
        );
      }
    }
    testWidgets(
      'El resultado y las capacidades tienen contraste en ${dark ? 'oscuro' : 'claro'}',
      (tester) async {
        for (final label in [
          'Todavía no podés cursar',
          'Cursada condicionada',
          'Podés cursar',
        ]) {
          final res = EvalResult(
            canEnroll: true,
            overallLabel: label,
            activities: true,
            activitiesRestricted: label == 'Cursada condicionada',
            exams: true,
            examsRestricted: false,
            promotion: true,
            notes: [],
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: TemaCalculadora(
                builder: (context) => Scaffold(
                  body: Builder(
                    builder: (context) => PanelResultado.build(context, res),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final bodyContext = tester.element(find.text('Promoción'));
          final bg = Theme.of(bodyContext).colorScheme.surface;
          for (final text in find.byType(Text).evaluate()) {
            final widget = text.widget as Text;
            final fg = widget.style?.color;
            if (fg == null) continue;
            Color background = bg;
            final parents = <Widget>[];
            text.visitAncestorElements((element) {
              parents.add(element.widget);
              return true;
            });
            for (final parent in parents) {
              if (parent is AnimatedContainer &&
                  parent.decoration is BoxDecoration) {
                background = (parent.decoration as BoxDecoration).color ?? bg;
                break;
              }
            }
            expect(
              _contraste(fg, background),
              greaterThanOrEqualTo(4.5),
              reason: '${widget.data}: $fg / $background',
            );
          }
        }
      },
    );
  }

  testWidgets(
    'Cambiar una correlativa no superpone resultados y conserva la selección',
    (tester) async {
      final container = await _montar(tester, bottom: 48);
      await tester.scrollUntilVisible(
        find.text('aprobada'),
        250,
        scrollable: _scrollPrincipal(false),
      );
      await tester.pumpAndSettle();
      final before = tester.getSize(find.text('no\u00A0regularizada'));
      await tester.tap(find.text('aprobada'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        container.read(proveedorMapaEstadosCorrelativas)['previa'],
        'aprobada',
      );
      expect(
        find.textContaining('esta cursada todavía no aparece habilitada'),
        findsNothing,
      );
      expect(
        find.textContaining('esta cursada aparece habilitada.'),
        findsOneWidget,
      );
      expect(tester.getSize(find.text('no\u00A0regularizada')), before);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'La búsqueda de materia se adapta al teclado y permite seleccionar',
    (tester) async {
      await _montar(tester, bottom: 48, selected: false);
      await tester.scrollUntilVisible(
        find.text('Seleccionar materia'),
        100,
        scrollable: _scrollPrincipal(false),
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.text('Seleccionar materia')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccionar materia'));
      await tester.pumpAndSettle();
      final input = find.byType(TextField);
      expect(input, findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'reflexión');
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.text(_materia.nombre)).dy,
        lessThanOrEqualTo(640 - 290),
      );
      await tester.tap(find.text(_materia.nombre));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Carreras y años permiten scroll en pantalla compacta con texto grande',
    (tester) async {
      await _montar(tester, bottom: 48, selected: false, scale: 2);
      await tester.scrollUntilVisible(
        find.text(_carrera.nombre),
        150,
        scrollable: _scrollPrincipal(false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_carrera.nombre));
      await tester.pumpAndSettle();
      expect(find.text('Carrera de referencia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_carrera.nombre).last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('2° año'),
        150,
        scrollable: _scrollPrincipal(false),
      );
      await tester.tap(find.text('2° año'));
      await tester.pumpAndSettle();
      expect(find.text('4° año'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Movimiento reducido muestra el resultado nuevo desde el primer cuadro',
    (tester) async {
      final container = await _montar(tester, reduced: true);
      await tester.scrollUntilVisible(
        find.text('aprobada'),
        250,
        scrollable: _scrollPrincipal(false),
      );
      container
          .read(proveedorMapaEstadosCorrelativas.notifier)
          .setStatus('previa', 'aprobada');
      await tester.pump();
      expect(
        find.textContaining('esta cursada aparece habilitada.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tema local: Escenarios no cambia los colores de otra pantalla', (
    tester,
  ) async {
    final parent = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.pink,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: parent,
        home: Column(
          children: [
            const Text('Exterior'),
            TemaCalculadora(builder: (context) => const Text('Interior')),
          ],
        ),
      ),
    );
    expect(
      Theme.of(tester.element(find.text('Exterior'))).scaffoldBackgroundColor,
      Colors.pink,
    );
    expect(
      Theme.of(tester.element(find.text('Interior'))).scaffoldBackgroundColor,
      const Color(0xFFF5F7FA),
    );
  });

  testWidgets('Las tres opciones quedan completas en una pantalla angosta', (
    tester,
  ) async {
    await _montar(tester);
    await tester.scrollUntilVisible(
      find.text('aprobada'),
      200,
      scrollable: _scrollPrincipal(false),
    );
    await tester.pumpAndSettle();
    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(3));
    for (final element in chips.evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(344));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escritorio mantiene visible la evaluación sin desbordes', (
    tester,
  ) async {
    await _montar(tester, legacy: true, size: const Size(1400, 900));
    expect(find.byType(PanelEvaluacion), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _scrollPrincipal(bool legacy) => find
    .descendant(
      of: find.byType(
        legacy ? PantallaCalculadora : PantallaEscenariosAtlassian,
      ),
      matching: find.byType(Scrollable),
    )
    .first;

Future<ProviderContainer> _montar(
  WidgetTester tester, {
  bool dark = true,
  bool legacy = false,
  bool selected = true,
  bool reduced = false,
  double bottom = 24,
  double keyboard = 0,
  double scale = 1,
  Size size = const Size(360, 640),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final container = ProviderContainer(
    overrides: [
      proveedorPlan.overrideWith((ref) async => _plan),
      proveedorIdCarreraSeleccionada.overrideWith((ref) => _carrera.id),
      proveedorIdMateriaCalculadoraSeleccionada.overrideWith(
        (ref) => selected ? 'materia' : null,
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => Theme(
          data: temaLaboratorioAtlassian(context),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(
                top: 24,
                bottom:
                    keyboard == 0 &&
                        MediaQuery.viewInsetsOf(context).bottom == 0
                    ? bottom
                    : 0,
              ),
              viewPadding: EdgeInsets.only(top: 24, bottom: bottom),
              viewInsets: keyboard == 0
                  ? MediaQuery.viewInsetsOf(context)
                  : EdgeInsets.only(bottom: keyboard),
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
            ),
            child: child!,
          ),
        ),
        home: legacy
            ? const PantallaCalculadora()
            : const PantallaEscenariosAtlassian(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

double _contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}
