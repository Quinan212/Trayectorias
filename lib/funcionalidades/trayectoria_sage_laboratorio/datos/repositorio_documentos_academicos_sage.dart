import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../documentos_pdf/extractor_documento_academico_pdf.dart';
import '../documentos_pdf/modelos_documento_academico_pdf.dart';
import '../modelos/modelos_trayectoria_sage_laboratorio.dart';

class ClaveDocumentoAcademicoSage {
  const ClaveDocumentoAcademicoSage({
    required this.usuario,
    required this.institucion,
    this.nombreInstitucion,
    required this.carrera,
    required this.nombreCarrera,
    required this.tipo,
  });

  factory ClaveDocumentoAcademicoSage.de(
    PerfilTrayectoriaSageLaboratorio perfil,
    DocumentoAcademicoSage documento,
  ) {
    var usuario = (perfil.dni ?? '').replaceAll(RegExp(r'\D'), '');
    if (usuario.isEmpty) {
      for (final campo in perfil.campos.entries) {
        final nombre = normalizarTextoDocumentoPdf(campo.key);
        if (const ['dni', 'documento', 'cuil', 'usuario'].contains(nombre)) {
          usuario = campo.value.trim().toLowerCase();
          if (usuario.isNotEmpty) break;
        }
      }
    }
    // Un nombre de persona no identifica una cuenta de forma inequívoca.
    if (usuario.isEmpty ||
        documento.institucion.trim().isEmpty ||
        documento.carrera.trim().isEmpty) {
      throw const FormatException(
        'Falta identificar el titular del documento.',
      );
    }
    return ClaveDocumentoAcademicoSage(
      usuario: usuario,
      institucion: normalizarTextoDocumentoPdf(documento.institucion),
      nombreInstitucion: _normalizarInstitucionSage(documento.institucion),
      carrera: documento.identidadCarrera,
      nombreCarrera: normalizarTextoDocumentoPdf(documento.carrera),
      tipo: TipoDocumentoAcademicoPdf.values.byName(documento.tipo.name),
    );
  }

  final String usuario;
  final String institucion;
  final String? nombreInstitucion;
  final String carrera;
  final String nombreCarrera;
  final TipoDocumentoAcademicoPdf tipo;

  Map<String, dynamic> toJson() => {
    'usuario': usuario,
    'institucion': institucion,
    'carrera': carrera,
    'tipo': tipo.name,
  };

  String get id => sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();

  void validar(DocumentoAcademicoPdf documento) {
    if (documento.tipo != tipo || documento.materias.isEmpty) {
      throw const FormatException('El documento académico no corresponde.');
    }
    final dni = (documento.documento ?? '').replaceAll(RegExp(r'\D'), '');
    if (RegExp(r'^\d+$').hasMatch(usuario) &&
        dni.isNotEmpty &&
        dni != usuario) {
      throw const FormatException('El documento pertenece a otro usuario.');
    }
    if ((documento.establecimiento ?? '').trim().isNotEmpty &&
        _normalizarInstitucionSage(documento.establecimiento!) !=
            (nombreInstitucion ?? institucion)) {
      throw const FormatException('El documento pertenece a otra institución.');
    }
    if ((documento.carrera ?? '').trim().isNotEmpty &&
        normalizarTextoDocumentoPdf(documento.carrera!) != nombreCarrera) {
      throw const FormatException('El documento pertenece a otra carrera.');
    }
  }

  bool coincideConReporte(DocumentoAcademicoPdf documento) =>
      documento.tipo == tipo &&
      (documento.documento ?? '').replaceAll(RegExp(r'\D'), '') == usuario &&
      _normalizarInstitucionSage(documento.establecimiento ?? '') ==
          (nombreInstitucion ?? institucion) &&
      normalizarTextoDocumentoPdf(documento.carrera ?? '') == nombreCarrera;
}

// El historial agrega el nivel educativo al nombre; los reportes lo omiten.
// Conservamos la institución completa en la clave y quitamos sólo ese sufijo
// explícito al comparar los rótulos, sin aceptar coincidencias parciales.
String _normalizarInstitucionSage(String value) => normalizarTextoDocumentoPdf(
  value.replaceFirst(RegExp(r'\s*-\s*SUPERIOR\s*$', caseSensitive: false), ''),
);

class CopiaDocumentoAcademicoSage {
  const CopiaDocumentoAcademicoSage({
    required this.clave,
    required this.obtenidoEn,
    this.archivo,
    this.nativo,
  });

