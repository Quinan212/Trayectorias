import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../compartido/componentes/etiqueta_opcion_institucion.dart';
import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/datos_catalogo.dart';
import '../../../compartido/tema/tema_herramientas_app.dart';
import '../../../datos/cargador_fuente_html.dart';
import '../../../modelos/materia.dart';
import '../../cascada/pantalla/componentes/capa_seleccion_institucion.dart';
import '../busqueda/modelos_busqueda_atlassian.dart';
import '../componentes/componentes_academicos_app.dart';
import '../componentes/componentes_atlassian.dart';
import '../tema/tema_atlassian.dart';

const String _logoPscsCircularAsset =
    'assets/career_icons/logo_pscs_overlay.png';

bool _esInstitucionPscs(InstitutionInfo? institution) {
  if (institution == null) return false;
  return institution.id.endsWith('_pscs') ||
      institution.nombre.toLowerCase().contains(
        'profesorado superior de ciencias sociales',
      );
}

String? _assetInstitucionPlan(InstitutionInfo? institution) {
  if (_esInstitucionPscs(institution)) return _logoPscsCircularAsset;
  return institution?.iconAsset;
}

double _zoomInstitucionPlan(InstitutionInfo? institution) {
  return _esInstitucionPscs(institution) ? 1.15 : 1.0;
}

class PantallaPlanAtlassian extends StatefulWidget {
  const PantallaPlanAtlassian({
    super.key,
    required this.onSearch,
    required this.requestListenable,
  });

  final VoidCallback onSearch;
  final ValueListenable<SolicitudPlanAtlassian?> requestListenable;

  @override
  State<PantallaPlanAtlassian> createState() => _PantallaPlanAtlassianState();
}

