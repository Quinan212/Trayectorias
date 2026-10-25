import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../componentes/componentes_atlassian.dart';

String nombrePerfilAtlassian(PerfilTrayectoriaSageLaboratorio? perfil) {
  final name = perfil?.nombre.trim() ?? '';
  return name.isEmpty ? 'Estudiante' : name;
}

String inicialesAtlassian(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'ES';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2).toInt())
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String nombreCarreraAtlassian(String raw) {
  final value = raw.trim();
  return value.isEmpty ? 'Carrera sin nombre' : value;
}

AparienciaLozengeAtlassian aparienciaEstadoAtlassian(
  EstadoMateriaSageLaboratorio estado,
) {
  return switch (estado) {
    EstadoMateriaSageLaboratorio.aprobada => AparienciaLozengeAtlassian.success,
    EstadoMateriaSageLaboratorio.regular => AparienciaLozengeAtlassian.brand,
    EstadoMateriaSageLaboratorio.cursando =>
      AparienciaLozengeAtlassian.discovery,
    EstadoMateriaSageLaboratorio.noRegularizada =>
      AparienciaLozengeAtlassian.warning,
    EstadoMateriaSageLaboratorio.desconocida =>
      AparienciaLozengeAtlassian.neutral,
  };
}

String formatoFechaAtlassian(DateTime? date) {
  if (date == null) return 'Sin fecha';
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatoFechaHoraAtlassian(DateTime? date, [String? hour]) {
  final dateText = formatoFechaAtlassian(date);
  final normalizedHour = hour?.trim() ?? '';
  return normalizedHour.isEmpty ? dateText : '$dateText · $normalizedHour';
}

String textoSincronizacionAtlassian(DateTime? date) {
  if (date == null) return 'Pendiente';
  return formatoFechaAtlassian(date);
}

String idCarreraExamenAtlassian(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('geograf')) return 'geografia';
  if (value.contains('política') ||
      value.contains('politica') ||
      value.contains('ciencia política') ||
      value.contains('ciencia politica')) {
    return 'politica';
  }
  if (value.contains('artes')) return 'artes_visuales';
  if (value.contains('música') || value.contains('musica')) return 'musica';
  if (value.contains('física') || value.contains('fisica')) return 'fisica';
  return 'historia';
}
