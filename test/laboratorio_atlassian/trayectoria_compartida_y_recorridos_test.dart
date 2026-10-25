import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:correlativas_historia/compartido/movimiento/movimiento_app.dart';
import 'package:correlativas_historia/compartido/navegacion/barra_busqueda_app.dart';
import 'package:correlativas_historia/datos/cargador_fuente_html.dart'
    as planes;
import 'package:correlativas_historia/funcionalidades/administrador/modelos/estado_dispositivo_administrador.dart';
import 'package:correlativas_historia/funcionalidades/administrador/proveedores/proveedores_acceso_administrador.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/datos/repositorio_examenes.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/componentes/componentes_academicos_app.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/componentes/trayectoria_activa_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_datos_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_disenos_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/utilidades_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:correlativas_historia/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _regular = MateriaTrayectoriaSageLaboratorio(
  idSage: 'unica-1',
  nombre: 'Materia Única',
  estadoOriginal: 'Regular',
  estado: EstadoMateriaSageLaboratorio.regular,
  anio: 2,
);
const _aprobada = MateriaTrayectoriaSageLaboratorio(
  idSage: 'unica-1',
  nombre: 'Materia Única',
  estadoOriginal: 'Aprobada',
  estado: EstadoMateriaSageLaboratorio.aprobada,
  anio: 2,
  nota: '9',
  fecha: '06/10/2026',
);

CarreraTrayectoriaSageLaboratorio _carrera(
  MateriaTrayectoriaSageLaboratorio materia,
) => CarreraTrayectoriaSageLaboratorio(
  gridRowId: 'hist-1',
  careerKey: 'historia',
  nombre: 'Profesorado de Historia',
  institucion: 'Instituto',
  materias: [materia],
);
TrayectoriaSageLaboratorio _trayectoria(
  MateriaTrayectoriaSageLaboratorio materia,
) => TrayectoriaSageLaboratorio(
  perfil: const PerfilTrayectoriaSageLaboratorio(nombre: 'Lucía Pérez'),
  carreras: [_carrera(materia)],
  capturadaEn: DateTime(2026, 10, 6),
);

class _RepositorioVacio extends RepositorioExamenes {
  int cargas = 0;
  @override
  Future<List<EventoExamen>> cargarTodos() async {
    cargas++;
    return [];
  }

  @override
  Stream<void> observarCambios() => const Stream<void>.empty();
}

class _RepositorioConEspera extends _RepositorioVacio {
  final peticiones = <Completer<List<EventoExamen>>>[];

  @override
  Future<List<EventoExamen>> cargarTodos() {
    final peticion = Completer<List<EventoExamen>>();
    peticiones.add(peticion);
    return peticion.future;
  }
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  ValueNotifier<TrayectoriaSageLaboratorio?>? trayectoria,
  ValueNotifier<int>? seleccion,
  _RepositorioVacio? repo,
  GlobalKey? captura,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorRepositorioExamenes.overrideWithValue(
          repo ?? _RepositorioVacio(),
        ),
        proveedorEstadoDispositivoAdministrador.overrideWith(
          (ref) async => const EstadoDispositivoAdministrador(
            deviceId: 'prueba',
            isAdmin: false,
            message: '',
          ),
        ),
        proveedorContenidosCurriculares.overrideWith(
          (ref) async => const <ContenidoCurricular>[],
        ),
      ],
      child: RepaintBoundary(
        key: captura,
        child: MaterialApp(
          theme: TemaApp.dark(),
          home: trayectoria == null
              ? pantalla
              : TrayectoriaActivaAtlassian(
                  trayectoria: trayectoria,
                  carreraSeleccionada: seleccion!,
                  cambios: Listenable.merge([trayectoria, seleccion]),
                  child: pantalla,
                ),
        ),
      ),
    ),
  );
  await _avanzar(tester);
}

