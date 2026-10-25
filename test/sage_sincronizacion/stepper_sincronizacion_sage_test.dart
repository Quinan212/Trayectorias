import 'dart:io';
import 'dart:ui' as ui;

import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/modelos_sincronizacion_sage_automatica.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sincronizacion_sage_automatica.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conserva la contraseña hasta que SAGE acepta la sesión', (
    tester,
  ) async {
    const login = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.credenciales,
      titulo: 'Conectar con SAGE',
      paso: PasoSincronizacionSageAutomatica.sesion,
    );
    final estado = ValueNotifier(login);
    addTearDown(estado.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<EstadoSincronizacionSageAutomatica>(
          valueListenable: estado,
          builder: (context, actual, _) => PantallaSincronizacionSageAutomatica(
            estado: actual,
            loginDisponible: actual.solicitaCredenciales,
            procesandoCredenciales: false,
            onIngresar: (_, _) async {
              estado.value = const EstadoSincronizacionSageAutomatica(
                etapa: EtapaSincronizacionSageAutomatica.autenticando,
                titulo: 'Iniciando sesión',
                paso: PasoSincronizacionSageAutomatica.sesion,
              );
            },
            onReintentar: () {},
            onCancelar: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(find.byType(TextFormField).first, 'usuario-prueba');
    await tester.enterText(find.byType(TextFormField).last, 'clave-prueba');
    final password = tester
        .widget<TextFormField>(find.byType(TextFormField).last)
        .controller!;
    await tester.ensureVisible(find.text('Iniciar y sincronizar'));
    await tester.tap(find.text('Iniciar y sincronizar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(password.text, 'clave-prueba');
    estado.value = login;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(password.text, 'clave-prueba');
    estado.value = const EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.detectandoPerfil,
      titulo: 'Detectando perfil',
      paso: PasoSincronizacionSageAutomatica.perfil,
    );
    await tester.pump();
    expect(password.text, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Widget buildSubject(
    EstadoSincronizacionSageAutomatica estado, {
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: PantallaSincronizacionSageAutomatica(
        estado: estado,
        loginDisponible: false,
        procesandoCredenciales: false,
        onIngresar: (_, _) async {},
        onReintentar: () {},
        onCancelar: () {},
      ),
    );
  }

  testWidgets('el progreso de SAGE permanece centrado en la pantalla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildSubject(const EstadoSincronizacionSageAutomatica.preparando()),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final contenido = tester.getRect(
      find.byKey(const ValueKey('sage-auto-progress')),
    );
    expect(contenido.center.dx, closeTo(215, 0.1));
    expect(contenido.center.dy, closeTo(450, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'muestra un riel de cuatro etapas y explica solo la etapa actual',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildSubject(
          const EstadoSincronizacionSageAutomatica(
            etapa: EtapaSincronizacionSageAutomatica.abriendoHistorial,
            titulo: 'Leyendo historial',
            detalle: 'Preparando los datos académicos…',
            progreso: 0.62,
            paso: PasoSincronizacionSageAutomatica.historial,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey<String>('sage-sync-stepper')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-stepper-rail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-0-completada')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-1-completada')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-2-activa')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-3-pendiente')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-loading-2')),
        findsOneWidget,
      );
      expect(find.text('Sincronización con SAGE'), findsOneWidget);
      expect(find.text('Paso 3 de 4'), findsOneWidget);
      expect(find.text('Trayectoria académica'), findsOneWidget);
      expect(find.text('Preparando los datos académicos…'), findsOneWidget);
      expect(find.text('Leyendo historial'), findsNothing);
      expect(find.text('Acceso a SAGE'), findsNothing);
      expect(find.text('Perfil y legajo'), findsNothing);
      expect(find.text('Documentos y guardado'), findsNothing);
      expect(find.text('Completado'), findsNothing);
      expect(find.text('En curso'), findsNothing);
      expect(find.text('Pendiente'), findsNothing);
    },
  );

  testWidgets(
    'anima el marcador activo y mantiene estable el área de contenido',
    (WidgetTester tester) async {
      const firstState = EstadoSincronizacionSageAutomatica(
        etapa: EtapaSincronizacionSageAutomatica.abriendoLegajo,
        titulo: 'Abriendo Legajo Único Alumno',
        detalle: 'Ingresando al módulo académico…',
        progreso: 0.36,
        paso: PasoSincronizacionSageAutomatica.legajo,
        sesionReutilizada: true,
      );
      const secondState = EstadoSincronizacionSageAutomatica(
        etapa: EtapaSincronizacionSageAutomatica.abriendoLegajo,
        titulo: 'Abriendo Legajo Único Alumno',
        detalle: 'Ingresando a Legajo Alumnos con el perfil Docente…',
        progreso: 0.38,
        paso: PasoSincronizacionSageAutomatica.legajo,
        sesionReutilizada: true,
      );
      const contentKey = ValueKey<String>('sage-sync-step-content');

      await tester.pumpWidget(buildSubject(firstState));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey<String>('sage-sync-step-loading-1')),
        findsOneWidget,
      );
      expect(find.text('Perfil y legajo'), findsOneWidget);
      expect(find.text('Sesión reutilizada'), findsOneWidget);
      final heightBefore = tester.getSize(find.byKey(contentKey)).height;
      final progressTopBefore = tester
          .getTopLeft(find.byType(LinearProgressIndicator))
          .dy;

      await tester.pumpWidget(buildSubject(secondState));
      await tester.pump(const Duration(milliseconds: 250));

      final heightAfter = tester.getSize(find.byKey(contentKey)).height;
      final progressTopAfter = tester
          .getTopLeft(find.byType(LinearProgressIndicator))
          .dy;
      expect(heightAfter, heightBefore);
      expect(progressTopAfter, closeTo(progressTopBefore, 0.1));
      expect(
        find.text('Ingresando a Legajo Alumnos con el perfil Docente…'),
        findsOneWidget,
      );
    },
  );

  testWidgets('marca el error sin repetir estados en el contenido', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const EstadoSincronizacionSageAutomatica(
          etapa: EtapaSincronizacionSageAutomatica.error,
          titulo: 'No se pudo cargar',
          detalle: 'SAGE no pudo abrir el legajo.',
          permiteReintentar: true,
          paso: PasoSincronizacionSageAutomatica.legajo,
          codigoError: CodigoErrorSincronizacionSage.abrirLegajo,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('sage-sync-step-0-completada')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sage-sync-step-1-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sage-sync-step-2-pendiente')),
      findsOneWidget,
    );
    expect(find.text('Atención requerida'), findsOneWidget);
    expect(find.text('Perfil y legajo'), findsOneWidget);
    expect(find.text('SAGE no pudo abrir el legajo.'), findsOneWidget);
    expect(find.text('SAGE-LEGAJO-02'), findsOneWidget);
    expect(find.text('Requiere atención'), findsNothing);
    expect(find.text('Reintentar este paso'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('los mensajes rápidos no duplican textos ni adelantan el riel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final fuente = ByteData.sublistView(
        await File('assets/fonts/Inter_24pt-Regular.ttf').readAsBytes(),
      );
      await (FontLoader('Roboto')..addFont(Future.value(fuente))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    const perfil = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.abriendoLegajo,
      titulo: 'Abriendo legajo',
      detalle: 'Ingresando al módulo académico…',
      progreso: 0.36,
      paso: PasoSincronizacionSageAutomatica.legajo,
    );
    const historial = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.abriendoHistorial,
      titulo: 'Leyendo historial',
      detalle: 'Preparando los datos académicos…',
      progreso: 0.62,
      paso: PasoSincronizacionSageAutomatica.historial,
    );
    const carreras = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.leyendoTrayectoria,
      titulo: 'Leyendo las carreras',
      detalle: 'Relacionando las materias y sus calificaciones…',
      progreso: 0.7,
      paso: PasoSincronizacionSageAutomatica.carreras,
    );
    await tester.pumpWidget(buildSubject(perfil));
    final riel = tester.getRect(
      find.byKey(const ValueKey('sage-sync-stepper-rail')),
    );
    final contenido = tester.getRect(
      find.byKey(const ValueKey('sage-sync-step-content')),
    );
    await tester.pumpWidget(buildSubject(historial));
    await tester.pump(const Duration(milliseconds: 32));
    await tester.pumpWidget(buildSubject(carreras));
    for (var frame = 0; frame < 18; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final tituloPerfil = find.text('Perfil y legajo');
      final tituloHistorial = find.text('Trayectoria académica');
      expect(
        tituloPerfil.evaluate().length + tituloHistorial.evaluate().length,
        1,
        reason: 'Cada cuadro debe contener un solo mensaje del paso actual.',
      );
      final enPerfil = tituloPerfil.evaluate().isNotEmpty;
      expect(
        find.byKey(ValueKey('sage-sync-step-${enPerfil ? 1 : 2}-activa')),
        findsOneWidget,
        reason: 'El riel debe representar el paso que todavía está visible.',
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('sage-sync-stepper-rail'))),
        riel,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('sage-sync-step-content'))),
        contenido,
      );
      expect(tester.takeException(), isNull);
      if (frame == 8) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final imagen = await boundary.toImage();
          final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/qa/sage_775_paso_en_transicion.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          imagen.dispose();
        });
      }
    }
    expect(find.text(historial.detalle!), findsNothing);
    expect(find.text(carreras.detalle!), findsOneWidget);
  });

  testWidgets('un cambio de detalle conserva una sola cabecera y su posición', (
    tester,
  ) async {
    const primero = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.abriendoLegajo,
      titulo: 'Abriendo legajo',
      detalle: 'Ingresando al módulo académico…',
      paso: PasoSincronizacionSageAutomatica.legajo,
      sesionReutilizada: true,
    );
    const segundo = EstadoSincronizacionSageAutomatica(
      etapa: EtapaSincronizacionSageAutomatica.abriendoLegajo,
      titulo: 'Abriendo legajo',
      detalle: 'Buscando el legajo del perfil Docente…',
      paso: PasoSincronizacionSageAutomatica.legajo,
      sesionReutilizada: true,
    );
    await tester.pumpWidget(buildSubject(primero));
    final posicion = tester.getTopLeft(find.text('Perfil y legajo'));
    await tester.pumpWidget(buildSubject(segundo));
    for (var frame = 0; frame < 16; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Perfil y legajo'), findsOneWidget);
      expect(find.text('Sesión reutilizada'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Perfil y legajo')), posicion);
      expect(tester.takeException(), isNull);
    }
    expect(find.text(segundo.detalle!), findsOneWidget);
  });

  testWidgets('muestra las cuatro etapas completadas al finalizar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const EstadoSincronizacionSageAutomatica(
          etapa: EtapaSincronizacionSageAutomatica.completada,
          titulo: 'Sincronización completa',
          detalle: 'Los datos quedaron actualizados.',
          progreso: 1,
          paso: PasoSincronizacionSageAutomatica.guardado,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    for (var index = 0; index < 4; index++) {
      expect(
        find.byKey(ValueKey<String>('sage-sync-step-$index-completada')),
        findsOneWidget,
      );
    }
    expect(find.text('Finalizado'), findsOneWidget);
    expect(find.text('Sincronización completa'), findsOneWidget);
    expect(find.text('Los datos quedaron actualizados.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'Sesión reutilizada conserva su elemento, posición y opacidad entre pasos',
    (tester) async {
      EstadoSincronizacionSageAutomatica estado(
        PasoSincronizacionSageAutomatica paso,
      ) => EstadoSincronizacionSageAutomatica(
        etapa: EtapaSincronizacionSageAutomatica.abriendoHistorial,
        titulo: 'Preparando los datos académicos',
        detalle: 'Avance del paso ${paso.name}…',
        paso: paso,
        sesionReutilizada: true,
      );
      await tester.pumpWidget(
        buildSubject(estado(PasoSincronizacionSageAutomatica.legajo)),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final etiqueta = find.text('Sesión reutilizada');
      final elemento = tester.element(etiqueta);
      final posicion = tester.getRect(etiqueta);
      var huboTransicionDelPaso = false;
      for (final paso in [
        PasoSincronizacionSageAutomatica.historial,
        PasoSincronizacionSageAutomatica.documentos,
      ]) {
        await tester.pumpWidget(buildSubject(estado(paso)));
        for (var frame = 0; frame < 18; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.element(etiqueta), same(elemento));
          expect(tester.getRect(etiqueta), posicion);
          final fundidos = find.ancestor(
            of: etiqueta,
            matching: find.byType(FadeTransition),
          );
          for (final widget in tester.widgetList<FadeTransition>(fundidos)) {
            expect(widget.opacity.value, 1);
          }
          final fundidoDelPaso = tester.widget<FadeTransition>(
            find.descendant(
              of: find.byKey(const ValueKey('sage-sync-step-content')),
              matching: find.byType(FadeTransition),
            ),
          );
          huboTransicionDelPaso |= fundidoDelPaso.opacity.value < 1;
        }
      }
      expect(huboTransicionDelPaso, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el avance numérico no vuelve a animar el mensaje', (
    tester,
  ) async {
    EstadoSincronizacionSageAutomatica estado(double progreso) =>
        EstadoSincronizacionSageAutomatica(
          etapa: EtapaSincronizacionSageAutomatica.descargandoDocumento,
          titulo: 'Descargando documento',
          detalle: 'Recibiendo tu libreta de SAGE…',
          paso: PasoSincronizacionSageAutomatica.documentos,
          progreso: progreso,
        );
    await tester.pumpWidget(buildSubject(estado(0.75)));
    for (var i = 0; i < 8; i++) {
      await tester.pumpWidget(buildSubject(estado(0.75 + i * 0.02)));
      await tester.pump(const Duration(milliseconds: 16));
      final transicion = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byKey(const ValueKey('sage-sync-step-content')),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(transicion.opacity.value, 1);
      expect(find.text('Recibiendo tu libreta de SAGE…'), findsOneWidget);
    }
  });

  testWidgets(
    'los cambios rápidos entre login y progreso no superponen paneles',
    (tester) async {
      const login = EstadoSincronizacionSageAutomatica(
        etapa: EtapaSincronizacionSageAutomatica.credenciales,
        titulo: 'Conectar con SAGE',
        paso: PasoSincronizacionSageAutomatica.sesion,
      );
      const progreso = EstadoSincronizacionSageAutomatica.preparando();
      await tester.pumpWidget(buildSubject(login));
      for (final estado in [progreso, login, progreso]) {
        await tester.pumpWidget(buildSubject(estado));
        await tester.pump(const Duration(milliseconds: 32));
        expect(tester.takeException(), isNull);
      }
      for (var frame = 0; frame < 18; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.byType(Form).evaluate().length +
              find.byKey(const ValueKey('sage-sync-stepper')).evaluate().length,
          1,
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(Form), findsNothing);
      expect(find.text('Acceso a SAGE'), findsOneWidget);
    },
  );

  testWidgets('respeta movimiento reducido y muestra el estado más reciente', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const EstadoSincronizacionSageAutomatica.preparando(),
        reduceMotion: true,
      ),
    );
    await tester.pumpWidget(
      buildSubject(
        const EstadoSincronizacionSageAutomatica(
          etapa: EtapaSincronizacionSageAutomatica.guardando,
          titulo: 'Guardando los datos',
          detalle: 'Actualizando tu trayectoria académica…',
          paso: PasoSincronizacionSageAutomatica.guardado,
          progreso: 0.98,
        ),
        reduceMotion: true,
      ),
    );
    expect(find.text('Acceso a SAGE'), findsNothing);
    expect(find.text('Documentos y guardado'), findsOneWidget);
    expect(find.text('Actualizando tu trayectoria académica…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
