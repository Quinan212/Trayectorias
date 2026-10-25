enum TipoDocumentoAcademicoPdf { libreta, analitico, situacionAcademica }

extension TipoDocumentoAcademicoPdfX on TipoDocumentoAcademicoPdf {
  String get titulo => switch (this) {
    TipoDocumentoAcademicoPdf.libreta => 'Libreta de calificaciones',
    TipoDocumentoAcademicoPdf.analitico => 'Certificado analítico',
    TipoDocumentoAcademicoPdf.situacionAcademica => 'Situación académica',
  };

  String get etiquetaCorta => switch (this) {
    TipoDocumentoAcademicoPdf.libreta => 'Libreta',
    TipoDocumentoAcademicoPdf.analitico => 'Analítico',
    TipoDocumentoAcademicoPdf.situacionAcademica => 'Situación académica',
  };
}

enum CategoriaEstadoDocumentoPdf {
  aprobada,
  cursando,
  regular,
  sinEstado,
  otra,
}

class MateriaDocumentoAcademicoPdf {
  const MateriaDocumentoAcademicoPdf({
    required this.nombre,
    required this.anio,
    this.estado,
    this.fechaMovimiento,
    this.nota,
  });

  final String nombre;
  final int anio;
  final String? estado;
  final String? fechaMovimiento;
  final String? nota;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'anio': anio,
    'estado': estado,
    'fecha_movimiento': fechaMovimiento,
    'nota': nota,
  };

  factory MateriaDocumentoAcademicoPdf.fromJson(Map<String, dynamic> json) =>
      MateriaDocumentoAcademicoPdf(
        nombre: json['nombre'] as String,
        anio: json['anio'] as int,
        estado: json['estado'] as String?,
        fechaMovimiento: json['fecha_movimiento'] as String?,
        nota: json['nota'] as String?,
      );

  CategoriaEstadoDocumentoPdf get categoriaEstado {
    final value = normalizarTextoDocumentoPdf(estado ?? '');
    if (value.isEmpty) return CategoriaEstadoDocumentoPdf.sinEstado;
    if (value == 'aprobada' ||
        value == 'aprobado' ||
        value == 'equivalencia' ||
        value == 'promocionada') {
      return CategoriaEstadoDocumentoPdf.aprobada;
    }
    if (value == 'cursando') return CategoriaEstadoDocumentoPdf.cursando;
    if (value == 'regular' || value == 'no regularizada' || value == 'libre') {
      return CategoriaEstadoDocumentoPdf.regular;
    }
    return CategoriaEstadoDocumentoPdf.otra;
  }

  DateTime? get fechaMovimientoDateTime =>
      parsearFechaDocumentoAcademico(fechaMovimiento);

  double? get notaNumerica {
    final value = nota?.trim().replaceAll(',', '.');
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
}

class DocumentoAcademicoPdf {
  const DocumentoAcademicoPdf({
    required this.tipo,
    required this.materias,
    this.alumno,
    this.documento,
    this.establecimiento,
    this.carrera,
    this.fechaEmision,
    this.condicionAlumno,
    this.promedioOficial,
  });

  final TipoDocumentoAcademicoPdf tipo;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final String? alumno;
  final String? documento;
  final String? establecimiento;
  final String? carrera;
  final String? fechaEmision;
  final String? condicionAlumno;
  final String? promedioOficial;

  Map<String, dynamic> toJson() => {
    'tipo': tipo.name,
    'materias': materias.map((materia) => materia.toJson()).toList(),
    'alumno': alumno,
    'documento': documento,
    'establecimiento': establecimiento,
    'carrera': carrera,
    'fecha_emision': fechaEmision,
    'condicion_alumno': condicionAlumno,
    'promedio_oficial': promedioOficial,
  };

  factory DocumentoAcademicoPdf.fromJson(Map<String, dynamic> json) =>
      DocumentoAcademicoPdf(
        tipo: TipoDocumentoAcademicoPdf.values.byName(json['tipo'] as String),
        materias: List<MateriaDocumentoAcademicoPdf>.unmodifiable(
          (json['materias'] as List).map(
            (row) => MateriaDocumentoAcademicoPdf.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          ),
        ),
        alumno: json['alumno'] as String?,
        documento: json['documento'] as String?,
        establecimiento: json['establecimiento'] as String?,
        carrera: json['carrera'] as String?,
        fechaEmision: json['fecha_emision'] as String?,
        condicionAlumno: json['condicion_alumno'] as String?,
        promedioOficial: json['promedio_oficial'] as String?,
      );

  int get totalMaterias => materias.length;

  int get aprobadas => materias
      .where(
        (materia) =>
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.aprobada,
      )
      .length;

  int get cursando => materias
      .where(
        (materia) =>
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.cursando,
      )
      .length;

  int get regulares => materias
      .where(
        (materia) =>
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.regular,
      )
      .length;

  int get sinEstado => materias
      .where(
        (materia) =>
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.sinEstado,
      )
      .length;

  int get otrosEstados => materias
      .where(
        (materia) =>
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.otra,
      )
      .length;

  List<int> get anios {
    final values = materias.map((materia) => materia.anio).toSet().toList()
      ..sort();
    return List<int>.unmodifiable(values);
  }

  DateTime? get ultimaFechaMovimiento {
    DateTime? latest;
    for (final materia in materias) {
      final date = materia.fechaMovimientoDateTime;
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest;
  }

  DateTime? get primeraFechaMovimiento {
    DateTime? earliest;
    for (final materia in materias) {
      final date = materia.fechaMovimientoDateTime;
      if (date != null && (earliest == null || date.isBefore(earliest))) {
        earliest = date;
      }
    }
    return earliest;
  }

  double? get promedioOficialNumerico {
    final value = promedioOficial?.trim().replaceAll(',', '.');
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
}

DateTime? parsearFechaDocumentoAcademico(String? value) {
  final match = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
  ).firstMatch(value?.trim() ?? '');
  if (match == null) return null;
  final day = int.tryParse(match.group(1) ?? '');
  final month = int.tryParse(match.group(2) ?? '');
  final year = int.tryParse(match.group(3) ?? '');
  if (day == null || month == null || year == null) return null;
  final date = DateTime(year, month, day);
  return date.day == day && date.month == month && date.year == year
      ? date
      : null;
}

String normalizarTextoDocumentoPdf(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
