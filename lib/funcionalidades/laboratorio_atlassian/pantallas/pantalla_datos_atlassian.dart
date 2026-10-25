import 'package:flutter/material.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/tema/tema_herramientas_app.dart';

import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../componentes/componentes_academicos_app.dart';
import '../componentes/componentes_atlassian.dart';
import '../componentes/trayectoria_activa_atlassian.dart';
import '../tema/tema_atlassian.dart';
import 'utilidades_atlassian.dart';

class PantallaDatosAtlassian extends StatefulWidget {
  const PantallaDatosAtlassian({
    super.key,
    required this.trajectoryListenable,
    required this.localLoadedListenable,
    required this.selectedCareerListenable,
    required this.onDesynchronize,
    required this.onNavigate,
    required this.onSearch,
  });

  final ValueNotifier<TrayectoriaSageLaboratorio?> trajectoryListenable;
  final ValueNotifier<bool> localLoadedListenable;
  final ValueNotifier<int> selectedCareerListenable;
  final VoidCallback onDesynchronize;
  final ValueChanged<int> onNavigate;
  final VoidCallback onSearch;

  @override
  State<PantallaDatosAtlassian> createState() => _PantallaDatosAtlassianState();
}

class _PantallaDatosAtlassianState extends State<PantallaDatosAtlassian> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final headerHeight = alturaEncabezadoAcademicoAtlassian(context);
    final header = EncabezadoAcademicoAtlassian(
      controller: _scrollController,
      title: 'Datos',
      subtitle: 'Perfil y sincronización',
    );

    return ValueListenableBuilder<bool>(
      valueListenable: widget.localLoadedListenable,
      builder: (context, loaded, _) {
        return ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
          valueListenable: widget.trajectoryListenable,
          builder: (context, trajectory, _) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: !loaded
                          ? const Center(child: CircularProgressIndicator())
                          : trajectory == null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: headerHeight),
                                child: EstadoVacioAtlassian(
                                  icon: Icons.person_off_outlined,
                                  title: 'Sin datos sincronizados',
                                  message:
                                      'Conectá SAGE desde Inicio para cargar el perfil.',
                                  action: BotonAtlassian(
                                    label: 'Ir a Inicio',
                                    icon: Icons.home_rounded,
                                    primary: true,
                                    onPressed: () => widget.onNavigate(0),
                                  ),
                                ),
                              ),
                            )
                          : _ContenidoDatosAtlassian(
                              trajectory: trajectory,
                              selectedCareerListenable:
                                  widget.selectedCareerListenable,
                              onDesynchronize: widget.onDesynchronize,
                              scrollController: _scrollController,
                            ),
                    ),
                    Align(alignment: Alignment.topCenter, child: header),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ContenidoDatosAtlassian extends StatelessWidget {
  const _ContenidoDatosAtlassian({
    required this.trajectory,
    required this.selectedCareerListenable,
    required this.onDesynchronize,
    required this.scrollController,
  });

  final TrayectoriaSageLaboratorio trajectory;
  final ValueNotifier<int> selectedCareerListenable;
  final VoidCallback onDesynchronize;
  final ScrollController scrollController;

  void _openCareer(
    BuildContext context,
    CarreraTrayectoriaSageLaboratorio career,
  ) {
    Navigator.of(context).push<void>(
      rutaAtlassian<void>(
        builder: (_) => PantallaDetalleCarreraAtlassian(career: career),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = trajectory.perfil;
    final name = nombrePerfilAtlassian(profile);
    final fields = _camposPerfilPresentables(profile);
    final headerHeight = alturaEncabezadoAcademicoAtlassian(context);

    return ListView(
      key: const ValueKey('datos-contenido'),
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, headerHeight + 16, 16, 128),
      children: [
        PanelAtlassian(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RadioAtlassian.large),
                ),
                child: Text(
                  inicialesAtlassian(name),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    if ((profile.dni ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'DNI ${profile.dni}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const EtiquetaAcademicaAtlassian(
                      label: 'Sincronizado',
                      appearance: AparienciaLozengeAtlassian.success,
                      icon: Icons.cloud_done_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResumenSincronizacionAtlassian(trajectory: trajectory),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SeparadorTituloAtlassian(title: 'Perfil SAGE'),
          const SizedBox(height: 8),
          PanelAtlassian(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  _FilaDatoAtlassian(
                    label: fields[index].key,
                    value: fields[index].value,
                  ),
                  if (index != fields.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SeparadorTituloAtlassian(
          title: 'Carreras',
          subtitle: trajectory.carreras.length == 1
              ? '1 registrada'
              : '${trajectory.carreras.length} registradas',
        ),
        const SizedBox(height: 8),
        PanelAtlassian(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (
                var index = 0;
                index < trajectory.carreras.length;
                index++
              ) ...[
                ToqueMovimientoApp(
                  child: InkWell(
                    onTap: () {
                      selectedCareerListenable.value = index;
                      _openCareer(context, trajectory.carreras[index]);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                RadioAtlassian.medium,
                              ),
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombreCarreraAtlassian(
                                    trajectory.carreras[index].nombre,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${trajectory.carreras[index].materias.length} '
                                  '${trajectory.carreras[index].materias.length == 1 ? 'materia' : 'materias'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (index != trajectory.carreras.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SeparadorTituloAtlassian(title: 'Almacenamiento local'),
        const SizedBox(height: 8),
        MensajeAcademicoAtlassian(
          title: 'Trayectoria guardada',
          message:
              'La copia local contiene ${trajectory.totalMaterias} '
              '${trajectory.totalMaterias == 1 ? 'materia' : 'materias'}.',
          appearance: AparienciaLozengeAtlassian.brand,
          icon: Icons.storage_outlined,
          action: BotonAtlassian(
            label: 'Desincronizar',
            icon: Icons.delete_outline_rounded,
            danger: true,
            onPressed: onDesynchronize,
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _ResumenSincronizacionAtlassian extends StatelessWidget {
  const _ResumenSincronizacionAtlassian({required this.trajectory});

  final TrayectoriaSageLaboratorio trajectory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        final metrics = [
          MetricaAcademicaAtlassian(
            label: 'Carreras',
            value: '${trajectory.carreras.length}',
            icon: Icons.school_outlined,
            appearance: AparienciaLozengeAtlassian.brand,
          ),
          MetricaAcademicaAtlassian(
            label: 'Materias',
            value: '${trajectory.totalMaterias}',
            icon: Icons.menu_book_outlined,
            appearance: AparienciaLozengeAtlassian.neutral,
          ),
          _MetricaFechaDatosAtlassian(
            label: 'Capturada',
            value: formatoFechaAtlassian(trajectory.capturadaEn),
            icon: Icons.history_rounded,
            appearance: AparienciaLozengeAtlassian.discovery,
          ),
          _MetricaFechaDatosAtlassian(
            label: 'Sincronizada',
            value: textoSincronizacionAtlassian(trajectory.sincronizadaEn),
            icon: Icons.cloud_done_outlined,
            appearance: AparienciaLozengeAtlassian.success,
          ),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics) SizedBox(width: width, child: metric),
          ],
        );
      },
    );
  }
}

class _MetricaFechaDatosAtlassian extends StatelessWidget {
  const _MetricaFechaDatosAtlassian({
    required this.label,
    required this.value,
    required this.icon,
    required this.appearance,
  });
  final String label;
  final String value;
  final IconData icon;
  final AparienciaLozengeAtlassian appearance;

  @override
  Widget build(BuildContext context) => PanelAtlassian(
    ordenEntrada: 2,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 10),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _FilaDatoAtlassian extends StatelessWidget {
  const _FilaDatoAtlassian({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      FilaDatoAcademicoAtlassian(label: label, value: value);
}

class PantallaDetalleCarreraAtlassian extends StatelessWidget {
  const PantallaDetalleCarreraAtlassian({super.key, required this.career});

  final CarreraTrayectoriaSageLaboratorio career;

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final activa = TrayectoriaActivaAtlassian.de(context);
    final career = activa == null
        ? this.career
        : activa.buscarCarrera(this.career);
    if (career == null) {
      return Scaffold(
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              EncabezadoPaginaAtlassian(
                title: 'Datos de carrera',
                leading: BotonIconoAtlassian(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Expanded(
                child: EstadoVacioAtlassian(
                  icon: Icons.sync_rounded,
                  title: 'Carrera no disponible',
                  message:
                      'Esta carrera ya no está en la trayectoria sincronizada.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            EncabezadoPaginaAtlassian(
              title: 'Datos de carrera',
              subtitle: nombreCarreraAtlassian(career.nombre),
              leading: BotonIconoAtlassian(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  PanelAtlassian(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EtiquetaAcademicaAtlassian(
                          label: career.estado ?? 'Carrera',
                          appearance: AparienciaLozengeAtlassian.brand,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nombreCarreraAtlassian(career.nombre),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (career.institucion.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            career.institucion,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PanelAtlassian(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _FilaDatoAtlassian(
                          label: 'Materias',
                          value: '${career.materias.length}',
                        ),
                        const Divider(height: 1),
                        _FilaDatoAtlassian(
                          label: 'Aprobadas',
                          value: '${career.aprobadas}',
                        ),
                        const Divider(height: 1),
                        _FilaDatoAtlassian(
                          label: 'Regulares',
                          value: '${career.regulares}',
                        ),
                        const Divider(height: 1),
                        _FilaDatoAtlassian(
                          label: 'Cursando',
                          value: '${career.cursando}',
                        ),
                        if (career.anioInicio != null) ...[
                          const Divider(height: 1),
                          _FilaDatoAtlassian(
                            label: 'Inicio',
                            value: '${career.anioInicio}',
                          ),
                        ],
                        if ((career.estadoInscripcion ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const Divider(height: 1),
                          _FilaDatoAtlassian(
                            label: 'Inscripción',
                            value: career.estadoInscripcion!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<MapEntry<String, String>> _camposPerfilPresentables(
  PerfilTrayectoriaSageLaboratorio profile,
) {
  final result = <MapEntry<String, String>>[];
  final seen = <String>{};

  for (final entry in profile.campos.entries) {
    final value = entry.value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty) continue;
    final label = _etiquetaCampoPerfil(entry.key);
    final normalizedValue = _normalizarCampoPerfil(value);
    if (label == 'Estudiante' &&
        const {
          'dni',
          'alumno',
          'estudiante',
          'perfil',
        }.contains(normalizedValue)) {
      continue;
    }
    final signature = '${label.toLowerCase()}|${value.toLowerCase()}';
    if (!seen.add(signature)) continue;
    result.add(MapEntry<String, String>(label, value));
  }

  const priority = <String, int>{
    'Tipo de documento': 0,
    'DNI': 1,
    'Documento': 2,
    'Nombre completo': 3,
    'Nombre': 4,
    'Apellido': 5,
    'Teléfono': 6,
    'Celular': 7,
    'Fecha de nacimiento': 8,
    'Localidad': 9,
    'Domicilio': 10,
    'Dirección': 11,
    'Correo electrónico': 12,
  };
  result.sort((first, second) {
    final firstPriority = priority[first.key] ?? 100;
    final secondPriority = priority[second.key] ?? 100;
    final byPriority = firstPriority.compareTo(secondPriority);
    return byPriority != 0 ? byPriority : first.key.compareTo(second.key);
  });
  return result;
}

String _etiquetaCampoPerfil(String raw) {
  final segments = raw
      .split(RegExp(r'[.:/]+'))
      .where((segment) => segment.trim().isNotEmpty)
      .toList(growable: false);
  var source = segments.isEmpty ? raw : segments.last;
  source = source
      .replaceFirst(
        RegExp(r'^(tb|tbl|tabla)[_-]?alumnos?[_-]?', caseSensitive: false),
        '',
      )
      .replaceFirst(
        RegExp(
          r'^(tv|txt|lbl|label|col|campo|dato|ctl|td|th)[_-]+',
          caseSensitive: false,
        ),
        '',
      );
  final key = _normalizarCampoPerfil(source)
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  const labels = <String, String>{
    'tipo': 'Tipo de documento',
    'tipo documento': 'Tipo de documento',
    'tipo de documento': 'Tipo de documento',
    'tipo medio documento': 'Tipo de documento',
    'tipo de medio documento': 'Tipo de documento',
    'tipodoc': 'Tipo de documento',
    'tipomediodocumento': 'Tipo de documento',
    'alumno': 'Estudiante',
    'alumnos': 'Estudiante',
    'estudiante': 'Estudiante',
    'nombre': 'Nombre',
    'nombres': 'Nombre',
    'apellido': 'Apellido',
    'apellidos': 'Apellido',
    'apenom': 'Nombre completo',
    'ape nom': 'Nombre completo',
    'ape nom 2': 'Nombre completo',
    'apenom 2': 'Nombre completo',
    'apenom2': 'Nombre completo',
    'dni': 'DNI',
    'nro doc': 'DNI',
    'nrodoc': 'DNI',
    'numero documento': 'DNI',
    'numero de documento': 'DNI',
    'documento': 'Documento',
    'cuil': 'CUIL',
    'telefono': 'Teléfono',
    'tel': 'Teléfono',
    'telefono celular': 'Celular',
    'celular': 'Celular',
    'mail': 'Correo electrónico',
    'email': 'Correo electrónico',
    'correo': 'Correo electrónico',
    'correo electronico': 'Correo electrónico',
    'fecha nacimiento': 'Fecha de nacimiento',
    'fecha de nacimiento': 'Fecha de nacimiento',
    'fechanacimiento': 'Fecha de nacimiento',
    'fechanac': 'Fecha de nacimiento',
    'nacimiento': 'Fecha de nacimiento',
    'domicilio': 'Domicilio',
    'direccion': 'Dirección',
    'localidad': 'Localidad',
    'provincia': 'Provincia',
    'legajo': 'Legajo',
    'sexo': 'Sexo',
  };
  final mapped = labels[key];
  if (mapped != null) return mapped;
  if (key.isEmpty) return 'Dato';
  return key
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _normalizarCampoPerfil(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