  final ClaveDocumentoAcademicoSage clave;
  final DateTime obtenidoEn;
  final File? archivo;
  final DocumentoAcademicoPdf? nativo;
}

DocumentoAcademicoPdf? _extraerDocumento(Uint8List bytes) {
  try {
    return const ExtractorDocumentoAcademicoPdf().extraer(bytes);
  } on FormatException {
    return null;
  }
}

class RepositorioDocumentosAcademicosSage {
  const RepositorioDocumentosAcademicosSage({this.directorio});

  final Future<Directory> Function()? directorio;
  static final _escrituras = <String, Future<void>>{};
  static final _obtenciones = <String, Future<CopiaDocumentoAcademicoSage?>>{};
  static int _revision = 0;

  Future<Directory> _carpeta(ClaveDocumentoAcademicoSage clave) async {
    final base =
        await (directorio?.call() ?? getApplicationDocumentsDirectory());
    return Directory('${base.path}/sage_documentos_v1/${clave.id}');
  }

  Future<CopiaDocumentoAcademicoSage?> cargar(
    ClaveDocumentoAcademicoSage clave,
  ) async {
    final carpeta = await _carpeta(clave);
    try {
      final indice =
          jsonDecode(
                await File(
                  '${carpeta.path}/actual.json',
                ).readAsString(encoding: utf8),
              )
              as Map;
      for (final entrada in [indice['actual'], indice['anterior']]) {
        if (entrada is! Map) continue;
        try {
          final version = entrada['version'] as String;
          if (!RegExp(r'^\d+-\d+$').hasMatch(version)) continue;
          final raw = await File('${carpeta.path}/$version.json').readAsBytes();
          if (sha256.convert(raw).toString() != entrada['sha256']) continue;
          final datos = jsonDecode(utf8.decode(raw)) as Map;
          if (datos['esquema'] != 1 ||
              jsonEncode(datos['clave']) != jsonEncode(clave.toJson())) {
            continue;
          }
          DocumentoAcademicoPdf? nativo;
          if (datos['nativo'] is Map) {
            nativo = DocumentoAcademicoPdf.fromJson(
              Map<String, dynamic>.from(datos['nativo'] as Map),
            );
            clave.validar(nativo);
          }
          File? archivo;
          if (datos['pdf_sha256'] is String) {
            final pdf = File('${carpeta.path}/$version.pdf');
            if (await pdf.exists()) {
              final bytes = await pdf.readAsBytes();
              if (_pdfValido(bytes) &&
                  sha256.convert(bytes).toString() == datos['pdf_sha256']) {
                archivo = pdf;
              }
            }
          }
          if (archivo == null && nativo == null) continue;
          return CopiaDocumentoAcademicoSage(
            clave: clave,
            obtenidoEn: DateTime.parse(datos['obtenido_en'] as String),
            archivo: archivo,
            nativo: nativo,
          );
        } catch (_) {
          // Una versión dañada no elimina la última copia recuperable.
        }
      }
    } catch (_) {}
    return null;
  }

  Future<CopiaDocumentoAcademicoSage> guardar(
    ClaveDocumentoAcademicoSage clave, {
    File? archivo,
    DocumentoAcademicoPdf? nativo,
    bool actualizar = false,
  }) async {
    final anterior = _escrituras[clave.id] ?? Future<void>.value();
    final tarea = anterior.then(
      (_) => _guardar(
        clave,
        archivo: archivo,
        nativo: nativo,
        actualizar: actualizar,
      ),
    );
    final espera = tarea.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    _escrituras[clave.id] = espera;
    try {
      return await tarea;
    } finally {
      if (identical(_escrituras[clave.id], espera)) {
        final _ = _escrituras.remove(clave.id);
      }
    }
  }

