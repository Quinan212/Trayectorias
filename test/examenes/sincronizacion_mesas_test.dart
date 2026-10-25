import 'dart:async';

import 'package:correlativas_historia/funcionalidades/administrador/modelos/estado_dispositivo_administrador.dart';
import 'package:correlativas_historia/funcionalidades/administrador/proveedores/proveedores_acceso_administrador.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/datos/repositorio_examenes.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/modelos_busqueda_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

EventoExamen _mesa({String docente = 'Lucía Pérez'}) => EventoExamen(
  id: 'mesa-compartida',
  careerId: 'historia',
  anio: 1,
  fecha: DateTime(2026, 10, 15),
  hora: '19:00',
  materia: 'Prueba de sincronización',
  instancia: 'llamado_1',
  docentes: [docente],
  actaUrl: null,
);

class _RepositorioRemotoSimulado extends RepositorioExamenes {
  final cambios = StreamController<void>.broadcast();
  List<EventoExamen> mesas = [_mesa()];
  int cargas = 0;
  int escuchas = 0;
  bool errorDeConexion = false;

  @override
  Stream<void> observarCambios() {
    escuchas++;
    return cambios.stream;
  }

  @override
  Future<List<EventoExamen>> cargarTodos() async {
    cargas++;
    return List<EventoExamen>.unmodifiable(mesas);
  }

  @override
  Future<EventoExamen?> loadById(String id) async {
    if (errorDeConexion) throw TimeoutException('Sin conexión');
    return mesas.where((mesa) => mesa.id == id).firstOrNull;
  }
}

