import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/componentes/componentes_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MateriaTrayectoriaSageLaboratorio _materia({
  String nombre = 'Educación y filosofía',
  EstadoMateriaSageLaboratorio estado = EstadoMateriaSageLaboratorio.aprobada,
  int anio = 1,
}) => MateriaTrayectoriaSageLaboratorio(
  idSage: nombre,
  nombre: nombre,
  estadoOriginal: estado.etiqueta,
  estado: estado,
  anio: anio,
  nota: '9',
  fecha: '14/07/2026',
);

CarreraTrayectoriaSageLaboratorio _carrera({
  String id = 'historia',
  List<MateriaTrayectoriaSageLaboratorio>? materias,
}) => CarreraTrayectoriaSageLaboratorio(
  gridRowId: id,
  careerKey: id,
  nombre: 'Profesorado de Historia',
  institucion: 'Instituto',
  materias:
      materias ??
      [
        _materia(),
        _materia(
          nombre: 'Práctica docente',
          estado: EstadoMateriaSageLaboratorio.regular,
        ),
        _materia(nombre: 'Didáctica general', anio: 2),
      ],
);

class _Datos {
  final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
  final cargado = ValueNotifier(true);
  final carrera = ValueNotifier(0);
  final solicitud = ValueNotifier<SolicitudMateriasAtlassian?>(null);

  _Datos({int carreras = 1}) {
    trayectoria.value = TrayectoriaSageLaboratorio(
      perfil: const PerfilTrayectoriaSageLaboratorio(nombre: 'Prueba'),
      carreras: [for (var i = 0; i < carreras; i++) _carrera(id: 'carrera-$i')],
      capturadaEn: DateTime(2026, 10, 7),
    );
  }

  Widget pantalla() => PantallaMateriasAtlassian(
    trajectoryListenable: trayectoria,
    localLoadedListenable: cargado,
    selectedCareerListenable: carrera,
    requestListenable: solicitud,
  );

  void dispose() {
    trayectoria.dispose();
    cargado.dispose();
    carrera.dispose();
    solicitud.dispose();
  }
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  Brightness brightness = Brightness.light,
  double escala = 1,
  bool reducido = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
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
  );
  await tester.pumpAndSettle();
}

