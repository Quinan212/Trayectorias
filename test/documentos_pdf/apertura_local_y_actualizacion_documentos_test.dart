import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:correlativas_historia/funcionalidades/acceso_estudiante/pantallas/pantalla_visor_pdf_sage.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/abrir_documento_academico_sage.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _perfil = PerfilTrayectoriaSageLaboratorio(
  nombre: 'Lucía Pérez',
  dni: '11223344',
);

DocumentoAcademicoSage _solicitud(TipoDocumentoAcademicoPdf tipo) =>
    DocumentoAcademicoSage(
      tipo: TipoDocumentoAcademicoSage.values.byName(tipo.name),
      gridRowId: 'row-1',
      careerKey: 'historia-1',
      carrera: 'Profesorado de Historia',
      institucion: 'Instituto de Prueba',
    );

DocumentoAcademicoPdf _nativo(
  TipoDocumentoAcademicoPdf tipo, {
  String nota = '8',
}) => DocumentoAcademicoPdf(
  tipo: tipo,
  alumno: 'Lucía Pérez',
  documento: '11223344',
  establecimiento: 'Instituto de Prueba',
  carrera: 'Profesorado de Historia',
  fechaEmision: '07/10/2026',
  condicionAlumno: 'Regular',
  promedioOficial: nota,
  materias: [
    MateriaDocumentoAcademicoPdf(
      nombre: 'Filosofía de la educación',
      anio: 2,
      estado: 'Aprobada',
      nota: nota,
      fechaMovimiento: '06/10/2026',
    ),
  ],
);

Future<void> _avanzar(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final tipo in TipoDocumentoAcademicoPdf.values) {
    testWidgets(
      '${tipo.name}: el acceso abre la copia nativa sin montar SAGE, incluso al reiniciar',
      (tester) async {
        final carpeta = await tester.runAsync(
          () => Directory.systemTemp.createTemp('sage-visor-local-'),
        );
        addTearDown(() async {
          await carpeta!.delete(recursive: true);
        });
        final repo = RepositorioDocumentosAcademicosSage(
          directorio: () async => carpeta!,
        );
        final solicitud = _solicitud(tipo);
        final clave = ClaveDocumentoAcademicoSage.de(_perfil, solicitud);
        await tester.runAsync(() => repo.guardar(clave, nativo: _nativo(tipo)));
        for (var apertura = 0; apertura < 2; apertura++) {
          final reiniciada = RepositorioDocumentosAcademicosSage(
            directorio: () async => carpeta!,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () => unawaited(
                      abrirDocumentoAcademicoSage(
                        context,
                        documento: solicitud,
                        perfil: _perfil,
                        repositorio: reiniciada,
                      ),
                    ),
                    child: const Text('Abrir documento'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Abrir documento'));
          await _avanzar(tester);
          expect(find.byType(VistaDocumentoAcademicoNativo), findsOneWidget);
          expect(find.byType(PantallaSageLaboratorio), findsNothing);
          expect(find.text('Actualizar'), findsOneWidget);
          expect(find.textContaining('Lucía'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.byKey(const Key('document-native-floating-back')),
          );
          await _avanzar(tester);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

  testWidgets(
    'Actualizar conserva el documento visible ante error o cancelación y permite reemplazarlo',
    (tester) async {
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
      final carpeta = await tester.runAsync(
        () => Directory.systemTemp.createTemp('sage-visor-actualizar-'),
      );
      addTearDown(() async {
        await carpeta!.delete(recursive: true);
      });
      final repo = RepositorioDocumentosAcademicosSage(
        directorio: () async => carpeta!,
      );
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      );
      final copia = await tester.runAsync(
        () => repo.guardar(clave, nativo: _nativo(clave.tipo)),
      );
      var solicitudes = 0;
      final espera = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaVisorPdfSage(
            rutaArchivo: null,
            nombreArchivo: 'libreta.pdf',
            copiaLocal: copia,
            onActualizar: () async {
              solicitudes++;
              if (solicitudes == 1) {
                await espera.future;
                throw const SocketException('Sin conexión');
              }
              if (solicitudes == 2) return null;
              return repo.guardar(
                clave,
                nativo: _nativo(clave.tipo, nota: '10'),
                actualizar: true,
              );
            },
          ),
        ),
      );
      await _avanzar(tester);
      await tester.tap(find.text('Actualizar'));
      await tester.pump();
      await tester.tap(find.text('Actualizando…'));
      await tester.pump();
      expect(solicitudes, 1);
      expect(find.byType(VistaDocumentoAcademicoNativo), findsOneWidget);
      espera.complete();
      await _avanzar(tester);
      expect(
        find.text('No se pudo actualizar. La copia guardada sigue disponible.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<VistaDocumentoAcademicoNativo>(
              find.byType(VistaDocumentoAcademicoNativo),
            )
            .documento
            .materias
            .single
            .nota,
        '8',
      );
      await tester.tap(find.text('Actualizar'));
      await _avanzar(tester);
      expect(
        tester
            .widget<VistaDocumentoAcademicoNativo>(
              find.byType(VistaDocumentoAcademicoNativo),
            )
            .documento
            .materias
            .single
            .nota,
        '8',
      );
      await tester.tap(find.text('Actualizar'));
      await _avanzar(tester);
      expect(solicitudes, 3);
      for (
        var espera = 0;
        espera < 8 && find.text('Actualizando…').evaluate().isNotEmpty;
        espera++
      ) {
        await _avanzar(tester);
      }
      expect(find.text('Actualizando…'), findsNothing);
      expect(
        tester
            .widget<VistaDocumentoAcademicoNativo>(
              find.byType(VistaDocumentoAcademicoNativo),
            )
            .documento
            .materias
            .single
            .nota,
        '10',
      );
      expect(
        (await tester.runAsync(
          () => repo.cargar(clave),
        ))?.nativo?.materias.single.nota,
        '10',
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final imagen = await boundary.toImage();
        final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/qa/documento_guardado_775.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        imagen.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