// La entrada skeleton, la carga de planes y el cursor pueden seguir animados.
// Avanzamos los cuadros necesarios sin esperar a que esas tareas terminen.
Future<void> _avanzar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 2000));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    planes.limpiarCachePlanesParaPruebas();
    rootBundle.clear();
  });
  testWidgets('el botón sube como una sola barra y vuelve al mismo origen', (
    tester,
  ) async {
    final captura = GlobalKey();
    await tester.runAsync(() async {
      final datos = ByteData.sublistView(
        await File('assets/fonts/Inter_24pt-Regular.ttf').readAsBytes(),
      );
      for (final familia in ['inter', 'Inter_24pt-Regular']) {
        await (FontLoader(familia)..addFont(Future.value(datos))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    await _montar(
      tester,
      const PantallaLaboratorioAtlassian(hideExit: true),
      captura: captura,
    );
    final acceso = find.byKey(const ValueKey('inicio-react-liquid-search'));
    final origen = tester.getRect(acceso);
    await tester.tap(acceso);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final vuelo = find.byWidgetPredicate(
      (w) => w is BarraBusquedaApp && w.enVuelo,
    );
    expect(vuelo, findsOneWidget);
    final intermedio = tester.getRect(vuelo);
    expect(intermedio.top, lessThan(origen.top));
    expect(intermedio.height, closeTo(60, 0.1));
    await tester.runAsync(() async {
      final boundary =
          captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await boundary.toImage();
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/qa/buscador_barra_compartida_mitad.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      imagen.dispose();
    });
    await _avanzar(tester);
    expect(vuelo, findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    final campo = tester.getRect(
      find.byKey(const ValueKey('busqueda-react-liquid-field')),
    );
    expect(campo.top, lessThan(100));
    expect(intermedio.top, greaterThan(campo.top));
    await tester.runAsync(() async {
      final boundary =
          captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await boundary.toImage();
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/qa/buscador_barra_compartida_arriba.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      imagen.dispose();
    });
    await tester.enterText(find.byType(TextField), 'Educación Física');
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Educación Física',
    );
    final ruta = ModalRoute.of(
      tester.element(find.byType(PantallaBusquedaGlobalReactDeveloper)),
    )!;
    expect(ruta, isA<RutaBusquedaApp<void>>());
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(vuelo, findsOneWidget);
    expect(
      find.descendant(of: vuelo, matching: find.text('Educación Física')),
      findsOneWidget,
      reason: 'La vuelta conserva la búsqueda al iniciar el movimiento.',
    );
    await tester.pump(const Duration(milliseconds: 94));
    final regreso = tester.getRect(vuelo);
    expect(regreso.top, greaterThan(campo.top));
    expect(regreso.top, lessThan(origen.top));
    await tester.runAsync(() async {
      final boundary =
          captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await boundary.toImage();
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/qa/buscador_barra_regreso_mitad.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      imagen.dispose();
    });
    await _avanzar(tester);
    expect(find.byType(TextField), findsNothing);
    expect(tester.getRect(acceso), origen);
    expect(tester.takeException(), isNull);
  });

  for (final calendario in [true, false]) {
    testWidgets(
      '${calendario ? 'Calendario' : 'Exámenes'} conserva el skeleton al cargar y actualizar',
      (tester) async {
        final repo = _RepositorioConEspera();
        final captura = GlobalKey();
        final solicitud = ValueNotifier<SolicitudExamenesAtlassian?>(null);
        addTearDown(solicitud.dispose);
        await _montar(
          tester,
          calendario
              ? const PantallaCalendarioAtlassian(careerId: 'historia')
              : PantallaExamenesAtlassian(
                  onSearch: () {},
                  requestListenable: solicitud,
                ),
          repo: repo,
          captura: captura,
        );
        final skeleton = find.byWidgetPredicate(
          (w) => w is Skeletonizer && w.enabled,
        );
        expect(skeleton, findsOneWidget);
        expect(repo.peticiones, hasLength(1));
        repo.peticiones.first.complete([]);
        await _avanzar(tester);
        expect(skeleton, findsNothing);
        await tester.tap(find.byTooltip('Actualizar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(repo.peticiones, hasLength(2));
        expect(
          skeleton,
          findsOneWidget,
          reason:
              'Los datos anteriores no ocultan el skeleton de actualización.',
        );
        await tester.runAsync(() async {
          final boundary =
              captura.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final imagen = await boundary.toImage();
          final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/qa/skeleton_${calendario ? 'calendario' : 'examenes'}_actualizacion.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          imagen.dispose();
        });
        repo.peticiones.last.complete([]);
        await _avanzar(tester);
        expect(skeleton, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final react in [true, false]) {
    testWidgets(
      'la barra vuelve sin saltar al cerrar el teclado desde ${react ? 'Inicio' : 'Exámenes'}',
      (tester) async {
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetViewPadding);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewInsets);
        await _montar(
          tester,
          const PantallaLaboratorioAtlassian(hideExit: true),
        );
        if (!react) {
          tester
              .widget<PantallaInicioReactDeveloper>(
                find.byType(PantallaInicioReactDeveloper),
              )
              .onNavigate(1);
          await _avanzar(tester);
        }
        final acceso = find.byWidgetPredicate(
          (w) =>
              w is BarraBusquedaApp &&
              w.onTap != null &&
              (react
                  ? w.key == const ValueKey('inicio-react-liquid-search')
                  : w.key == null),
          skipOffstage: false,
        );
        final origen = tester.getRect(acceso);
        tester.widget<BarraBusquedaApp>(acceso).onTap!();
        await _avanzar(tester);
        await tester.enterText(find.byType(TextField), 'Educación Física');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        tester.view.padding = const FakeViewPadding(top: 24);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.getRect(acceso),
          origen,
          reason: 'El teclado de búsqueda no mueve la barra de origen.',
        );
        Navigator.of(tester.element(find.byType(TextField))).pop();
        await tester.pump();
        final vuelo = find.byWidgetPredicate(
          (w) => w is BarraBusquedaApp && w.enVuelo,
        );
        var ultimaPosicion = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is BarraBusquedaApp && w.controller != null,
          ),
        );
        for (var cuadro = 0; cuadro < 14; cuadro++) {
          tester.view.viewInsets = FakeViewPadding(
            bottom: 300 * (1 - (cuadro + 1) / 14),
          );
          if (cuadro == 13) {
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          }
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            find.descendant(
              of: find.byWidgetPredicate((w) => w is BarraBusquedaApp),
              matching: find.byType(Material),
            ),
            findsOneWidget,
            reason: 'La barra visible no se duplica durante la vuelta.',
          );
          expect(
            tester.getRect(acceso),
            origen,
            reason: 'Inicio y su barra no acompañan la animación de la ruta.',
          );
          final actual = vuelo.evaluate().isEmpty
              ? tester.getRect(acceso)
              : tester.getRect(vuelo);
          expect(actual.top, greaterThanOrEqualTo(ultimaPosicion.top - 0.1));
          expect(actual.bottom, lessThanOrEqualTo(origen.bottom + 0.1));
          expect(actual.height, closeTo(60, 0.1));
          ultimaPosicion = actual;
        }
        await _avanzar(tester);
        expect(tester.getRect(acceso), origen);
        expect(vuelo, findsNothing);
        expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
        expect(find.byType(PantallaBusquedaGlobalAtlassian), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('Educación Física y Música conservan su carrera en los recorridos', () {
    expect(
      idCarreraExamenAtlassian('Profesorado en Educación Física'),
      'fisica',
    );
    expect(idCarreraExamenAtlassian('Profesorado de Música'), 'musica');
    expect(idCarreraExamenAtlassian('Profesorado de Geografía'), 'geografia');
  });

  testWidgets(
    'detalle abierto renueva nota y fecha y deja de mostrar datos borrados',
    (tester) async {
      final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
        _trayectoria(_regular),
      );
      final seleccion = ValueNotifier<int>(0);
      addTearDown(trayectoria.dispose);
      addTearDown(seleccion.dispose);
      await _montar(
        tester,
        PantallaDetalleMateriaAtlassian(
          subject: _regular,
          career: _carrera(_regular),
        ),
        trayectoria: trayectoria,
        seleccion: seleccion,
      );
      expect(find.text('Nota'), findsNothing);
      trayectoria.value = _trayectoria(_aprobada);
      await _avanzar(tester);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('06/10/2026'), findsOneWidget);
      trayectoria.value = null;
      await _avanzar(tester);
      expect(find.text('Materia no disponible'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    },
  );

  testWidgets('Datos de carrera abierto renueva sus contadores', (
    tester,
  ) async {
    final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
      _trayectoria(_regular),
    );
    final seleccion = ValueNotifier<int>(0);
    addTearDown(trayectoria.dispose);
    addTearDown(seleccion.dispose);
    await _montar(
      tester,
      PantallaDetalleCarreraAtlassian(career: _carrera(_regular)),
      trayectoria: trayectoria,
      seleccion: seleccion,
    );
    trayectoria.value = _trayectoria(_aprobada);
    await _avanzar(tester);
    final fila = find
        .ancestor(
          of: find.text('Aprobadas'),
          matching: find.byType(FilaDatoAcademicoAtlassian),
        )
        .first;
    expect(find.descendant(of: fila, matching: find.text('1')), findsOneWidget);
    trayectoria.value = null;
    await _avanzar(tester);
    expect(find.text('Carrera no disponible'), findsOneWidget);
  });

  testWidgets(
    'Educación Física se identifica en el filtro público de exámenes',
    (tester) async {
      final solicitud = ValueNotifier<SolicitudExamenesAtlassian?>(
        const SolicitudExamenesAtlassian(careerId: 'fisica'),
      );
      addTearDown(solicitud.dispose);
      await _montar(
        tester,
        PantallaExamenesAtlassian(
          onSearch: () {},
          requestListenable: solicitud,
        ),
      );
      expect(find.text('Educación Física'), findsOneWidget);
      expect(find.text('Historia'), findsNothing);
    },
  );

  testWidgets(
    'verificación visual sin abrir ventanas: entrada y plan de Educación Física',
    (tester) async {
      final captura = GlobalKey();
      await tester.runAsync(() async {
        final datos = ByteData.sublistView(
          await File('assets/fonts/Inter_24pt-Regular.ttf').readAsBytes(),
        );
        for (final familia in ['inter', 'Inter_24pt-Regular']) {
          await (FontLoader(familia)..addFont(Future.value(datos))).load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        // La carga real del isolate se completa fuera del reloj virtual.
        await planes.cargarPlanDesdeHtml('assets/data/educacion_fisica.json');
      });
      await _montar(
        tester,
        const PantallaLaboratorioAtlassian(hideExit: true),
        captura: captura,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('inicio-react-liquid-search')),
      );
      await _avanzar(tester);
      final buscador = tester.widget<PantallaBusquedaGlobalReactDeveloper>(
        find.byType(PantallaBusquedaGlobalReactDeveloper),
      );
      final apertura = buscador.onOpenDestination(
        const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 2,
          careerId: 'fisica',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      await _avanzar(tester);
      await apertura;
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Educación Física'), findsWidgets);
      expect(
        find.image(const AssetImage('assets/career_icons/logo_iseef.png')),
        findsWidgets,
      );
      await tester.runAsync(() async {
        final boundary =
            captura.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final imagen = await boundary.toImage();
        final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
        final destino = File('build/qa/movimiento_plan_educacion_fisica.png');
        await destino.parent.create(recursive: true);
        await destino.writeAsBytes(png!.buffer.asUint8List());
        imagen.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );

  for (final avance in [true, false]) {
    testWidgets(
      '${avance ? 'Avance' : 'Próximos pasos'} sigue la trayectoria y carrera vigentes',
      (tester) async {
        final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
          _trayectoria(_regular),
        );
        final seleccion = ValueNotifier<int>(0);
        addTearDown(trayectoria.dispose);
        addTearDown(seleccion.dispose);
        await _montar(
          tester,
          avance
              ? PantallaAvanceAtlassian(career: _carrera(_regular))
              : PantallaProximosPasosAtlassian(career: _carrera(_regular)),
          trayectoria: trayectoria,
          seleccion: seleccion,
        );
        trayectoria.value = _trayectoria(_aprobada);
        await _avanzar(tester);
        expect(
          find.text(
            avance ? '1 de 1 materias aprobadas' : '0 materias regularizadas',
          ),
          findsOneWidget,
        );
        trayectoria.value = TrayectoriaSageLaboratorio(
          perfil: trayectoria.value!.perfil,
          carreras: [
            trayectoria.value!.carreras.first,
            const CarreraTrayectoriaSageLaboratorio(
              gridRowId: 'mus-1',
              careerKey: 'musica',
              nombre: 'Profesorado de Música',
              institucion: 'Instituto',
              materias: [],
            ),
          ],
          capturadaEn: DateTime(2026, 10, 6),
        );
        seleccion.value = 1;
        await _avanzar(tester);
        expect(find.text('Profesorado de Música'), findsOneWidget);
        trayectoria.value = null;
        await _avanzar(tester);
        expect(
          find.text(avance ? 'Sin datos de avance' : 'Sin trayectoria'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('calendario abierto recibe las nuevas aprobaciones de SAGE', (
    tester,
  ) async {
    final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
      _trayectoria(_regular),
    );
    final seleccion = ValueNotifier<int>(0);
    addTearDown(trayectoria.dispose);
    addTearDown(seleccion.dispose);
    await _montar(
      tester,
      PantallaCalendarioAtlassian(
        careerId: 'historia',
        initialDate: DateTime(2026, 10, 6),
        trayectoria: trayectoria.value,
      ),
      trayectoria: trayectoria,
      seleccion: seleccion,
    );
    trayectoria.value = _trayectoria(_aprobada);
    await _avanzar(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await _avanzar(tester);
    expect(find.text('Materia Única'), findsWidgets);
    trayectoria.value = null;
    await _avanzar(tester);
    expect(find.text('Materia Única'), findsNothing);
  });

  for (final react in [false, true]) {
    testWidgets(
      'buscador ${react ? 'React' : 'Atlassian'} actualiza la misma consulta después de SAGE',
      (tester) async {
        final trayectoria = ValueNotifier<TrayectoriaSageLaboratorio?>(
          _trayectoria(_regular),
        );
        final seleccion = ValueNotifier<int>(0);
        addTearDown(trayectoria.dispose);
        addTearDown(seleccion.dispose);
        DestinoBusquedaAtlassian? destino;
        Future<void> abrir(DestinoBusquedaAtlassian valor) async {
          destino = valor;
        }

        await _montar(
          tester,
          react
              ? PantallaBusquedaGlobalReactDeveloper(
                  trajectoryListenable: trayectoria,
                  selectedCareerListenable: seleccion,
                  onOpenDestination: abrir,
                )
              : PantallaBusquedaGlobalAtlassian(
                  trajectoryListenable: trayectoria,
                  selectedCareerListenable: seleccion,
                  onOpenDestination: abrir,
                ),
        );
        await tester.enterText(find.byType(TextField), 'Materia Única');
        await _avanzar(tester);
        trayectoria.value = _trayectoria(_aprobada);
        await _avanzar(tester);
        await tester.tap(find.text(react ? 'aprobada' : 'Aprobada').last);
        await tester.pump();
        expect(destino?.materiaTrayectoria?.nota, '9');
        expect(destino?.materiaTrayectoria?.fecha, '06/10/2026');
      },
    );
  }

  testWidgets(
    'buscar prepara el destino antes de salir y evita aperturas duplicadas',
    (tester) async {
      final repo = _RepositorioVacio();
      await _montar(
        tester,
        const PantallaLaboratorioAtlassian(hideExit: true),
        repo: repo,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('inicio-react-liquid-search')),
      );
      await _avanzar(tester);
      final buscador = tester.widget<PantallaBusquedaGlobalReactDeveloper>(
        find.byType(PantallaBusquedaGlobalReactDeveloper),
      );
      const destino = DestinoBusquedaAtlassian(
        tipo: TipoDestinoBusquedaAtlassian.seccion,
        seccion: 1,
      );
      final apertura = buscador.onOpenDestination(destino);
      final duplicado = buscador.onOpenDestination(destino);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(
        find.byType(PantallaExamenesAtlassian, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsOneWidget);
      await _avanzar(tester);
      await apertura;
      await duplicado;
      expect(find.byType(PantallaExamenesAtlassian), findsOneWidget);
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
      expect(repo.cargas, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final caso in [
    (0, 1, 'exámenes', PantallaExamenesAtlassian),
    (0, 2, 'plan completo', PantallaPlanAtlassian),
    (0, 3, 'mis materias', PantallaMateriasAtlassian),
    (1, 3, 'mis materias', PantallaMateriasAtlassian),
    (0, 4, 'datos', PantallaDatosAtlassian),
  ]) {
    testWidgets(
      'Volver desde ${caso.$3} regresa al menú y después al origen ${caso.$1}',
      (tester) async {
        await _montar(
          tester,
          const PantallaLaboratorioAtlassian(hideExit: true),
        );
        final inicio = tester.widget<PantallaInicioReactDeveloper>(
          find.byType(PantallaInicioReactDeveloper),
        );
        inicio.onNavigate(caso.$1);
        await _avanzar(tester);
        final barra = find.byWidgetPredicate(
          (widget) => widget is BarraBusquedaApp && widget.onTap != null,
        );
        final posicion = tester.getRect(barra);
        await tester.tap(barra);
        await _avanzar(tester);
        await tester.tap(find.text(caso.$3));
        await _avanzar(tester);
        expect(find.byType(caso.$4), findsOneWidget);
        expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await _avanzar(tester);
        expect(
          find.byType(PantallaBusquedaGlobalReactDeveloper),
          findsOneWidget,
        );
        expect(find.byType(PantallaBusquedaGlobalAtlassian), findsNothing);
        await tester.tap(find.byKey(const ValueKey('busqueda-react-back')));
        await _avanzar(tester);
        expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
        expect(
          find.byType(
            caso.$1 == 0
                ? PantallaInicioReactDeveloper
                : PantallaExamenesAtlassian,
          ),
          findsOneWidget,
        );
        expect(tester.getRect(barra), posicion);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final caso in [
    (
      'Calendario',
      TipoDestinoBusquedaAtlassian.calendario,
      PantallaCalendarioAtlassian,
    ),
    ('Diseños', TipoDestinoBusquedaAtlassian.disenos, PantallaDisenosAtlassian),
    (
      'Escenarios',
      TipoDestinoBusquedaAtlassian.escenarios,
      PantallaEscenariosInicializadosAtlassian,
    ),
    ('Ayuda', TipoDestinoBusquedaAtlassian.ayuda, PantallaAyudaAtlassian),
    (
      'Próximos pasos',
      TipoDestinoBusquedaAtlassian.proximosPasos,
      PantallaProximosPasosAtlassian,
    ),
    ('Avance', TipoDestinoBusquedaAtlassian.avance, PantallaAvanceAtlassian),
  ]) {
    for (final sistema in [false, true]) {
      testWidgets(
        '${caso.$1}: Volver ${sistema ? 'de Android' : 'de la cabecera'} regresa al menú sin pintar Inicio',
        (tester) async {
          await _montar(
            tester,
            const PantallaLaboratorioAtlassian(hideExit: true),
          );
          await tester.tap(
            find.byKey(const ValueKey('inicio-react-liquid-search')),
          );
          await _avanzar(tester);
          final apertura = tester
              .widget<PantallaBusquedaGlobalReactDeveloper>(
                find.byType(PantallaBusquedaGlobalReactDeveloper),
              )
              .onOpenDestination(DestinoBusquedaAtlassian(tipo: caso.$2));
          for (var frame = 0; frame < 45; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          await apertura;
          expect(find.byType(caso.$3), findsOneWidget);
          final ruta = ModalRoute.of(tester.element(find.byType(caso.$3)))!;
          if (sistema) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
          }
          await tester.pump();
          for (var frame = 0; frame < 20; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            expect(
              find.byType(PantallaBusquedaGlobalReactDeveloper),
              findsOneWidget,
              reason: 'El menú debe abrirse en el cuadro $frame.',
            );
            expect(
              find.byType(PantallaInicioReactDeveloper).hitTestable(),
              findsNothing,
              reason:
                  'Inicio queda cubierto durante el cuadro $frame desde ${caso.$1}.',
            );
            expect(tester.takeException(), isNull);
          }
          await _avanzar(tester);
          expect(
            find.byType(PantallaBusquedaGlobalReactDeveloper),
            findsOneWidget,
          );
          expect(ruta.isActive, isFalse);
          await tester.tap(find.byKey(const ValueKey('busqueda-react-back')));
          await _avanzar(tester);
          expect(find.byType(PantallaInicioReactDeveloper), findsOneWidget);
          expect(find.byType(caso.$3), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Materias abierta directamente conserva el regreso a Inicio', (
    tester,
  ) async {
    await _montar(tester, const PantallaLaboratorioAtlassian(hideExit: true));
    tester
        .widget<PantallaInicioReactDeveloper>(
          find.byType(PantallaInicioReactDeveloper),
        )
        .onNavigate(3);
    await _avanzar(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await _avanzar(tester);
    expect(find.byType(PantallaInicioReactDeveloper), findsOneWidget);
    expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barra inferior permanece fija mientras cambian las secciones', (
    tester,
  ) async {
    await _montar(tester, const PantallaLaboratorioAtlassian(hideExit: true));
    final inicio = tester.widget<PantallaInicioReactDeveloper>(
      find.byType(PantallaInicioReactDeveloper),
    );
    final barra = find.byWidgetPredicate(
      (widget) => widget is BarraBusquedaApp && widget.onTap != null,
    );
    final posicion = tester.getRect(barra);
    for (final seccion in [1, 2, 4, 3, 0]) {
      inicio.onNavigate(seccion);
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(barra, findsOneWidget);
        expect(
          tester.getRect(barra),
          posicion,
          reason:
              'La barra no sigue el movimiento del contenido de la sección $seccion.',
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  for (final seccion in [0, 1, 2, 3, 4]) {
    testWidgets('la barra de la sección $seccion abre el buscador actual', (
      tester,
    ) async {
      await _montar(tester, const PantallaLaboratorioAtlassian(hideExit: true));
      tester
          .widget<PantallaInicioReactDeveloper>(
            find.byType(PantallaInicioReactDeveloper),
          )
          .onNavigate(seccion);
      await _avanzar(tester);
      final acceso = find.byWidgetPredicate(
        (widget) => widget is BarraBusquedaApp && widget.onTap != null,
      );
      expect(acceso, findsOneWidget);
      await tester.tap(acceso);
      await _avanzar(tester);
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsOneWidget);
      expect(find.byType(PantallaBusquedaGlobalAtlassian), findsNothing);
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await _avanzar(tester);
      expect(
        find.descendant(of: acceso, matching: find.byType(Material)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final react in [true, false]) {
    for (final caso in [
      (
        'Exámenes',
        const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 1,
          careerId: 'fisica',
        ),
        PantallaExamenesAtlassian,
      ),
      (
        'Plan',
        const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 2,
          careerId: 'fisica',
        ),
        PantallaPlanAtlassian,
      ),
      (
        'Calendario',
        DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.calendario,
          careerId: 'fisica',
          fecha: DateTime(2026, 10, 7),
        ),
        PantallaCalendarioAtlassian,
      ),
      (
        'Ayuda',
        const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.ayuda,
        ),
        PantallaAyudaAtlassian,
      ),
    ]) {
      testWidgets(
        'búsqueda desde ${react ? 'Inicio' : 'Exámenes'} → ${caso.$1} no pinta Inicio al salir',
        (tester) async {
          final captura = GlobalKey();
          await _montar(
            tester,
            const PantallaLaboratorioAtlassian(hideExit: true),
            captura: captura,
          );
          final inicio = tester.widget<PantallaInicioReactDeveloper>(
            find.byType(PantallaInicioReactDeveloper),
          );
          if (react) {
            inicio.onSearch();
          } else {
            inicio.onNavigate(1);
            await _avanzar(tester);
            tester
                .widget<PantallaExamenesAtlassian>(
                  find.byType(PantallaExamenesAtlassian),
                )
                .onSearch();
          }
          await _avanzar(tester);
          final buscador = find.byType(PantallaBusquedaGlobalReactDeveloper);
          expect(find.byType(PantallaBusquedaGlobalAtlassian), findsNothing);
          final ruta = ModalRoute.of(tester.element(buscador))!;
          final apertura = tester
              .widget<PantallaBusquedaGlobalReactDeveloper>(buscador)
              .onOpenDestination(caso.$2);
          var cuadrosDeSalida = 0;
          for (var cuadro = 0; cuadro < 40; cuadro++) {
            await tester.pump(const Duration(milliseconds: 16));
            if (ruta.animation!.status != AnimationStatus.reverse ||
                ruta.animation!.value == 1) {
              continue;
            }
            cuadrosDeSalida++;
            expect(
              find.byType(PantallaInicioReactDeveloper),
              findsNothing,
              reason: 'Inicio no debe pintarse en el cuadro $cuadro',
            );
            expect(find.byType(caso.$3), findsOneWidget);
            if (react && caso.$1 == 'Calendario' && cuadrosDeSalida == 8) {
              await tester.runAsync(() async {
                final boundary =
                    captura.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final imagen = await boundary.toImage();
                final png = await imagen.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final destino = File(
                  'build/qa/transicion_calendario_sin_inicio.png',
                );
                await destino.parent.create(recursive: true);
                await destino.writeAsBytes(png!.buffer.asUint8List());
                imagen.dispose();
              });
            }
          }
          await apertura;
          expect(cuadrosDeSalida, greaterThan(5));
          expect(buscador, findsNothing);
          expect(find.byType(caso.$3), findsOneWidget);
          if (caso.$2.tipo != TipoDestinoBusquedaAtlassian.seccion) {
            final destino = tester.element(find.byType(caso.$3));
            final rutaDestino = ModalRoute.of(destino)!;
            expect(rutaDestino.transitionDuration, Duration.zero);
            expect(rutaDestino.reverseTransitionDuration, MovimientoApp.salida);
            Navigator.of(destino).pop();
            await _avanzar(tester);
            expect(find.byType(PantallaInicioReactDeveloper), findsOneWidget);
            expect(find.byType(caso.$3), findsNothing);
          }
          inicio.onNavigate(0);
          await _avanzar(tester);
          final accesoInicio = find.byKey(
            const ValueKey('inicio-react-liquid-search'),
          );
          expect(
            find.descendant(of: accesoInicio, matching: find.byType(Material)),
            findsOneWidget,
            reason: 'La barra debe pintarse al volver desde ${caso.$1}.',
          );
          expect(tester.getRect(accesoInicio).height, closeTo(60, 0.1));
          await tester.tap(accesoInicio);
          await _avanzar(tester);
          expect(
            find.byType(PantallaBusquedaGlobalReactDeveloper),
            findsOneWidget,
          );
          Navigator.of(tester.element(find.byType(TextField))).pop();
          await _avanzar(tester);
          expect(
            find.descendant(of: accesoInicio, matching: find.byType(Material)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'toques repetidos abren una sola búsqueda incluso durante la salida',
    (tester) async {
      await _montar(tester, const PantallaLaboratorioAtlassian(hideExit: true));
      final inicio = tester.widget<PantallaInicioReactDeveloper>(
        find.byType(PantallaInicioReactDeveloper),
      );
      inicio.onSearch();
      inicio.onSearch();
      await _avanzar(tester);
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsOneWidget);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pump();
      inicio.onSearch();
      await _avanzar(tester);
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsNothing);
      inicio.onSearch();
      await _avanzar(tester);
      expect(find.byType(PantallaBusquedaGlobalReactDeveloper), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
