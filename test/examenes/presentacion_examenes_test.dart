import 'dart:async';

import 'package:correlativas_historia/compartido/tema/tema_herramientas_app.dart';
import 'package:correlativas_historia/funcionalidades/administrador/modelos/estado_dispositivo_administrador.dart';
import 'package:correlativas_historia/funcionalidades/administrador/proveedores/proveedores_acceso_administrador.dart';
import 'package:correlativas_historia/funcionalidades/examenes/datos/repositorio_examenes.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

EventoExamen _mesa({
  String materia = 'Educación y filosofía',
  String instancia = 'llamado_1',
  EstadoEventoExamen estado = EstadoEventoExamen.activa,
}) => EventoExamen(
  id: materia,
  careerId: 'historia',
  anio: 1,
  fecha: DateTime(2030, 10, 15),
  hora: '19:00',
  materia: materia,
  instancia: instancia,
  estado: estado,
  docentes: const ['María Núñez'],
  actaUrl: 'https://example.com/acta.pdf',
);

class _Repositorio extends RepositorioExamenes {
  List<EventoExamen> mesas = [
    _mesa(),
    _mesa(materia: 'Coloquio público', instancia: 'coloquio'),
  ];
  Completer<List<EventoExamen>>? pendiente;
  int cargas = 0;

  @override
  Stream<void> observarCambios() => const Stream.empty();

  @override
  Future<List<EventoExamen>> cargarTodos() async {
    cargas++;
    return pendiente?.future ?? mesas;
  }
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla,
  _Repositorio repo, {
  Brightness brightness = Brightness.light,
  double escala = 1,
  bool reducido = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorRepositorioExamenes.overrideWithValue(repo),
        proveedorEstadoDispositivoAdministrador.overrideWith(
          (ref) async => const EstadoDispositivoAdministrador(
            deviceId: 'prueba',
            isAdmin: false,
            message: '',
          ),
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
        home: pantalla,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

PantallaExamenesAtlassian _pantalla(
  ValueNotifier<SolicitudExamenesAtlassian?> solicitud,
) => PantallaExamenesAtlassian(onSearch: () {}, requestListenable: solicitud);

double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

Future<void> _centrar(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
        'listado $brightness escala $escala reserva navegación y búsqueda',
        (tester) async {
          final solicitud = ValueNotifier<SolicitudExamenesAtlassian?>(null);
          addTearDown(solicitud.dispose);
          await _montar(
            tester,
            _pantalla(solicitud),
            _Repositorio(),
            brightness: brightness,
            escala: escala,
          );
          expect(tester.takeException(), isNull);
          final scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(
            tester.getBottomRight(find.text('Coloquio público')).dy,
            lessThan(640 - 48 - 96),
          );
          expect(tester.takeException(), isNull);
          scroll.position.jumpTo(0);
          await tester.pumpAndSettle();
          await _centrar(tester, find.widgetWithText(ChoiceChip, 'Coloquios'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, 'Coloquios'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Educación y filosofía'), findsNothing);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _centrar(tester, find.widgetWithText(ChoiceChip, 'Llamados'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, 'Llamados'));
          await tester.pumpAndSettle();
          expect(find.text('Coloquio público'), findsNothing);
          await tester.pumpAndSettle();
          await _centrar(tester, find.text('Historia').first);
          await tester.tap(find.text('Historia').first);
          await tester.pumpAndSettle();
          await _centrar(tester, find.text('Educación Física'));
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final estado in EstadoEventoExamen.values) {
      testWidgets('detalle $brightness $estado: contraste y área segura', (
        tester,
      ) async {
        final mesa = _mesa(estado: estado);
        await _montar(
          tester,
          PantallaDetalleExamenAtlassian(event: mesa),
          _Repositorio()..mesas = [mesa],
          brightness: brightness,
          escala: 2,
        );
        expect(tester.takeException(), isNull);
        if (estado != EstadoEventoExamen.activa) {
          final textFinder = find.text(estado.etiqueta).first;
          final text = tester.widget<Text>(textFinder);
          final container = tester.widget<Container>(
            find
                .ancestor(of: textFinder, matching: find.byType(Container))
                .first,
          );
          final background = (container.decoration! as BoxDecoration).color!;
          expect(
            _contraste(text.style!.color!, background),
            greaterThanOrEqualTo(4.5),
          );
        }
        final button = find.text('Abrir acta');
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(button).dy, lessThan(640 - 48));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('skeleton inicial y actualización conservan los filtros', (
    tester,
  ) async {
    final repo = _Repositorio()..pendiente = Completer();
    final solicitud = ValueNotifier<SolicitudExamenesAtlassian?>(null);
    addTearDown(solicitud.dispose);
    await _montar(tester, _pantalla(solicitud), repo);
    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsOneWidget,
    );
    repo.pendiente!.complete(repo.mesas);
    repo.pendiente = null;
    await tester.pumpAndSettle();
    await _centrar(tester, find.widgetWithText(ChoiceChip, 'Coloquios'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Coloquios'));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    repo.pendiente = Completer();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pump();
    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsOneWidget,
    );
    repo.pendiente!.complete([
      _mesa(materia: 'Coloquio actualizado', instancia: 'coloquio'),
    ]);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Coloquios'))
          .selected,
      isTrue,
    );
    expect(find.text('Educación y filosofía'), findsNothing);
    expect(repo.cargas, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movimiento reducido y paleta permanecen locales', (
    tester,
  ) async {
    final solicitud = ValueNotifier<SolicitudExamenesAtlassian?>(null);
    addTearDown(solicitud.dispose);
    await _montar(
      tester,
      _pantalla(solicitud),
      _Repositorio(),
      brightness: Brightness.dark,
      reducido: true,
    );
    expect(
      Theme.of(tester.element(find.byType(MaterialApp))).brightness,
      Brightness.light,
    );
    final context = tester.element(find.text('Buscar y filtrar'));
    expect(Theme.of(context).scaffoldBackgroundColor, Colors.black);
    expect(
      Theme.of(context).colorScheme.surface,
      temaHerramientasApp(context).colorScheme.surface,
    );
    await _centrar(tester, find.widgetWithText(ChoiceChip, 'Coloquios'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Coloquios'));
    await tester.pump();
    expect(find.text('Educación y filosofía'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
