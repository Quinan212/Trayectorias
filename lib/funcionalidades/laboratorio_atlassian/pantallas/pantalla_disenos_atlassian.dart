import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/datos_catalogo.dart';
import '../../../datos/cargador_fuente_html.dart';
import '../../../modelos/contenido_curricular.dart';
import '../../../modelos/materia.dart';
import '../../curriculum/proveedores/proveedores_curriculum.dart';
import '../componentes/componentes_atlassian.dart';
import '../tema/tema_atlassian.dart';

class PantallaDisenosAtlassian extends ConsumerStatefulWidget {
  const PantallaDisenosAtlassian({
    super.key,
    this.initialCareerId,
    this.initialQuery,
  });

  final String? initialCareerId;
  final String? initialQuery;

  @override
  ConsumerState<PantallaDisenosAtlassian> createState() =>
      _PantallaDisenosAtlassianState();
}

class _PantallaDisenosAtlassianState
    extends ConsumerState<PantallaDisenosAtlassian> {
  final TextEditingController _searchController = TextEditingController();
  late final List<CareerInfo> _careers;
  late CareerInfo _career;
  late Future<DatosPlan> _future;
  int? _year;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _careers = kCareers.where((item) => !item.hidden).toList(growable: false);
    final requestedCareer = widget.initialCareerId?.trim();
    _career = _careers.firstWhere(
      (item) => item.id == requestedCareer,
      orElse: () => _careers.firstWhere(
        (item) => item.id == 'historia',
        orElse: () => _careers.first,
      ),
    );
    _query = widget.initialQuery?.trim() ?? '';
    _searchController.text = _query;
    _future = cargarPlanDesdeAssetHtml(_career.assetHtml);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeCareer(CareerInfo career) {
    setState(() {
      _career = career;
      _year = null;
      _query = '';
      _searchController.clear();
      _future = cargarPlanDesdeAssetHtml(career.assetHtml);
    });
  }

  Future<void> _chooseCareer() async {
    final selected = await mostrarHojaAtlassian<CareerInfo>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seleccionar carrera',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _careers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final career = _careers[index];
                    return PanelAtlassian(
                      selected: career.id == _career.id,
                      onTap: () => Navigator.of(sheetContext).pop(career),
                      child: Row(
                        children: [
                          Icon(
                            career.id == _career.id
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: career.id == _career.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              career.nombre,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) _changeCareer(selected);
  }

  Future<void> _chooseYear(List<int> years) async {
    final selected = await mostrarHojaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar por año',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              PanelAtlassian(
                selected: _year == null,
                onTap: () => Navigator.of(sheetContext).pop('todos'),
                child: const Text('Todos los años'),
              ),
              const SizedBox(height: 8),
              for (final year in years) ...[
                PanelAtlassian(
                  selected: _year == year,
                  onTap: () => Navigator.of(sheetContext).pop('$year'),
                  child: Text('$year° año'),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _year = selected == 'todos' ? null : int.parse(selected));
  }

  List<Materia> _filter(List<Materia> subjects) {
    final query = _normalize(_query);
    final filtered = subjects.where((subject) {
      if (_year != null && subject.anio != _year) return false;
      if (query.isEmpty) return true;
      return _normalize(
        '${subject.displayNombre} ${subject.codigo} ${subject.tipo} ${subject.formato}',
      ).contains(query);
    }).toList();
    filtered.sort((first, second) {
      final byYear = first.anio.compareTo(second.anio);
      if (byYear != 0) return byYear;
      return first.displayNombre.compareTo(second.displayNombre);
    });
    return filtered;
  }

  void _openDetail(Materia subject, ContenidoCurricular? content) {
    Navigator.of(context).push<void>(
      rutaAtlassian<void>(
        builder: (_) => PantallaDetalleDisenoAtlassian(
          subject: subject,
          content: content,
          careerName: _career.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsync = ref.watch(proveedorContenidosCurriculares);
    final contents = contentsAsync.value ?? const <ContenidoCurricular>[];
    final contentById = <String, ContenidoCurricular>{
      for (final item in contents) item.id: item,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          EncabezadoPaginaAtlassian(
            title: 'Diseños curriculares',
            subtitle: _career.nombre,
            leading: BotonIconoAtlassian(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: () => volverPantallaAtlassian(context),
            ),
          ),
          Expanded(
            child: FutureBuilder<DatosPlan>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done ||
                    contentsAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || contentsAsync.hasError) {
                  return EstadoVacioAtlassian(
                    icon: Icons.error_outline_rounded,
                    title: 'No se pudo cargar el diseño',
                    message: snapshot.hasError
                        ? snapshot.error.toString()
                        : contentsAsync.error.toString(),
                  );
                }
                final plan = snapshot.data!;
                final filtered = _filter(plan.materias);
                final years =
                    plan.materias.map((item) => item.anio).toSet().toList()
                      ..sort();
                final grouped = <int, List<Materia>>{};
                for (final subject in filtered) {
                  grouped
                      .putIfAbsent(subject.anio, () => <Materia>[])
                      .add(subject);
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    120 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    PanelAtlassian(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CampoBusquedaAtlassian(
                            controller: _searchController,
                            hintText: 'Buscar materia o contenido',
                            onChanged: (value) =>
                                setState(() => _query = value),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final careerSelector = SelectorAtlassian(
                                label: 'Carrera',
                                value: _career.nombre,
                                icon: Icons.school_outlined,
                                onTap: _chooseCareer,
                              );
                              final yearSelector = SelectorAtlassian(
                                label: 'Año',
                                value: _year == null ? 'Todos' : '$_year° año',
                                icon: Icons.calendar_view_month_outlined,
                                onTap: () => _chooseYear(years),
                              );
                              if (constraints.maxWidth >= 620) {
                                return Row(
                                  children: [
                                    Expanded(child: careerSelector),
                                    const SizedBox(width: 10),
                                    SizedBox(width: 190, child: yearSelector),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  careerSelector,
                                  const SizedBox(height: 10),
                                  yearSelector,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    MensajeSeccionAtlassian(
                      title: '${filtered.length} materias visibles',
                      message:
                          '${contentById.length} contenidos desarrollados dentro de la aplicación.',
                      icon: Icons.library_books_outlined,
                    ),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      const EstadoVacioAtlassian(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        message: 'Revisá la búsqueda o el filtro de año.',
                      )
                    else
                      for (final entry in grouped.entries) ...[
                        SeparadorTituloAtlassian(
                          title: '${entry.key}° año',
                          subtitle: '${entry.value.length} materias',
                        ),
                        const SizedBox(height: 8),
                        PanelAtlassian(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < entry.value.length;
                                index++
                              ) ...[
                                _DesignSubjectRowAtlassian(
                                  subject: entry.value[index],
                                  available: contentById.containsKey(
                                    entry.value[index].id,
                                  ),
                                  onTap: () => _openDetail(
                                    entry.value[index],
                                    contentById[entry.value[index].id],
                                  ),
                                ),
                                if (index != entry.value.length - 1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignSubjectRowAtlassian extends StatelessWidget {
  const _DesignSubjectRowAtlassian({
    required this.subject,
    required this.available,
    required this.onTap,
  });

  final Materia subject;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ToqueMovimientoApp(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RadioAtlassian.medium),
                ),
                child: Text(
                  '${subject.anio}°',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.displayNombre,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.formato.isEmpty ? subject.tipo : subject.formato,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LozengeAtlassian(
                label: available ? 'Disponible' : 'Pendiente',
                appearance: available
                    ? AparienciaLozengeAtlassian.success
                    : AparienciaLozengeAtlassian.neutral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaDetalleDisenoAtlassian extends StatelessWidget {
  const PantallaDetalleDisenoAtlassian({
    super.key,
    required this.subject,
    required this.content,
    required this.careerName,
  });

  final Materia subject;
  final ContenidoCurricular? content;
  final String careerName;

  @override
  Widget build(BuildContext context) {
    final item = content;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          EncabezadoPaginaAtlassian(
            title: subject.displayNombre,
            subtitle: '$careerName · ${subject.anio}° año',
            centerTitle: true,
            leading: BotonIconoAtlassian(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: () => volverPantallaAtlassian(context),
            ),
          ),
          Expanded(
            child: item == null
                ? const EstadoVacioAtlassian(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Contenido en preparación',
                    message:
                        'La materia está incluida en el plan, pero su desarrollo curricular todavía no fue cargado.',
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      120 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _ResumenDisenoAtlassian(item: item),
                      const SizedBox(height: 12),
                      _DesignSectionAtlassian(
                        title: 'Marco orientador',
                        icon: Icons.explore_outlined,
                        child: Text(
                          item.marcoOrientador,
                          textAlign: TextAlign.justify,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DesignSectionAtlassian(
                        title: 'Ejes de contenidos',
                        icon: Icons.account_tree_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (
                              var index = 0;
                              index < item.ejes.length;
                              index++
                            ) ...[
                              Text(
                                item.ejes[index].titulo,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.ejes[index].descripcion,
                                textAlign: TextAlign.justify,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                              ),
                              if (index != item.ejes.length - 1) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DesignSectionAtlassian(
                        title: 'Bibliografía',
                        icon: Icons.local_library_outlined,
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < item.bibliografia.length;
                              index++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${index + 1}.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.bibliografia[index],
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResumenDisenoAtlassian extends StatelessWidget {
  const _ResumenDisenoAtlassian({required this.item});

  final ContenidoCurricular item;

  @override
  Widget build(BuildContext context) {
    final carga = _descomponerCargaHoraria(item.cargaHoraria);
    return PanelAtlassian(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _DatoCabeceraDisenoAtlassian(
            icon: Icons.dashboard_customize_outlined,
            label: 'Formato',
            value: _limpiarDatoDiseno(item.formato),
          ),
          const Divider(height: 1),
          _DatoCabeceraDisenoAtlassian(
            icon: Icons.schedule_outlined,
            label: 'Horas cátedra por semana',
            value: carga.horasCatedra,
          ),
          const Divider(height: 1),
          _DatoCabeceraDisenoAtlassian(
            icon: Icons.timer_outlined,
            label: 'Equivalencia en horas reloj por semana',
            value: carga.horasReloj,
          ),
          if (carga.detalleAdicional.isNotEmpty) ...[
            const Divider(height: 1),
            _DatoCabeceraDisenoAtlassian(
              icon: Icons.notes_rounded,
              label: 'Distribución y observaciones',
              value: carga.detalleAdicional,
              justify: true,
            ),
          ],
          const Divider(height: 1),
          _DatoCabeceraDisenoAtlassian(
            icon: Icons.event_repeat_outlined,
            label: 'Régimen de cursado',
            value: _limpiarDatoDiseno(item.regimenCursado),
          ),
        ],
      ),
    );
  }
}

class _DatoCabeceraDisenoAtlassian extends StatelessWidget {
  const _DatoCabeceraDisenoAtlassian({
    required this.icon,
    required this.label,
    required this.value,
    this.justify = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool justify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(RadioAtlassian.medium),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : scheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Sin información' : value,
                  textAlign: justify ? TextAlign.justify : TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _limpiarDatoDiseno(String value) => value
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceFirst(RegExp(r'\.$'), '');

class _CargaHorariaDiseno {
  const _CargaHorariaDiseno({
    required this.horasCatedra,
    required this.horasReloj,
    required this.detalleAdicional,
  });

  final String horasCatedra;
  final String horasReloj;
  final String detalleAdicional;
}

_CargaHorariaDiseno _descomponerCargaHoraria(String value) {
  final limpio = _limpiarDatoDiseno(value)
      .replaceAll(RegExp(r'\bcátedras\b', caseSensitive: false), 'cátedra')
      .replaceAll(RegExp(r'(\d)horas', caseSensitive: false), r'$1 horas')
      .replaceAll(
        RegExp(r'horas?\.\s+reloj', caseSensitive: false),
        'horas reloj',
      )
      .replaceAll(RegExp(r'\bmin\.?(?=\s|$)', caseSensitive: false), 'minutos')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final catedra = RegExp(
    r'(\d+)\s+horas?\s+cátedra',
    caseSensitive: false,
  ).firstMatch(limpio);
  final reloj = RegExp(
    r'(\d+)\s+horas?(?:\s+(\d+)\s+(?:minutos?|min))?\s*\.?\s*reloj',
    caseSensitive: false,
  ).firstMatch(limpio);

  final horasCatedra = catedra == null
      ? 'Sin información diferenciada'
      : _formatearHorasCatedra(int.parse(catedra.group(1)!));
  final horasReloj = reloj == null
      ? 'Sin información diferenciada'
      : _formatearHorasReloj(
          int.parse(reloj.group(1)!),
          reloj.group(2) == null ? null : int.parse(reloj.group(2)!),
        );

  var detalle = limpio;
  if (catedra != null) {
    detalle = detalle.replaceFirst(catedra.group(0)!, '');
  }
  if (reloj != null) {
    detalle = detalle.replaceFirst(reloj.group(0)!, '');
  }
  detalle = detalle
      .replaceAll(
        RegExp(r'^\s*(?:semanal(?:es)?|[-·()]|\.)+\s*', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'\s*(?:-|·)\s*(?:semanal(?:es)?)?\s*', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'^\s*semanal(?:es)?\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^[().\s]+|[()\s]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return _CargaHorariaDiseno(
    horasCatedra: horasCatedra,
    horasReloj: horasReloj,
    detalleAdicional: detalle,
  );
}

String _formatearHorasCatedra(int hours) =>
    hours == 1 ? '1 hora cátedra semanal' : '$hours horas cátedra semanales';

String _formatearHorasReloj(int hours, int? minutes) {
  final partes = <String>[
    hours == 1 ? '1 hora' : '$hours horas',
    if (minutes != null && minutes > 0)
      minutes == 1 ? '1 minuto' : '$minutes minutos',
  ];
  return '${partes.join(' ')} reloj por semana';
}

class _DesignSectionAtlassian extends StatelessWidget {
  const _DesignSectionAtlassian({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

String _normalize(String value) {
  const replacements = <String, String>{
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var output = value.toLowerCase();
  replacements.forEach((key, replacement) {
    output = output.replaceAll(key, replacement);
  });
  return output.replaceAll(RegExp(r'\s+'), ' ').trim();
}