Future<void> _centrar(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _final(WidgetTester tester) async {
  final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
  scroll.position.jumpTo(scroll.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
        'listado $brightness escala $escala deja libres navegación y buscador',
        (tester) async {
          final datos = _Datos();
          addTearDown(datos.dispose);
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          await _montar(
            tester,
            datos.pantalla(),
            brightness: brightness,
            escala: escala,
          );
          expect(tester.takeException(), isNull);
          await _final(tester);
          expect(
            tester.getBottomRight(find.text('Didáctica general')).dy,
            lessThan(640 - 48 - 96),
          );
          expect(find.text('Nota 9'), findsWidgets);
          expect(find.text('14/07/2026'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final estado in EstadoMateriaSageLaboratorio.values) {
      testWidgets(
        'detalle $brightness $estado mantiene datos y contraste con texto grande',
        (tester) async {
          final materia = _materia(estado: estado);
          final carrera = _carrera(
            materias: [
              materia,
              _materia(
                nombre: 'Historia de la educación',
                estado: EstadoMateriaSageLaboratorio.noRegularizada,
              ),
              _materia(
                nombre: 'Pedagogía',
                estado: EstadoMateriaSageLaboratorio.regular,
              ),
            ],
          );
          await _montar(
            tester,
            PantallaDetalleMateriaAtlassian(subject: materia, career: carrera),
            brightness: brightness,
            escala: 2,
          );
          expect(tester.takeException(), isNull);
          final texto = find.text(estado.etiqueta).first;
          final widget = tester.widget<Text>(texto);
          final container = tester.widget<Container>(
            find.ancestor(of: texto, matching: find.byType(Container)).first,
          );
          expect(
            _contraste(
              widget.style!.color!,
              (container.decoration! as BoxDecoration).color!,
            ),
            greaterThanOrEqualTo(4.5),
          );
          await _centrar(tester, find.text('Nota'));
          expect(find.text('9'), findsOneWidget);
          await _centrar(tester, find.text('Fecha'));
          expect(find.text('14/07/2026'), findsOneWidget);
          await _final(tester);
          expect(
            tester.getBottomRight(find.text('Pedagogía')).dy,
            lessThan(640 - 48),
          );
          expect(
            tester.getTopLeft(find.text('Historia de la educación')).dx,
            tester.getTopLeft(find.text('Pedagogía')).dx,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'filtros por estado y año reemplazan las filas sin superponer resultados',
    (tester) async {
      final datos = _Datos();
      addTearDown(datos.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await _montar(tester, datos.pantalla(), escala: 2);
      await _centrar(tester, find.byType(SelectorAtlassian).first);
      await tester.tap(find.byType(SelectorAtlassian).first);
      await tester.pumpAndSettle();
      await _centrar(tester, find.text('Regular').last);
      await tester.tap(find.text('Regular').last);
      await tester.pumpAndSettle();
      await _final(tester);
      expect(find.text('Práctica docente'), findsOneWidget);
      expect(find.text('Educación y filosofía'), findsNothing);
      expect(find.text('Didáctica general'), findsNothing);
      expect(tester.takeException(), isNull);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await _centrar(tester, find.byType(SelectorAtlassian).last);
      await tester.tap(find.byType(SelectorAtlassian).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2° año').last);
      await tester.pumpAndSettle();
      await _final(tester);
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(tester.takeException(), isNull);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await _centrar(tester, find.text('Limpiar (2)'));
      await tester.tap(find.text('Limpiar (2)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sin resultados'), findsNothing);
      await tester.pumpAndSettle();
      await _final(tester);
      expect(find.text('Didáctica general'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'volver a seleccionar la carrera actual conserva búsqueda y filtros',
    (tester) async {
      final datos = _Datos(carreras: 12);
      datos.solicitud.value = const SolicitudMateriasAtlassian(
        query: 'filosofia',
        year: 1,
        status: EstadoMateriaSageLaboratorio.aprobada,
      );
      addTearDown(datos.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await _montar(tester, datos.pantalla(), escala: 2);
      await tester.tap(find.byTooltip('Cambiar carrera'));
      await tester.pumpAndSettle();
      final carreras = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Profesorado de Historia'),
      );
      final primera = carreras.first;
      // Las doce carreras comparten nombre; elegimos el primer panel del selector.
      final panel = find.byType(PanelAtlassian).last;
      expect(primera, findsOneWidget);
      await _centrar(tester, panel);
      expect(tester.takeException(), isNull);
      final hojaScroll = tester.state<ScrollableState>(
        find.byType(Scrollable).last,
      );
      hojaScroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(primera);
      await tester.pumpAndSettle();
      expect(datos.carrera.value, 0);
      expect(find.text('Limpiar (3)'), findsOneWidget);
      await _final(tester);
      expect(find.text('Educación y filosofía'), findsOneWidget);
      expect(find.text('Práctica docente'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'solicitud externa respeta tildes, filtros y movimiento reducido',
    (tester) async {
      final datos = _Datos();
      addTearDown(datos.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await _montar(
        tester,
        datos.pantalla(),
        brightness: Brightness.dark,
        reducido: true,
      );
      final context = tester.element(find.text('Buscar y filtrar'));
      expect(Theme.of(context).scaffoldBackgroundColor, Colors.black);
      datos.solicitud.value = const SolicitudMateriasAtlassian(
        query: 'filosofia',
        year: 1,
        status: EstadoMateriaSageLaboratorio.aprobada,
      );
      await tester.pump();
      await _final(tester);
      expect(find.text('Educación y filosofía'), findsOneWidget);
      expect(find.text('Práctica docente'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
