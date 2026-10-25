import 'dart:convert';
import 'dart:io';

import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:flutter_test/flutter_test.dart';

const _perfil = PerfilTrayectoriaSageLaboratorio(
  nombre: 'Lucía Pérez',
  dni: '11223344',
);

DocumentoAcademicoSage _solicitud(
  TipoDocumentoAcademicoPdf tipo, {
  String institucion = 'Instituto de Prueba',
  String carrera = 'Profesorado de Prueba',
  String careerKey = 'carrera-1',
}) => DocumentoAcademicoSage(
  tipo: TipoDocumentoAcademicoSage.values.byName(tipo.name),
  gridRowId: 'fila-variable',
  careerKey: careerKey,
  carrera: carrera,
  institucion: institucion,
);

DocumentoAcademicoPdf _nativo(
  TipoDocumentoAcademicoPdf tipo, {
  String nota = '8',
}) => DocumentoAcademicoPdf(
  tipo: tipo,
  alumno: 'Lucía Pérez',
  documento: '11223344',
  establecimiento: 'Instituto de Prueba',
  carrera: 'Profesorado de Prueba',
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

List<int> _pdf(TipoDocumentoAcademicoPdf tipo, {String nota = '8'}) {
  final titulo = switch (tipo) {
    TipoDocumentoAcademicoPdf.libreta => 'Libreta de Calificaciones',
    TipoDocumentoAcademicoPdf.analitico => 'Certificado Analítico',
    TipoDocumentoAcademicoPdf.situacionAcademica =>
      'Situación Académica del Alumno',
  };
  final stream = ZLibEncoder().convert(
    latin1.encode('''
BT 470 770 Td (Paraná 07/10/2026) Tj ET
BT 60 740 Td (Alumno: LUCIA PEREZ. Documento: 11223344) Tj ET
BT 60 720 Td (Establecimiento: INSTITUTO DE PRUEBA) Tj ET
BT 60 700 Td (Carrera: PROFESORADO DE PRUEBA) Tj ET
BT 60 675 Td ($titulo) Tj ET
BT 62 640 Td (FILOSOFIA DE LA EDUCACION) Tj ET
BT 245 640 Td (2) Tj ET
BT 281 640 Td (Aprobada) Tj ET
BT 349 640 Td (06/10/2026) Tj ET
BT 430 640 Td ($nota) Tj ET
BT 60 580 Td (Condición del Alumno: REGULAR) Tj ET
BT 60 560 Td (Promedio de Materias Aprobadas: $nota) Tj ET
'''),
  );
  return [
    ...latin1.encode(
      '%PDF-1.3\n1 0 obj\n<< /Filter /FlateDecode /Length ${stream.length} >>\nstream\n',
    ),
    ...stream,
    ...latin1.encode('\nendstream\nendobj\n%%EOF'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory carpeta;
  late RepositorioDocumentosAcademicosSage repo;
  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('sage-documentos-prueba-');
    repo = RepositorioDocumentosAcademicosSage(directorio: () async => carpeta);
  });
  tearDown(() async => carpeta.delete(recursive: true));

  for (final tipo in TipoDocumentoAcademicoPdf.values) {
    final clave = ClaveDocumentoAcademicoSage.de(_perfil, _solicitud(tipo));
    test(
      '${tipo.name}: primera obtención, reapertura sin red y reinicio',
      () async {
        var solicitudes = 0;
        final origen = await File(
          '${carpeta.path}/origen.bin',
        ).writeAsBytes(_pdf(tipo));
        final primera = await repo.obtener(
          clave,
          obtenerRemoto: () async {
            solicitudes++;
            return origen;
          },
        );
        expect(solicitudes, 1);
        expect(primera?.nativo?.materias.single.nota, '8');
        expect(primera?.archivo?.path, isNot(origen.path));
        await origen.delete();
        final reiniciada = RepositorioDocumentosAcademicosSage(
          directorio: () async => carpeta,
        );
        final segunda = await reiniciada.obtener(
          clave,
          obtenerRemoto: () async {
            solicitudes++;
            throw const SocketException('Sin conexión');
          },
        );
        expect(solicitudes, 1);
        expect(segunda?.obtenidoEn, primera?.obtenidoEn);
        expect(segunda?.nativo?.tipo, tipo);
        expect(await segunda!.archivo!.exists(), isTrue);
      },
    );

    test(
      '${tipo.name}: Actualizar cambia la versión y conserva el PDF anterior',
      () async {
        final origen = await File(
          '${carpeta.path}/primero.bin',
        ).writeAsBytes(_pdf(tipo));
        final vieja = await repo.guardar(clave, archivo: origen);
        final reciente = await File(
          '${carpeta.path}/nuevo.bin',
        ).writeAsBytes(_pdf(tipo, nota: '10'));
        final nueva = await repo.obtener(
          clave,
          actualizar: true,
          obtenerRemoto: () async => reciente,
        );
        expect(nueva?.nativo?.materias.single.nota, '10');
        expect(await vieja.archivo!.exists(), isTrue);
        expect((await repo.cargar(clave))?.nativo?.materias.single.nota, '10');
        // Sin el botón Actualizar, una sincronización general no reemplaza la copia.
        await repo.guardar(clave, archivo: origen);
        expect((await repo.cargar(clave))?.nativo?.materias.single.nota, '10');
      },
    );

    test(
      '${tipo.name}: error, cancelación y PDF incompleto conservan la copia',
      () async {
        final vieja = await repo.guardar(clave, nativo: _nativo(tipo));
        await expectLater(
          repo.obtener(
            clave,
            actualizar: true,
            obtenerRemoto: () async {
              throw const SocketException('Sin conexión');
            },
          ),
          throwsA(isA<SocketException>()),
        );
        expect(
          await repo.obtener(
            clave,
            actualizar: true,
            obtenerRemoto: () async => null,
          ),
          isNull,
        );
        final incompleto = await File(
          '${carpeta.path}/incompleto.bin',
        ).writeAsBytes(latin1.encode('%PDF-1.3 cortado'));
        await expectLater(
          repo.obtener(
            clave,
            actualizar: true,
            obtenerRemoto: () async => incompleto,
          ),
          throwsFormatException,
        );
        final reabierta = await repo.cargar(clave);
        expect(reabierta?.obtenidoEn, vieja.obtenidoEn);
        expect(
          reabierta?.nativo?.materias.single.nombre,
          'Filosofía de la educación',
        );
      },
    );

    test(
      '${tipo.name}: la pantalla nativa persiste sin depender del PDF',
      () async {
        final origen = await File(
          '${carpeta.path}/original.bin',
        ).writeAsBytes(_pdf(tipo));
        final copia = await repo.guardar(
          clave,
          archivo: origen,
          nativo: _nativo(tipo),
        );
        await copia.archivo!.delete();
        final reiniciada = RepositorioDocumentosAcademicosSage(
          directorio: () async => carpeta,
        );
        final reabierta = await reiniciada.obtener(
          clave,
          obtenerRemoto: () async => throw StateError('No debe conectarse'),
        );
        expect(reabierta?.archivo, isNull);
        expect(reabierta?.nativo?.alumno, 'Lucía Pérez');
        expect(
          reabierta?.nativo?.materias.single.nombre,
          'Filosofía de la educación',
        );
      },
    );
  }

  for (final tipo in TipoDocumentoAcademicoPdf.values) {
    test(
      '${tipo.name}: acepta el sufijo de nivel del historial y reabre sin red',
      () async {
        final clave = ClaveDocumentoAcademicoSage.de(
          _perfil,
          _solicitud(tipo, institucion: 'Instituto de Prueba-SUPERIOR'),
        );
        // La clave completa no cambia: mantiene las copias ya indexadas separadas.
        final claveAnterior = ClaveDocumentoAcademicoSage(
          usuario: clave.usuario,
          institucion: clave.institucion,
          carrera: clave.carrera,
          nombreCarrera: clave.nombreCarrera,
          tipo: tipo,
        );
        expect(clave.id, claveAnterior.id);
        final archivo = await File(
          '${carpeta.path}/descarga_anterior.pdf',
        ).writeAsBytes(_pdf(tipo));
        final primera = await repo.obtener(
          clave,
          obtenerRemoto: () async => throw StateError('La descarga ya existe'),
        );
        expect(primera?.nativo?.establecimiento, 'INSTITUTO DE PRUEBA');
        await archivo.delete();
        final reiniciada = RepositorioDocumentosAcademicosSage(
          directorio: () async => carpeta,
        );
        final reabierta = await reiniciada.obtener(
          clave,
          obtenerRemoto: () async =>
              throw const SocketException('Sin conexión'),
        );
        expect(reabierta?.obtenidoEn, primera?.obtenidoEn);
        expect(reabierta?.nativo?.tipo, tipo);
        final actualizada = await reiniciada.guardar(
          clave,
          nativo: _nativo(tipo, nota: '10'),
          actualizar: true,
        );
        expect(actualizada.nativo?.materias.single.nota, '10');
        final ajena = DocumentoAcademicoPdf.fromJson({
          ..._nativo(tipo).toJson(),
          'establecimiento': 'Otro Instituto',
        });
        await expectLater(
          reiniciada.guardar(clave, nativo: ajena, actualizar: true),
          throwsFormatException,
        );
        expect(
          (await reiniciada.cargar(clave))?.nativo?.materias.single.nota,
          '10',
        );
      },
    );
  }

  test(
    'no elimina Superior cuando forma parte del nombre de la institución',
    () {
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(
          TipoDocumentoAcademicoPdf.libreta,
          institucion: 'Instituto de Prueba Superior',
        ),
      );
      expect(
        () => clave.validar(_nativo(TipoDocumentoAcademicoPdf.libreta)),
        throwsFormatException,
      );
    },
  );

  test(
    'separa usuarios, instituciones, carreras y tipos aunque se repita la fila',
    () async {
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      );
      await repo.guardar(
        clave,
        nativo: _nativo(TipoDocumentoAcademicoPdf.libreta),
      );
      final variantes = [
        ClaveDocumentoAcademicoSage.de(
          const PerfilTrayectoriaSageLaboratorio(
            nombre: 'Lucía Pérez',
            dni: '55667788',
          ),
          _solicitud(TipoDocumentoAcademicoPdf.libreta),
        ),
        ClaveDocumentoAcademicoSage.de(
          _perfil,
          _solicitud(
            TipoDocumentoAcademicoPdf.libreta,
            institucion: 'Otro instituto',
          ),
        ),
        ClaveDocumentoAcademicoSage.de(
          _perfil,
          _solicitud(TipoDocumentoAcademicoPdf.libreta, careerKey: 'carrera-2'),
        ),
        ClaveDocumentoAcademicoSage.de(
          _perfil,
          _solicitud(TipoDocumentoAcademicoPdf.analitico),
        ),
      ];
      for (final variante in variantes) {
        expect(variante.id, isNot(clave.id));
        expect(await repo.cargar(variante), isNull);
      }
    },
  );

  test('no usa solamente el nombre para identificar una cuenta', () {
    expect(
      () => ClaveDocumentoAcademicoSage.de(
        const PerfilTrayectoriaSageLaboratorio(nombre: 'Lucía Pérez'),
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      ),
      throwsFormatException,
    );
  });

  test(
    'recupera una descarga antigua sólo cuando coincide toda la identidad',
    () async {
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      );
      await File(
        '${carpeta.path}/descarga_antigua.pdf',
      ).writeAsBytes(_pdf(TipoDocumentoAcademicoPdf.libreta));
      final copia = await repo.obtener(
        clave,
        obtenerRemoto: () async => throw StateError('No debe descargar'),
      );
      expect(copia?.nativo?.materias.single.nota, '8');
      final ajena = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(
          TipoDocumentoAcademicoPdf.libreta,
          institucion: 'Otro instituto',
        ),
      );
      var intentos = 0;
      expect(
        await repo.obtener(
          ajena,
          obtenerRemoto: () async {
            intentos++;
            return null;
          },
        ),
        isNull,
      );
      expect(intentos, 1);
    },
  );

  test(
    'un fallo al publicar el índice mantiene disponible la versión previa',
    () async {
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      );
      await repo.guardar(
        clave,
        nativo: _nativo(TipoDocumentoAcademicoPdf.libreta),
      );
      await Directory(
        '${carpeta.path}/sage_documentos_v1/${clave.id}/actual.json.part',
      ).create();
      await expectLater(
        repo.guardar(
          clave,
          nativo: _nativo(TipoDocumentoAcademicoPdf.libreta, nota: '10'),
          actualizar: true,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect((await repo.cargar(clave))?.nativo?.materias.single.nota, '8');
    },
  );

  test(
    'un documento de otro titular o tipo nunca sustituye al guardado',
    () async {
      final clave = ClaveDocumentoAcademicoSage.de(
        _perfil,
        _solicitud(TipoDocumentoAcademicoPdf.libreta),
      );
      await repo.guardar(
        clave,
        nativo: _nativo(TipoDocumentoAcademicoPdf.libreta),
      );
      await expectLater(
        repo.guardar(
          clave,
          nativo: _nativo(TipoDocumentoAcademicoPdf.analitico),
          actualizar: true,
        ),
        throwsFormatException,
      );
      final ajeno = DocumentoAcademicoPdf.fromJson({
        ..._nativo(TipoDocumentoAcademicoPdf.libreta).toJson(),
        'documento': '55667788',
      });
      await expectLater(
        repo.guardar(clave, nativo: ajeno, actualizar: true),
        throwsFormatException,
      );
      expect((await repo.cargar(clave))?.nativo?.documento, '11223344');
    },
  );
}