  Future<CopiaDocumentoAcademicoSage> _guardar(
    ClaveDocumentoAcademicoSage clave, {
    File? archivo,
    DocumentoAcademicoPdf? nativo,
    required bool actualizar,
  }) async {
    if (!actualizar) {
      final existente = await cargar(clave);
      if (existente != null) return existente;
    }
    final bytes = archivo == null ? null : await archivo.readAsBytes();
    if (bytes != null && !_pdfValido(bytes)) {
      throw const FormatException('El PDF está incompleto.');
    }
    if (nativo == null && bytes != null && bytes.length <= 2 * 1024 * 1024) {
      nativo = await compute(_extraerDocumento, bytes);
    }
    if (nativo != null) clave.validar(nativo);
    if (bytes == null && nativo == null) {
      throw const FormatException('No se obtuvo un documento válido.');
    }

    final carpeta = await _carpeta(clave);
    await carpeta.create(recursive: true);
    final obtenidoEn = DateTime.now();
    final version = '${obtenidoEn.microsecondsSinceEpoch}-${_revision++}';
    final datos = utf8.encode(
      jsonEncode({
        'esquema': 1,
        'clave': clave.toJson(),
        'obtenido_en': obtenidoEn.toIso8601String(),
        'nativo': nativo?.toJson(),
        'pdf_sha256': bytes == null ? null : sha256.convert(bytes).toString(),
      }),
    );
    if (bytes != null) {
      await File(
        '${carpeta.path}/$version.pdf',
      ).writeAsBytes(bytes, flush: true);
    }
    await File(
      '${carpeta.path}/$version.json',
    ).writeAsBytes(datos, flush: true);
    final indice = File('${carpeta.path}/actual.json');
    Map? anterior;
    try {
      anterior = jsonDecode(await indice.readAsString(encoding: utf8)) as Map;
    } catch (_) {}
    final provisional = File('${carpeta.path}/actual.json.part');
    await provisional.writeAsString(
      jsonEncode({
        'actual': {
          'version': version,
          'sha256': sha256.convert(datos).toString(),
        },
        'anterior': anterior?['actual'],
      }),
      encoding: utf8,
      flush: true,
    );
    // Los archivos de la versión anterior nunca se sobrescriben. Publicar
    // el índice es el último paso, después de validar y guardar la nueva.
    await provisional.rename(indice.path);
    return CopiaDocumentoAcademicoSage(
      clave: clave,
      obtenidoEn: obtenidoEn,
      archivo: bytes == null ? null : File('${carpeta.path}/$version.pdf'),
      nativo: nativo,
    );
  }

  Future<CopiaDocumentoAcademicoSage?> obtener(
    ClaveDocumentoAcademicoSage clave, {
    required Future<File?> Function() obtenerRemoto,
    bool actualizar = false,
  }) async {
    if (!actualizar) {
      final local =
          await cargar(clave) ?? await _recuperarDescargaAnterior(clave);
      if (local != null) return local;
    }
    final pendiente = _obtenciones[clave.id];
    if (pendiente != null) return pendiente;
    Future<CopiaDocumentoAcademicoSage?> adquirir() async {
      final archivo = await obtenerRemoto();
      if (archivo == null) return null;
      return guardar(clave, archivo: archivo, actualizar: actualizar);
    }

    final tarea = adquirir();
    _obtenciones[clave.id] = tarea;
    try {
      return await tarea;
    } finally {
      if (identical(_obtenciones[clave.id], tarea)) {
        final _ = _obtenciones.remove(clave.id);
      }
    }
  }

  Future<CopiaDocumentoAcademicoSage?> _recuperarDescargaAnterior(
    ClaveDocumentoAcademicoSage clave,
  ) async {
    // Los PDF antiguos carecen de índice: sólo se adoptan cuando sus cuatro
    // datos de identidad coinciden, nunca por el nombre del archivo.
    final carpetas = <Directory>[
      await (directorio?.call() ?? getApplicationDocumentsDirectory()),
    ];
    if (directorio == null && Platform.isAndroid) {
      carpetas.addAll(
        await getExternalStorageDirectories(type: StorageDirectory.downloads) ??
            [],
      );
    }
    for (final carpeta in carpetas) {
      if (!await carpeta.exists()) continue;
      await for (final entrada in carpeta.list()) {
        if (entrada is! File || !entrada.path.toLowerCase().endsWith('.pdf')) {
          continue;
        }
        try {
          if (await entrada.length() > 2 * 1024 * 1024) continue;
          final nativo = await compute(
            _extraerDocumento,
            await entrada.readAsBytes(),
          );
          if (nativo != null && clave.coincideConReporte(nativo)) {
            return await guardar(clave, archivo: entrada, nativo: nativo);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static bool _pdfValido(Uint8List bytes) =>
      bytes.length >= 10 &&
      latin1.decode(bytes.sublist(0, 5)) == '%PDF-' &&
      latin1
          .decode(bytes.sublist(bytes.length > 1024 ? bytes.length - 1024 : 0))
          .contains('%%EOF');
}