Future<ProviderContainer> _montar(
  WidgetTester tester,
  _RepositorioRemotoSimulado repo,
  Widget pantalla,
) async {
  tester.view.physicalSize = const Size(430, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await repo.cambios.close();
  });
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
        proveedorContenidosCurriculares.overrideWith(
          (ref) async => const <ContenidoCurricular>[],
        ),
      ],
      child: MaterialApp(home: pantalla),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Future<void> _recibirCambio(
  WidgetTester tester,
  _RepositorioRemotoSimulado repo,
) async {
  repo.cambios.add(null);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('el listado recibe cambios sin volver a entrar', (tester) async {
    final repo = _RepositorioRemotoSimulado();
    final request = ValueNotifier<SolicitudExamenesAtlassian?>(null);
    addTearDown(request.dispose);
    await _montar(
      tester,
      repo,
      PantallaExamenesAtlassian(onSearch: () {}, requestListenable: request),
    );
    expect(find.text('Prueba de sincronización'), findsOneWidget);
    repo.mesas = [_mesa().copyWith(materia: 'Nueva mesa pública')];
    await _recibirCambio(tester, repo);
    expect(find.text('Nueva mesa pública'), findsOneWidget);
    expect(find.text('Prueba de sincronización'), findsNothing);
    expect(repo.escuchas, 1);
    repo.mesas = [];
    await _recibirCambio(tester, repo);
    expect(find.text('Nueva mesa pública'), findsNothing);
  });

  testWidgets('el calendario mueve una mesa al día reprogramado', (
    tester,
  ) async {
    final repo = _RepositorioRemotoSimulado();
    await _montar(
      tester,
      repo,
      PantallaCalendarioAtlassian(
        careerId: 'historia',
        initialDate: DateTime(2026, 10, 15),
      ),
    );
    expect(find.text('Día libre'), findsNothing);
    repo.mesas = [
      _mesa().copyWith(
        estado: EstadoEventoExamen.reprogramada,
        fechaReprogramada: DateTime(2026, 10, 17),
        horaReprogramada: '20:30',
      ),
    ];
    await _recibirCambio(tester, repo);
    expect(find.text('Día libre'), findsOneWidget);
    await tester.tap(find.text('17').first);
    await tester.pump();
    expect(find.text('Día libre'), findsNothing);
    expect(find.textContaining('20:30'), findsWidgets);
    expect(repo.escuchas, 1);
  });

  testWidgets('el detalle recibe docentes y tolera un error de conexión', (
    tester,
  ) async {
    final repo = _RepositorioRemotoSimulado();
    await _montar(tester, repo, PantallaDetalleExamenAtlassian(event: _mesa()));
    expect(find.text('Lucía Pérez'), findsOneWidget);
    repo.mesas = [_mesa(docente: 'María Núñez')];
    await _recibirCambio(tester, repo);
    expect(find.text('María Núñez'), findsOneWidget);
    expect(find.text('Lucía Pérez'), findsNothing);
    repo.errorDeConexion = true;
    repo.mesas = [];
    await _recibirCambio(tester, repo);
    expect(find.byType(PantallaDetalleExamenAtlassian), findsOneWidget);
    expect(find.text('María Núñez'), findsOneWidget);
    expect(find.text('La mesa ya no está disponible.'), findsNothing);
  });

  for (final react in [false, true]) {
    testWidgets('el buscador ${react ? 'React' : 'Atlassian'} renueva una '
        'búsqueda abierta aunque solo cambien docentes o acta', (tester) async {
      final repo = _RepositorioRemotoSimulado();
      final trajectory = ValueNotifier<TrayectoriaSageLaboratorio?>(null);
      final career = ValueNotifier<int>(0);
      addTearDown(trajectory.dispose);
      addTearDown(career.dispose);
      DestinoBusquedaAtlassian? opened;
      Future<void> open(DestinoBusquedaAtlassian destination) async {
        opened = destination;
      }

      await _montar(
        tester,
        repo,
        react
            ? PantallaBusquedaGlobalReactDeveloper(
                trajectoryListenable: trajectory,
                selectedCareerListenable: career,
                onOpenDestination: open,
              )
            : PantallaBusquedaGlobalAtlassian(
                trajectoryListenable: trajectory,
                selectedCareerListenable: career,
                onOpenDestination: open,
              ),
      );
      // La primera entrada del menú mantiene su skeleton de presentación.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField), 'prueba sincronizacion');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Prueba de sincronización'), findsWidgets);
      repo.mesas = [
        _mesa(docente: 'María Núñez').copyWith(
          actaUrl: 'https://example.org/acta-nueva',
          estado: EstadoEventoExamen.suspendida,
        ),
      ];
      await _recibirCambio(tester, repo);
      // El resultado y su destino deben usar la mesa nueva, con la misma consulta.
      final result = find.text(react ? 'abrir mesa' : 'Abrir mesa').first;
      await Scrollable.ensureVisible(tester.element(result), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(result);
      await tester.pump();
      expect(opened?.evento?.docentes, ['María Núñez']);
      expect(opened?.evento?.actaUrl, 'https://example.org/acta-nueva');
      expect(opened?.evento?.estado, EstadoEventoExamen.suspendida);
      expect(repo.escuchas, 1);
      repo.mesas = [];
      await _recibirCambio(tester, repo);
      expect(find.text('Prueba de sincronización'), findsNothing);
    });
  }

  testWidgets('volver a la app recupera cambios y agrupa avisos remotos', (
    tester,
  ) async {
    final repo = _RepositorioRemotoSimulado();
    final request = ValueNotifier<SolicitudExamenesAtlassian?>(null);
    addTearDown(request.dispose);
    final container = await _montar(
      tester,
      repo,
      PantallaExamenesAtlassian(onSearch: () {}, requestListenable: request),
    );
    final cargasIniciales = repo.cargas;
    repo.mesas = [_mesa().copyWith(materia: 'Mesa actualizada al regresar')];
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    repo.cambios.add(null);
    repo.cambios.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    await tester.pump();
    expect(find.text('Mesa actualizada al regresar'), findsOneWidget);
    expect(repo.cargas, cargasIniciales + 1);
    expect(
      container.read(proveedorTodosLosExamenes).value?.single.materia,
      'Mesa actualizada al regresar',
    );
    expect(repo.escuchas, 1);
  });

  testWidgets(
    'dos vistas abiertas comparten descarga, suscripción y refresco',
    (tester) async {
      final repo = _RepositorioRemotoSimulado();
      final request = ValueNotifier<SolicitudExamenesAtlassian?>(null);
      addTearDown(request.dispose);
      final container = await _montar(
        tester,
        repo,
        IndexedStack(
          children: [
            PantallaExamenesAtlassian(
              onSearch: () {},
              requestListenable: request,
            ),
            PantallaCalendarioAtlassian(
              careerId: 'historia',
              initialDate: DateTime(2026, 10, 15),
            ),
          ],
        ),
      );
      expect(repo.cargas, 1);
      expect(repo.escuchas, 1);
      expect(
        find.text('Prueba de sincronización', skipOffstage: false),
        findsAtLeastNWidgets(2),
      );
      repo.mesas = [_mesa().copyWith(materia: 'Mesa compartida actualizada')];
      await tester.tap(find.byTooltip('Actualizar').first);
      await tester.pump();
      await tester.pump();
      expect(repo.cargas, 2);
      expect(
        find.text('Mesa compartida actualizada', skipOffstage: false),
        findsAtLeastNWidgets(2),
      );
      expect(
        container.read(proveedorTodosLosExamenes).value?.single.materia,
        'Mesa compartida actualizada',
      );
    },
  );
}