class _PantallaPlanAtlassianState extends State<PantallaPlanAtlassian> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<CareerInfo> _careers;
  late CareerInfo _career;
  InstitutionInfo? _institution;
  late Future<DatosPlan> _future;
  int? _year;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _careers = kCareers.where((item) => !item.hidden).toList(growable: false);
    _career = _careers.firstWhere(
      (item) => item.id == 'historia',
      orElse: () => _careers.first,
    );
    final initialInstitutions = _institutionsFor(_career);
    _institution = initialInstitutions.isEmpty
        ? null
        : initialInstitutions.first;
    _future = _load(_career, _institution);
    widget.requestListenable.addListener(_applyExternalRequest);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyExternalRequest(),
    );
  }

  @override
  void didUpdateWidget(covariant PantallaPlanAtlassian oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestListenable == widget.requestListenable) return;
    oldWidget.requestListenable.removeListener(_applyExternalRequest);
    widget.requestListenable.addListener(_applyExternalRequest);
  }

  void _applyExternalRequest() {
    final request = widget.requestListenable.value;
    if (request == null || !mounted) return;
    CareerInfo? requestedCareer;
    final requestedId = request.careerId?.trim() ?? '';
    if (requestedId.isNotEmpty) {
      for (final item in _careers) {
        if (item.id == requestedId) {
          requestedCareer = item;
          break;
        }
      }
    }

    setState(() {
      if (requestedCareer != null && requestedCareer.id != _career.id) {
        _career = requestedCareer;
        final institutions = _institutionsFor(_career);
        _institution = institutions.isEmpty ? null : institutions.first;
        _future = _load(_career, _institution);
      }
      _year = request.year;
      if (request.query != null) {
        _query = request.query!.trim();
        _searchController.text = _query;
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      }
    });
    MovimientoApp.volverAlInicio(context, _scrollController);
  }

  @override
  void dispose() {
    widget.requestListenable.removeListener(_applyExternalRequest);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<InstitutionInfo> _institutionsFor(CareerInfo career) {
    return kInstitutions
        .where((item) => !item.hidden && item.careerId == career.id)
        .toList(growable: false);
  }

  Future<DatosPlan> _load(
    CareerInfo career,
    InstitutionInfo? institution,
  ) async {
    final base = await cargarPlanDesdeAssetHtml(career.assetHtml);
    final subjects = _applyInstitutionOverrides(
      base.materias,
      institution?.overrides ?? const <MateriaOverride>[],
    );
    final preferredUrl = institution?.downloadUrl?.trim().isNotEmpty == true
        ? institution!.downloadUrl!
        : career.downloadUrl;
    return DatosPlan(
      materias: subjects,
      pdfUrl: Uri.tryParse(preferredUrl) ?? base.pdfUrl,
    );
  }

  List<Materia> _applyInstitutionOverrides(
    List<Materia> subjects,
    List<MateriaOverride> overrides,
  ) {
    if (overrides.isEmpty) return subjects;
    final byId = <String, MateriaOverride>{
      for (final override in overrides) override.materiaId: override,
    };
    return subjects
        .map((subject) {
          final override = byId[subject.id];
          if (override == null) return subject;
          return Materia(
            id: subject.id,
            codigo: override.codigo ?? subject.codigo,
            nombre: override.nombre ?? subject.nombre,
            anio: override.anio ?? subject.anio,
            cuatri: override.cuatri ?? subject.cuatri,
            tipo: override.tipo ?? subject.tipo,
            formato: override.formato ?? subject.formato,
            correlativas: subject.correlativas,
            horas: override.horas ?? subject.horas,
            correlativasDetalladas: subject.correlativasDetalladas,
          );
        })
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load(_career, _institution));
    await _future;
  }

  void _changeCareer(CareerInfo career) {
    final institutions = _institutionsFor(career);
    setState(() {
      _career = career;
      _institution = institutions.isEmpty ? null : institutions.first;
      _year = null;
      _query = '';
      _searchController.clear();
      _future = _load(career, _institution);
    });
  }

  Future<void> _chooseCareer() async {
    final selectedId = await mostrarHojaAcademicaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seleccionar carrera',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final career in _careers) ...[
                  PanelAtlassian(
                    selected: career.id == _career.id,
                    onTap: () => Navigator.of(sheetContext).pop(career.id),
                    child: Row(
                      children: [
                        Icon(
                          career.id == _career.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: career.id == _career.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            career.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (selectedId == null || !mounted || selectedId == _career.id) return;
    final selected = _careers.firstWhere((career) => career.id == selectedId);
    _changeCareer(selected);
    final selectedInstitutions = _institutionsFor(selected);
    final institution = selectedInstitutions.isEmpty
        ? null
        : selectedInstitutions.first;
    if (institution != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showInstitutionSelectionOverlay(context, institution: institution);
      });
    }
  }

  Future<void> _chooseInstitution() async {
    final institutions = _institutionsFor(_career);
    if (institutions.isEmpty) return;
    final selectedId = await mostrarHojaAcademicaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seleccionar institución',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final institution in institutions) ...[
                  PanelAtlassian(
                    selected: institution.id == _institution?.id,
                    onTap: () => Navigator.of(sheetContext).pop(institution.id),
                    child: Row(
                      children: [
                        Icon(
                          institution.id == _institution?.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: institution.id == _institution?.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EtiquetaOpcionInstitucion(
                            institution,
                            iconSize: 38,
                            gap: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (selectedId == null || !mounted) return;
    final selected = institutions.firstWhere(
      (institution) => institution.id == selectedId,
    );
    setState(() {
      _institution = selected;
      _future = _load(_career, selected);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showInstitutionSelectionOverlay(context, institution: selected);
    });
  }

  Future<void> _showInstitutionPresentation() async {
    final institution = _institution;
    if (institution == null) return;
    showInstitutionSelectionOverlay(context, institution: institution);
  }

  Future<void> _chooseYear(List<int> years) async {
    final selected = await mostrarHojaAcademicaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtrar por año',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
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
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _year = selected == 'todos' ? null : int.parse(selected));
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _year = null;
      _query = '';
    });
  }

  List<Materia> _filter(List<Materia> source) {
    final query = _normalize(_query);
    final out = source.where((subject) {
      if (_year != null && subject.anio != _year) return false;
      if (query.isEmpty) return true;
      return _normalize(
        '${subject.displayNombre} ${subject.codigo} ${subject.tipo} ${subject.formato}',
      ).contains(query);
    }).toList();
    out.sort((first, second) {
      final byYear = first.anio.compareTo(second.anio);
      if (byYear != 0) return byYear;
      final byTerm = (first.cuatri ?? 0).compareTo(second.cuatri ?? 0);
      if (byTerm != 0) return byTerm;
      return first.displayNombre.compareTo(second.displayNombre);
    });
    return out;
  }

  void _openDetail(Materia subject, List<Materia> all) {
    Navigator.of(context).push<void>(
      rutaAtlassian<void>(
        builder: (_) => PantallaDetallePlanAtlassian(
          subject: subject,
          allSubjects: all,
          careerName: _career.nombre,
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, Uri? uri) async {
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el diseño curricular.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final headerHeight = alturaEncabezadoAcademicoAtlassian(context);
    final header = EncabezadoAcademicoAtlassian(
      controller: _scrollController,
      title: 'Plan completo',
      subtitle: _career.nombre,
      actions: [
        BotonIconoAtlassian(
          icon: Icons.refresh_rounded,
          tooltip: 'Recargar plan',
          onPressed: () => unawaited(_refresh()),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<DatosPlan>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: headerHeight),
                        child: EstadoVacioAtlassian(
                          icon: Icons.error_outline_rounded,
                          title: 'No se pudo cargar el plan',
                          message: snapshot.error.toString(),
                          action: BotonAtlassian(
                            label: 'Reintentar',
                            icon: Icons.refresh_rounded,
                            primary: true,
                            onPressed: () => unawaited(_refresh()),
                          ),
                        ),
                      ),
                    );
                  }

                  final plan = snapshot.data!;
                  final filtered = _filter(plan.materias);
                  final years =
                      plan.materias.map((item) => item.anio).toSet().toList()
                        ..sort();
                  final groups = <int, List<Materia>>{};
                  for (final subject in filtered) {
                    groups
                        .putIfAbsent(subject.anio, () => <Materia>[])
                        .add(subject);
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      key: const ValueKey('plan-contenido'),
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        headerHeight + 16,
                        16,
                        128,
                      ),
                      children: [
                        _FiltrosPlanAtlassian(
                          selectedCareer: _career,
                          selectedInstitution: _institution,
                          years: years,
                          selectedYear: _year,
                          searchController: _searchController,
                          onChooseCareer: _chooseCareer,
                          onChooseInstitution: _chooseInstitution,
                          onChooseYear: () => _chooseYear(years),
                          onSearchChanged: (value) =>
                              setState(() => _query = value),
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          onResetFilters: _resetFilters,
                        ),
                        const SizedBox(height: 16),
                        _ContextoPlanAtlassian(
                          career: _career,
                          institution: _institution,
                          subjects: plan.materias,
                          pdfUrl: plan.pdfUrl,
                          onOpenPdf: plan.pdfUrl == null
                              ? null
                              : () => unawaited(_openPdf(context, plan.pdfUrl)),
                          onOpenPresentation: _institution == null
                              ? null
                              : () => unawaited(_showInstitutionPresentation()),
                        ),
                        const SizedBox(height: 22),
                        if (filtered.isEmpty)
                          const EstadoVacioAtlassian(
                            icon: Icons.search_off_rounded,
                            title: 'Sin resultados',
                            message: 'Revisá la búsqueda o el filtro de año.',
                          )
                        else
                          for (final entry in groups.entries) ...[
                            SeparadorTituloAtlassian(
                              title: '${entry.key}° año',
                              subtitle: '${entry.value.length} materias',
                            ),
                            const SizedBox(height: 10),
                            _TiraMateriasPlanAtlassian(
                              key: ValueKey((
                                _career.id,
                                _institution?.id,
                                _year,
                                _query,
                                entry.key,
                              )),
                              subjects: entry.value,
                              onOpen: (subject) =>
                                  _openDetail(subject, plan.materias),
                            ),
                            const SizedBox(height: 22),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(alignment: Alignment.topCenter, child: header),
          ],
        ),
      ),
    );
  }
}

class _FiltrosPlanAtlassian extends StatelessWidget {
  const _FiltrosPlanAtlassian({
    required this.selectedCareer,
    required this.selectedInstitution,
    required this.years,
    required this.selectedYear,
    required this.searchController,
    required this.onChooseCareer,
    required this.onChooseInstitution,
    required this.onChooseYear,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onResetFilters,
  });

  final CareerInfo selectedCareer;
  final InstitutionInfo? selectedInstitution;
  final List<int> years;
  final int? selectedYear;
  final TextEditingController searchController;
  final VoidCallback onChooseCareer;
  final VoidCallback onChooseInstitution;
  final VoidCallback onChooseYear;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Explorar el plan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: onResetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Restablecer'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CampoBusquedaAtlassian(
            controller: searchController,
            hintText: 'Buscar materia o código',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final careerField = _SelectorIdentidadPlanAtlassian(
                label: 'Carrera',
                value: selectedCareer.nombre,
                fallbackIcon: Icons.school_outlined,
                showLeading: false,
                onTap: onChooseCareer,
              );
              final institutionField = _SelectorIdentidadPlanAtlassian(
                label: 'Institución',
                value: selectedInstitution?.nombre ?? 'Sin institución',
                assetPath: _assetInstitucionPlan(selectedInstitution),
                imageZoom: _zoomInstitucionPlan(selectedInstitution),
                fallbackIcon: Icons.domain_outlined,
                onTap: onChooseInstitution,
              );
              final yearField = ToqueMovimientoApp(
                child: SelectorAtlassian(
                  label: 'Año',
                  value: selectedYear == null ? 'Todos' : '$selectedYear° año',
                  icon: Icons.calendar_view_month_outlined,
                  onTap: years.isEmpty ? null : onChooseYear,
                  enabled: years.isNotEmpty,
                ),
              );

              if (constraints.maxWidth >= 760) {
                return Row(
                  children: [
                    Expanded(child: careerField),
                    const SizedBox(width: 10),
                    Expanded(child: institutionField),
                    const SizedBox(width: 10),
                    SizedBox(width: 170, child: yearField),
                  ],
                );
              }
              return Column(
                children: [
                  careerField,
                  const SizedBox(height: 10),
                  institutionField,
                  const SizedBox(height: 10),
                  yearField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectorIdentidadPlanAtlassian extends StatelessWidget {
  const _SelectorIdentidadPlanAtlassian({
    required this.label,
    required this.value,
    required this.fallbackIcon,
    required this.onTap,
    this.assetPath,
    this.imageZoom = 1.0,
    this.showLeading = true,
  });

  final String label;
  final String value;
  final String? assetPath;
  final double imageZoom;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool showLeading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToqueMovimientoApp(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(RadioAtlassian.medium),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              if (showLeading) ...[
                _LogoPlanAtlassian(
                  assetPath: assetPath,
                  fallbackIcon: fallbackIcon,
                  size: 36,
                  zoom: imageZoom,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextoPlanAtlassian extends StatelessWidget {
  const _ContextoPlanAtlassian({
    required this.career,
    required this.institution,
    required this.subjects,
    required this.pdfUrl,
    required this.onOpenPdf,
    required this.onOpenPresentation,
  });

  final CareerInfo career;
  final InstitutionInfo? institution;
  final List<Materia> subjects;
  final Uri? pdfUrl;
  final VoidCallback? onOpenPdf;
  final VoidCallback? onOpenPresentation;

  @override
  Widget build(BuildContext context) {
    final years = subjects.map((item) => item.anio).toSet().length;
    final scheme = Theme.of(context).colorScheme;
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoPlanAtlassian(
                assetPath: _assetInstitucionPlan(institution),
                fallbackIcon: Icons.account_balance_outlined,
                size: 54,
                zoom: _zoomInstitucionPlan(institution),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.nombre,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      institution?.nombre ?? 'Institución sin seleccionar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas =
                  constraints.maxWidth >= 300 &&
                      MediaQuery.textScalerOf(context).scale(12) <= 17
                  ? 3
                  : 2;
              final ancho =
                  (constraints.maxWidth - (columnas - 1) * 12) / columnas;
              final metricas = [
                ('Materias', '${subjects.length}'),
                ('Años', '$years'),
                (
                  'Con correlativas',
                  '${subjects.where((item) => item.correlativas.isNotEmpty).length}',
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final metrica in metricas)
                    SizedBox(
                      width: ancho,
                      child: _DatoResumenPlan(
                        label: metrica.$1,
                        value: metrica.$2,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.outlineVariant),
                ),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onOpenPresentation != null)
                  BotonAtlassian(
                    label: 'Ver presentación',
                    icon: Icons.play_circle_outline_rounded,
                    onPressed: onOpenPresentation,
                  ),
                if (pdfUrl != null)
                  BotonAtlassian(
                    label: 'Abrir diseño curricular',
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: onOpenPdf,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPlanAtlassian extends StatelessWidget {
  const _LogoPlanAtlassian({
    required this.assetPath,
    required this.fallbackIcon,
    required this.size,
    this.zoom = 1.0,
  });

  final String? assetPath;
  final IconData fallbackIcon;
  final double size;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: scheme.onPrimaryContainer,
        size: size * 0.52,
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: assetPath == null
          ? fallback
          : Transform.scale(
              scale: zoom,
              child: Image.asset(
                assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

class _DatoResumenPlan extends StatelessWidget {
  const _DatoResumenPlan({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: MediaQuery.disableAnimationsOf(context)
                ? double.parse(value)
                : 0,
            end: double.parse(value),
          ),
          duration: MovimientoApp.duracion(context, MovimientoApp.entrada),
          curve: MovimientoApp.curva,
          builder: (context, number, _) => Text(
            number.round().toString(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TiraMateriasPlanAtlassian extends StatelessWidget {
  const _TiraMateriasPlanAtlassian({
    super.key,
    required this.subjects,
    required this.onOpen,
  });

  final List<Materia> subjects;
  final ValueChanged<Materia> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? 320.0
            : (constraints.maxWidth * 0.78).clamp(250.0, 310.0).toDouble();
        return _AutoScrollingHorizontalStripAtlassian(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < subjects.length; index++) ...[
                SizedBox(
                  width: cardWidth,
                  child: _TarjetaMateriaPlanAtlassian(
                    ordenEntrada: index,
                    subject: subjects[index],
                    onTap: () => onOpen(subjects[index]),
                  ),
                ),
                if (index < subjects.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AutoScrollingHorizontalStripAtlassian extends StatefulWidget {
  const _AutoScrollingHorizontalStripAtlassian({required this.child});

  final Widget child;

  @override
  State<_AutoScrollingHorizontalStripAtlassian> createState() =>
      _AutoScrollingHorizontalStripAtlassianState();
}

class _AutoScrollingHorizontalStripAtlassianState
    extends State<_AutoScrollingHorizontalStripAtlassian> {
  final ScrollController _controller = ScrollController();
  bool _leadingFade = false;
  bool _trailingFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFades());
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFades);
    _controller.dispose();
    super.dispose();
  }

  void _syncFades() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final leading = position.pixels > 2;
    final trailing = position.pixels < position.maxScrollExtent - 2;
    if (leading == _leadingFade && trailing == _trailingFade) return;
    if (!mounted) return;
    setState(() {
      _leadingFade = leading;
      _trailingFade = trailing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    const fadeWidth = 30.0;
    return ClipRect(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
          if (_leadingFade)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: fadeWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [background, background.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          if (_trailingFade)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: fadeWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [background, background.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaMateriaPlanAtlassian extends StatelessWidget {
  const _TarjetaMateriaPlanAtlassian({
    required this.subject,
    required this.onTap,
    this.ordenEntrada = 0,
  });

  final Materia subject;
  final VoidCallback onTap;
  final int ordenEntrada;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PanelAtlassian(
      ordenEntrada: ordenEntrada,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 170),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(RadioAtlassian.medium),
                  ),
                  child: Text(
                    subject.codigo.trim().isEmpty
                        ? '${subject.anio}°'
                        : subject.codigo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subject.displayNombre,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                if (subject.formato.trim().isNotEmpty)
                  EtiquetaAcademicaAtlassian(label: subject.formato),
                if (subject.cuatri != null)
                  EtiquetaAcademicaAtlassian(
                    label: '${subject.cuatri}° cuatrimestre',
                  ),
                if (subject.correlativas.isNotEmpty)
                  EtiquetaAcademicaAtlassian(
                    label: '${subject.correlativas.length} correlativas',
                    appearance: AparienciaLozengeAtlassian.brand,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PantallaDetallePlanAtlassian extends StatelessWidget {
  const PantallaDetallePlanAtlassian({
    super.key,
    required this.subject,
    required this.allSubjects,
    required this.careerName,
  });

  final Materia subject;
  final List<Materia> allSubjects;
  final String careerName;

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final byId = <String, Materia>{
      for (final item in allSubjects) item.id: item,
    };
    final prerequisites = subject.correlativas
        .map((id) => byId[id])
        .whereType<Materia>()
        .toList();
    final dependents = allSubjects
        .where((item) => item.correlativas.contains(subject.id))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            EncabezadoPaginaAtlassian(
              title: 'Detalle de materia',
              subtitle: careerName,
              centerTitle: true,
              leading: BotonIconoAtlassian(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onPressed: () => volverPantallaAtlassian(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  PanelAtlassian(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            EtiquetaAcademicaAtlassian(
                              label: '${subject.anio}° año',
                              appearance: AparienciaLozengeAtlassian.brand,
                            ),
                            EtiquetaAcademicaAtlassian(label: subject.formato),
                            if (subject.tipo.trim().isNotEmpty)
                              EtiquetaAcademicaAtlassian(label: subject.tipo),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            subject.displayNombre,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (subject.codigo.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            subject.codigo,
                            style: Theme.of(context).textTheme.bodySmall,
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
                        _DatoPlanDetalle(
                          label: 'Régimen',
                          value: subject.formato,
                        ),
                        const Divider(height: 1),
                        _DatoPlanDetalle(
                          label: 'Cuatrimestre',
                          value: subject.cuatri == null
                              ? 'Anual'
                              : '${subject.cuatri}°',
                        ),
                        if ((subject.horas ?? '').trim().isNotEmpty) ...[
                          const Divider(height: 1),
                          _DatoPlanDetalle(
                            label: 'Horas',
                            value: subject.horas!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SeparadorTituloAtlassian(
                    title: 'Correlativas',
                    subtitle: prerequisites.isEmpty
                        ? 'Sin requisitos previos'
                        : '${prerequisites.length} materias',
                  ),
                  const SizedBox(height: 8),
                  if (prerequisites.isEmpty)
                    const MensajeAcademicoAtlassian(
                      title: 'Sin correlativas',
                      message:
                          'La materia no registra requisitos previos en el plan.',
                      icon: Icons.check_circle_outline_rounded,
                      appearance: AparienciaLozengeAtlassian.success,
                    )
                  else
                    _ListaRelacionMateriasAtlassian(subjects: prerequisites),
                  const SizedBox(height: 20),
                  SeparadorTituloAtlassian(
                    title: 'Habilita',
                    subtitle: dependents.isEmpty
                        ? 'Sin materias posteriores'
                        : '${dependents.length} materias',
                  ),
                  const SizedBox(height: 8),
                  if (dependents.isEmpty)
                    const MensajeAcademicoAtlassian(
                      title: 'Sin dependencias',
                      message:
                          'Ninguna materia del plan la registra como correlativa.',
                      appearance: AparienciaLozengeAtlassian.neutral,
                      icon: Icons.info_outline_rounded,
                    )
                  else
                    _ListaRelacionMateriasAtlassian(subjects: dependents),
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

class _ListaRelacionMateriasAtlassian extends StatelessWidget {
  const _ListaRelacionMateriasAtlassian({required this.subjects});

  final List<Materia> subjects;

  @override
  Widget build(BuildContext context) {
    return PanelAtlassian(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < subjects.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final etiqueta = EtiquetaAcademicaAtlassian(
                    label: '${subjects[index].anio}° año',
                    appearance: AparienciaLozengeAtlassian.brand,
                  );
                  final nombre = Text(
                    subjects[index].displayNombre,
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                  if (constraints.maxWidth < 380 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [etiqueta, const SizedBox(height: 8), nombre],
                    );
                  }
                  return Row(
                    children: [
                      etiqueta,
                      const SizedBox(width: 10),
                      Expanded(child: nombre),
                    ],
                  );
                },
              ),
            ),
            if (index != subjects.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _DatoPlanDetalle extends StatelessWidget {
  const _DatoPlanDetalle({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      FilaDatoAcademicoAtlassian(label: label, value: value);
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
  var out = value.toLowerCase();
  replacements.forEach((key, replacement) {
    out = out.replaceAll(key, replacement);
  });
  return out.replaceAll(RegExp(r'\s+'), ' ').trim();
}
