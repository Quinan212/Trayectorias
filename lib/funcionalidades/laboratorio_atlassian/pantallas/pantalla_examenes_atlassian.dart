import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/tema/tema_herramientas_app.dart';
import '../../administrador/datos/repositorio_eventos_examen_administrador.dart';
import '../../administrador/proveedores/proveedores_acceso_administrador.dart';
import '../../examenes/modelos/evento_examen.dart';
import '../../examenes/proveedores/proveedores_examenes.dart';
import '../busqueda/modelos_busqueda_atlassian.dart';
import '../componentes/componentes_academicos_app.dart';
import '../componentes/componentes_atlassian.dart';
import '../tema/tema_atlassian.dart';
import 'utilidades_atlassian.dart';

double _espacioInferiorExamenes(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 720 || size.width > size.height ? 24 : 128;
}

class _FiltroInstanciaExamenes extends StatelessWidget {
  const _FiltroInstanciaExamenes({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MovimientoApp.duracion(context, MovimientoApp.respuesta);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final option in const [
          ('todos', 'Todos', Icons.list_alt_rounded),
          ('llamados', 'Llamados', Icons.event_note_rounded),
          ('coloquios', 'Coloquios', Icons.forum_outlined),
        ])
          ToqueMovimientoApp(
            child: ChoiceChip(
              selected: value == option.$1,
              showCheckmark: false,
              avatar: Icon(
                option.$3,
                size: 18,
                color: value == option.$1
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              label: Text(option.$2),
              labelStyle: TextStyle(
                color: value == option.$1
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: scheme.surfaceContainerLow,
              selectedColor: scheme.primaryContainer,
              side: BorderSide(
                color: value == option.$1
                    ? scheme.primary
                    : scheme.outlineVariant,
                width: 1.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              chipAnimationStyle: ChipAnimationStyle(
                enableAnimation: AnimationStyle(
                  duration: duration,
                  reverseDuration: duration,
                ),
                selectAnimation: AnimationStyle(
                  duration: duration,
                  reverseDuration: duration,
                ),
              ),
              onSelected: (_) {
                if (value == option.$1) return;
                HapticFeedback.selectionClick();
                onChanged(option.$1);
              },
            ),
          ),
      ],
    );
  }
}

class PantallaExamenesAtlassian extends ConsumerStatefulWidget {
  const PantallaExamenesAtlassian({
    super.key,
    required this.onSearch,
    required this.requestListenable,
  });

  final VoidCallback onSearch;
  final ValueListenable<SolicitudExamenesAtlassian?> requestListenable;

  @override
  ConsumerState<PantallaExamenesAtlassian> createState() =>
      _PantallaExamenesAtlassianState();
}

class _PantallaExamenesAtlassianState
    extends ConsumerState<PantallaExamenesAtlassian> {
  static const _adminRepository = RepositorioEventosExamenAdministrador();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _careerId = 'historia';
  String _scope = 'todos';
  int? _year;
  String _query = '';
  bool _savingQuickControl = false;

  @override
  void initState() {
    super.initState();
    widget.requestListenable.addListener(_applyExternalRequest);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyExternalRequest(),
    );
  }

  @override
  void didUpdateWidget(covariant PantallaExamenesAtlassian oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestListenable == widget.requestListenable) return;
    oldWidget.requestListenable.removeListener(_applyExternalRequest);
    widget.requestListenable.addListener(_applyExternalRequest);
  }

  void _applyExternalRequest() {
    final request = widget.requestListenable.value;
    if (request == null || !mounted) return;
    setState(() {
      if ((request.careerId ?? '').trim().isNotEmpty) {
        _careerId = request.careerId!;
      }
      if ((request.scope ?? '').trim().isNotEmpty) {
        _scope = request.scope!;
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

  Future<void> _refresh() async {
    await ref.refresh(proveedorTodosLosExamenes.future).then<void>((_) {});
  }

  List<EventoExamen> _filter(List<EventoExamen> source) {
    final normalizedQuery = _normalize(_query);
    return source
        .where((event) {
          if (event.careerId != _careerId) return false;
          if (_year != null && event.anio != _year) return false;
          if (_scope == 'llamados' && event.instancia == 'coloquio')
            return false;
          if (_scope == 'coloquios' && event.instancia != 'coloquio')
            return false;
          if (normalizedQuery.isEmpty) return true;
          final content = _normalize(
            '${event.materia} ${event.docentes.join(' ')} ${event.division ?? ''}',
          );
          return content.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _chooseCareer() async {
    const careers = <(String, String)>[
      ('historia', 'Historia'),
      ('geografia', 'Geografía'),
      ('politica', 'Ciencia Política'),
      ('artes_visuales', 'Artes Visuales'),
      ('musica', 'Música'),
      ('fisica', 'Educación Física'),
    ];
    final selected = await mostrarHojaAcademicaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SingleChildScrollView(
        child: SafeArea(
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
                for (final career in careers) ...[
                  PanelAtlassian(
                    selected: _careerId == career.$1,
                    onTap: () => Navigator.of(sheetContext).pop(career.$1),
                    child: Row(
                      children: [
                        Icon(
                          _careerId == career.$1
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: _careerId == career.$1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            career.$2,
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
    if (selected == null || !mounted) return;
    if (selected == _careerId) return;
    setState(() {
      _careerId = selected;
      _year = null;
    });
  }

  Future<void> _chooseYear(List<int> years) async {
    final selected = await mostrarHojaAcademicaAtlassian<String>(
      context: context,
      builder: (sheetContext) => SingleChildScrollView(
        child: SafeArea(
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
      ),
    );
    if (selected == null || !mounted) return;
    final year = selected == 'todos' ? null : int.parse(selected);
    if (year == _year) return;
    setState(() => _year = year);
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _scope = 'todos';
      _year = null;
      _query = '';
    });
  }

  void _openDetail(EventoExamen event) {
    Navigator.of(context).push<void>(
      rutaAtlassian<void>(
        builder: (_) => PantallaDetalleExamenAtlassian(event: event),
      ),
    );
  }

  Future<void> _openQuickControlSheet(EventoExamen event) async {
    if (_savingQuickControl) return;
    final id = event.id?.trim() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta mesa no admite edición remota.')),
      );
      return;
    }

    final access = await ref.read(
      proveedorEstadoDispositivoAdministrador.future,
    );
    if (!mounted || !access.isAdmin) return;

    final result =
        await mostrarHojaAcademicaAtlassian<_ResultadoControlRapidoExamen>(
          context: context,
          builder: (sheetContext) =>
              _HojaControlRapidoExamenAtlassian(event: event),
        );
    if (result == null || !mounted) return;

    setState(() => _savingQuickControl = true);
    try {
      await _adminRepository.updateQuickControls(
        client: Supabase.instance.client,
        adminDeviceId: access.deviceId,
        id: id,
        currentStatus: event.estado,
        status: result.status,
        actEnabled: result.actEnabled,
        actUrl: result.actUrl,
      );
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingQuickControl = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final examsFuture = ref.watch(proveedorTodosLosExamenes.future);
    final adminAccess = ref
        .watch(proveedorEstadoDispositivoAdministrador)
        .asData
        ?.value;
    final isAdmin = adminAccess?.isAdmin == true;
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle = theme.textTheme.headlineSmall;
    final subtitleStyle = theme.textTheme.bodySmall;
    final textHeight =
        (scaler.scale(titleStyle?.fontSize ?? 24) * (titleStyle?.height ?? 1.3))
            .ceilToDouble() +
        2 +
        (scaler.scale(subtitleStyle?.fontSize ?? 12) *
                (subtitleStyle?.height ?? 1.3))
            .ceilToDouble();
    final contentHeight = textHeight + 16 <= 72 ? 72.0 : textHeight + 24;
    final headerHeight = MediaQuery.paddingOf(context).top + contentHeight;
    final actions = [
      BotonIconoAtlassian(
        icon: Icons.refresh_rounded,
        tooltip: 'Actualizar',
        onPressed: () => unawaited(_refresh()),
      ),
    ];
    final header = contentHeight > 72
        ? EncabezadoPaginaAtlassian(
            title: 'Exámenes',
            subtitle: 'Mesas, llamados y coloquios',
            centerTitle: true,
            actions: actions,
          )
        : EncabezadoSeccionAtlassianColapsable(
            scrollController: _scrollController,
            title: 'Exámenes',
            subtitle: 'Mesas, llamados y coloquios',
            actions: actions,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<List<EventoExamen>>(
                future: examsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          headerHeight + 16,
                          16,
                          _espacioInferiorExamenes(context),
                        ),
                        children: [
                          _FiltrosExamenesAtlassian(
                            careerId: _careerId,
                            scope: _scope,
                            year: _year,
                            years: const [1, 2, 3, 4],
                            searchController: _searchController,
                            onChooseCareer: () {},
                            onChooseYear: () {},
                            onScopeChanged: (_) {},
                            onSearchChanged: (_) {},
                            onClearSearch: () {},
                            onResetFilters: () {},
                          ),
                          const SizedBox(height: 16),
                          const _EsqueletoExamenesAtlassian(),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: headerHeight,
                          bottom: _espacioInferiorExamenes(context),
                        ),
                        child: EstadoVacioAtlassian(
                          icon: Icons.error_outline_rounded,
                          title: 'No se pudieron cargar los exámenes',
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

                  final all = snapshot.data ?? const <EventoExamen>[];
                  final filtered = _filter(all);
                  final years =
                      all
                          .where((event) => event.careerId == _careerId)
                          .map((event) => event.anio)
                          .whereType<int>()
                          .toSet()
                          .toList()
                        ..sort();
                  final grouped = _group(filtered);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        headerHeight + 16,
                        16,
                        _espacioInferiorExamenes(context),
                      ),
                      children: [
                        _FiltrosExamenesAtlassian(
                          careerId: _careerId,
                          scope: _scope,
                          year: _year,
                          years: years,
                          searchController: _searchController,
                          onChooseCareer: _chooseCareer,
                          onChooseYear: () => _chooseYear(years),
                          onScopeChanged: (value) {
                            setState(() => _scope = value);
                          },
                          onSearchChanged: (value) {
                            setState(() => _query = value);
                          },
                          onClearSearch: _clearSearch,
                          onResetFilters: _resetFilters,
                        ),
                        const SizedBox(height: 16),
                        _ResumenExamenesAtlassian(events: filtered),
                        const SizedBox(height: 20),
                        if (filtered.isEmpty)
                          const EstadoVacioAtlassian(
                            icon: Icons.event_busy_rounded,
                            title: 'Sin resultados',
                            message: 'Revisá la carrera, el año o los filtros.',
                          )
                        else
                          for (final entry in grouped.entries) ...[
                            SeparadorTituloAtlassian(
                              title: entry.key,
                              subtitle: '${entry.value.length} registros',
                            ),
                            const SizedBox(height: 8),
                            PanelAtlassian(
                              key: ValueKey((
                                _careerId,
                                _scope,
                                _year,
                                entry.key,
                              )),
                              ordenEntrada: 1,
                              radius: 18,
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < entry.value.length;
                                    index++
                                  ) ...[
                                    _FilaExamenAtlassian(
                                      key: ValueKey(
                                        entry.value[index].id ??
                                            entry.value[index].materia,
                                      ),
                                      event: entry.value[index],
                                      onTap: () =>
                                          _openDetail(entry.value[index]),
                                      onLongPress:
                                          isAdmin && !_savingQuickControl
                                          ? () => unawaited(
                                              _openQuickControlSheet(
                                                entry.value[index],
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (index != entry.value.length - 1)
                                      const Divider(height: 1),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        const SizedBox(height: 48),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(height: headerHeight, child: header),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<EventoExamen>> _group(List<EventoExamen> events) {
    final groups = <String, List<EventoExamen>>{};
    for (final event in events) {
      final label = _instanceLabel(event.instancia);
      groups.putIfAbsent(label, () => <EventoExamen>[]).add(event);
    }
    return groups;
  }
}

class _FiltrosExamenesAtlassian extends StatelessWidget {
  const _FiltrosExamenesAtlassian({
    required this.careerId,
    required this.scope,
    required this.year,
    required this.years,
    required this.searchController,
    required this.onChooseCareer,
    required this.onChooseYear,
    required this.onScopeChanged,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onResetFilters,
  });

  final String careerId;
  final String scope;
  final int? year;
  final List<int> years;
  final TextEditingController searchController;
  final VoidCallback onChooseCareer;
  final VoidCallback onChooseYear;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onResetFilters;

  String get _careerLabel => switch (careerId) {
    'geografia' => 'Geografía',
    'politica' => 'Ciencia Política',
    'artes_visuales' => 'Artes Visuales',
    'musica' => 'Música',
    'fisica' => 'Educación Física',
    _ => 'Historia',
  };

  @override
  Widget build(BuildContext context) {
    final active =
        (year == null ? 0 : 1) +
        (scope == 'todos' ? 0 : 1) +
        (searchController.text.trim().isEmpty ? 0 : 1);
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Buscar y filtrar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (active > 0)
                TextButton.icon(
                  onPressed: onResetFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('Limpiar ($active)'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          CampoBusquedaAtlassian(
            controller: searchController,
            hintText: 'Buscar materia o docente',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final career = ToqueMovimientoApp(
                child: SelectorAtlassian(
                  label: 'Carrera',
                  value: _careerLabel,
                  icon: Icons.school_outlined,
                  onTap: onChooseCareer,
                ),
              );
              final yearField = ToqueMovimientoApp(
                habilitado: years.isNotEmpty,
                child: SelectorAtlassian(
                  label: 'Año',
                  value: year == null ? 'Todos' : '$year° año',
                  icon: Icons.calendar_view_month_outlined,
                  onTap: years.isEmpty ? null : onChooseYear,
                  enabled: years.isNotEmpty,
                ),
              );
              if (constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    Expanded(child: career),
                    const SizedBox(width: 10),
                    SizedBox(width: 190, child: yearField),
                  ],
                );
              }
              return Column(
                children: [career, const SizedBox(height: 10), yearField],
              );
            },
          ),
          const SizedBox(height: 10),
          _FiltroInstanciaExamenes(value: scope, onChanged: onScopeChanged),
        ],
      ),
    );
  }
}

class _ResumenExamenesAtlassian extends StatelessWidget {
  const _ResumenExamenesAtlassian({required this.events});

  final List<EventoExamen> events;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = events.where((event) {
      final date = event.fechaHora;
      return date != null && date.isAfter(now);
    }).length;
    final withActa = events.where((event) => event.puedeAbrirActa).length;
    final colloquiums = events
        .where((event) => event.instancia == 'coloquio')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        final metrics = [
          MetricaAcademicaAtlassian(
            label: 'Registros',
            value: '${events.length}',
            icon: Icons.list_alt_rounded,
            appearance: AparienciaLozengeAtlassian.brand,
          ),
          MetricaAcademicaAtlassian(
            label: 'Próximos',
            value: '$upcoming',
            icon: Icons.upcoming_outlined,
            appearance: AparienciaLozengeAtlassian.success,
          ),
          MetricaAcademicaAtlassian(
            label: 'Coloquios',
            value: '$colloquiums',
            icon: Icons.forum_outlined,
            appearance: AparienciaLozengeAtlassian.discovery,
          ),
          MetricaAcademicaAtlassian(
            label: 'Con acta',
            value: '$withActa',
            icon: Icons.description_outlined,
            appearance: AparienciaLozengeAtlassian.neutral,
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

class _FilaExamenAtlassian extends StatelessWidget {
  const _FilaExamenAtlassian({
    super.key,
    required this.event,
    required this.onTap,
    this.onLongPress,
  });

  final EventoExamen event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final future = event.fechaHora?.isAfter(DateTime.now()) ?? false;
    final hasStatus = event.mostrarAvisoEstado;
    final statusColor = _statusForeground(context, event.estado);

    return ToqueMovimientoApp(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: hasStatus ? _statusBackground(context, event.estado) : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasStatus
                      ? _statusIconBackground(context, event.estado)
                      : (future
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(RadioAtlassian.medium),
                ),
                child: Icon(
                  hasStatus
                      ? _statusIcon(event.estado)
                      : (future
                            ? Icons.event_available_rounded
                            : Icons.event_note_rounded),
                  color: hasStatus
                      ? statusColor
                      : (future
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary)
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.materia,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    if (hasStatus) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.mensajeEstadoEfectivo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      formatoFechaHoraAtlassian(
                        event.fechaVigente,
                        event.horaVigente,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (event.docentes.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.docentes.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hasStatus)
                          EtiquetaAcademicaAtlassian(
                            label: event.estado.etiqueta,
                            appearance: _statusAppearance(event.estado),
                          )
                        else
                          EtiquetaAcademicaAtlassian(
                            label: _shortInstanceLabel(event.instancia),
                            appearance: event.instancia == 'coloquio'
                                ? AparienciaLozengeAtlassian.discovery
                                : AparienciaLozengeAtlassian.brand,
                          ),
                        if (event.puedeAbrirActa) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_rounded,
                                size: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Con acta',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
    );
  }
}

class PantallaDetalleExamenAtlassian extends ConsumerStatefulWidget {
  const PantallaDetalleExamenAtlassian({super.key, required this.event});

  final EventoExamen event;

  @override
  ConsumerState<PantallaDetalleExamenAtlassian> createState() =>
      _PantallaDetalleExamenAtlassianState();
}

class _PantallaDetalleExamenAtlassianState
    extends ConsumerState<PantallaDetalleExamenAtlassian> {
  static const _adminRepository = RepositorioEventosExamenAdministrador();

  late EventoExamen _event;
  late final ProviderSubscription<AsyncValue<List<EventoExamen>>>
  _eventsSubscription;
  int _reloadRevision = 0;
  bool _savingDetails = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _eventsSubscription = ref.listenManual(proveedorTodosLosExamenes, (
      _,
      next,
    ) {
      final events = next.asData?.value;
      final id = _event.id?.trim() ?? '';
      if (events == null || id.isEmpty) return;
      final matches = events.where((event) => event.id == id);
      if (matches.isEmpty) {
        unawaited(_reloadCurrentEvent());
      } else {
        _reloadRevision++;
        setState(() => _event = matches.first);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _reloadRevision++;
    _eventsSubscription.close();
    super.dispose();
  }

  Future<void> _reloadCurrentEvent() async {
    final id = _event.id?.trim() ?? '';
    if (id.isEmpty || !mounted) return;
    final revision = ++_reloadRevision;
    EventoExamen? updated;
    try {
      updated = await ref.read(proveedorRepositorioExamenes).loadById(id);
    } catch (error) {
      // Un error de conexión no confirma que la mesa fue retirada.
      debugPrint('No se pudo actualizar el detalle de la mesa: $error');
      return;
    }
    if (!mounted || revision != _reloadRevision) return;
    if (updated == null || !updated.visible) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La mesa ya no está disponible.')),
      );
      return;
    }
    final effective = (updated.actaUrl?.trim().isNotEmpty ?? false)
        ? updated
        : updated.copyWith(actaUrl: _event.actaUrl);
    setState(() => _event = effective);
  }

  Future<void> _openAct() async {
    if (!_event.puedeAbrirActa) return;
    final raw = _event.actaUrl?.trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el acta.')),
      );
    }
  }

  Future<void> _openDetailEditSheet() async {
    if (_savingDetails) return;
    final id = _event.id?.trim() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta mesa no admite edición remota.')),
      );
      return;
    }

    final access = await ref.read(
      proveedorEstadoDispositivoAdministrador.future,
    );
    if (!mounted || !access.isAdmin) return;

    final result =
        await mostrarHojaAcademicaAtlassian<_ResultadoEdicionDetalleExamen>(
          context: context,
          builder: (sheetContext) =>
              _HojaEditarDetalleExamenAtlassian(event: _event),
        );
    if (result == null || !mounted) return;

    setState(() => _savingDetails = true);
    try {
      await _adminRepository.updateScheduleAndTeachers(
        client: Supabase.instance.client,
        adminDeviceId: access.deviceId,
        event: _event,
        date: result.date,
        time: result.time,
        teachers: result.teachers,
      );
      await ref.refresh(proveedorTodosLosExamenes.future).then<void>((_) {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha, hora y docentes actualizados.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      TemaHerramientasApp(builder: _contenido);

  Widget _contenido(BuildContext context) {
    final event = _event;
    final adminAccess = ref
        .watch(proveedorEstadoDispositivoAdministrador)
        .asData
        ?.value;
    final isAdmin = adminAccess?.isAdmin == true;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            EncabezadoPaginaAtlassian(
              title: 'Detalle del examen',
              subtitle: _instanceLabel(event.instancia),
              centerTitle: true,
              leading: BotonIconoAtlassian(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onPressed: () => volverPantallaAtlassian(context),
              ),
              actions: isAdmin
                  ? [
                      BotonIconoAtlassian(
                        icon: Icons.edit_calendar_rounded,
                        tooltip: 'Editar fecha, hora y docentes',
                        onPressed: _savingDetails
                            ? null
                            : () => unawaited(_openDetailEditSheet()),
                      ),
                    ]
                  : const <Widget>[],
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
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (event.mostrarAvisoEstado)
                              EtiquetaAcademicaAtlassian(
                                label: event.estado.etiqueta,
                                appearance: _statusAppearance(event.estado),
                              ),
                            EtiquetaAcademicaAtlassian(
                              label: _shortInstanceLabel(event.instancia),
                              appearance: event.instancia == 'coloquio'
                                  ? AparienciaLozengeAtlassian.discovery
                                  : AparienciaLozengeAtlassian.brand,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            event.materia,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.mostrarAvisoEstado) ...[
                    const SizedBox(height: 12),
                    _AvisoEstadoExamenAtlassian(event: event),
                  ],
                  const SizedBox(height: 12),
                  PanelAtlassian(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _DatoExamenAtlassian(
                          icon: Icons.calendar_today_outlined,
                          label: 'Fecha',
                          value: formatoFechaAtlassian(event.fechaVigente),
                        ),
                        const Divider(height: 1),
                        _DatoExamenAtlassian(
                          icon: Icons.schedule_rounded,
                          label: 'Hora',
                          value: event.horaVigente ?? 'Sin horario',
                        ),
                        if (event.tieneFechaOriginalDistinta) ...[
                          const Divider(height: 1),
                          _DatoExamenAtlassian(
                            icon: Icons.history_rounded,
                            label: 'Anterior',
                            value: formatoFechaHoraAtlassian(
                              event.fecha,
                              event.hora,
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        _DatoExamenAtlassian(
                          icon: Icons.school_outlined,
                          label: 'Año',
                          value: event.anio == null
                              ? 'Sin año'
                              : '${event.anio}°',
                        ),
                        const Divider(height: 1),
                        _DatoExamenAtlassian(
                          icon: Icons.groups_outlined,
                          label: 'Docentes',
                          value: event.docentes.isEmpty
                              ? 'Sin docentes informados'
                              : event.docentes.join(', '),
                        ),
                        if ((event.division ?? '').trim().isNotEmpty) ...[
                          const Divider(height: 1),
                          _DatoExamenAtlassian(
                            icon: Icons.badge_outlined,
                            label: 'División',
                            value: event.division!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (event.puedeAbrirActa) ...[
                    const SizedBox(height: 16),
                    BotonAtlassian(
                      label: 'Abrir acta',
                      icon: Icons.open_in_new_rounded,
                      primary: true,
                      expanded: true,
                      onPressed: () => unawaited(_openAct()),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoEdicionDetalleExamen {
  const _ResultadoEdicionDetalleExamen({
    required this.date,
    required this.time,
    required this.teachers,
  });

  final DateTime date;
  final String time;
  final List<String> teachers;
}

class _HojaEditarDetalleExamenAtlassian extends StatefulWidget {
  const _HojaEditarDetalleExamenAtlassian({required this.event});

  final EventoExamen event;

  @override
  State<_HojaEditarDetalleExamenAtlassian> createState() =>
      _HojaEditarDetalleExamenAtlassianState();
}

class _HojaEditarDetalleExamenAtlassianState
    extends State<_HojaEditarDetalleExamenAtlassian> {
  late DateTime _date;
  late TimeOfDay _time;
  late final List<TextEditingController> _teacherControllers;
  late final List<String> _preservedTeachers;

  @override
  void initState() {
    super.initState();
    _date = widget.event.fechaVigente ?? DateTime.now();
    _time = _timeOfDayFromText(widget.event.horaVigente);
    _teacherControllers = List<TextEditingController>.generate(
      3,
      (index) => TextEditingController(
        text: index < widget.event.docentes.length
            ? widget.event.docentes[index]
            : '',
      ),
    );
    _preservedTeachers = widget.event.docentes.length > 3
        ? widget.event.docentes.skip(3).toList(growable: false)
        : const <String>[];
  }

  @override
  void dispose() {
    for (final controller in _teacherControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _teachers {
    return <String>[
      ..._teacherControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty),
      ..._preservedTeachers,
    ];
  }

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:'
      '${_time.minute.toString().padLeft(2, '0')}';

  bool get _changed {
    final currentDate = widget.event.fechaVigente;
    final sameDate =
        currentDate != null &&
        currentDate.year == _date.year &&
        currentDate.month == _date.month &&
        currentDate.day == _date.day;
    final sameTime = (widget.event.horaVigente ?? '') == _timeText;
    return !sameDate ||
        !sameTime ||
        !_sameStringList(widget.event.docentes, _teachers);
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() => _date = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected == null || !mounted) return;
    setState(() => _time = selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar examen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SelectorAtlassian(
              label: 'Fecha',
              value: formatoFechaAtlassian(_date),
              icon: Icons.calendar_today_outlined,
              onTap: () => unawaited(_chooseDate()),
            ),
            const SizedBox(height: 10),
            SelectorAtlassian(
              label: 'Hora',
              value: _timeText,
              icon: Icons.schedule_rounded,
              onTap: () => unawaited(_chooseTime()),
            ),
            const SizedBox(height: 16),
            Text('Docentes', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (
              var index = 0;
              index < _teacherControllers.length;
              index++
            ) ...[
              TextField(
                controller: _teacherControllers[index],
                textCapitalization: TextCapitalization.words,
                textInputAction: index == _teacherControllers.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Docente ${index + 1}',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (index != _teacherControllers.length - 1)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: BotonAtlassian(
                    label: 'Cancelar',
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BotonAtlassian(
                    label: 'Guardar',
                    icon: Icons.save_outlined,
                    primary: true,
                    expanded: true,
                    onPressed: _changed
                        ? () => Navigator.of(context).pop(
                            _ResultadoEdicionDetalleExamen(
                              date: _date,
                              time: _timeText,
                              teachers: _teachers,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TimeOfDay _timeOfDayFromText(String? raw) {
  final parts = (raw ?? '').split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (hour == null || minute == null) return TimeOfDay.now();
  return TimeOfDay(
    hour: hour.clamp(0, 23).toInt(),
    minute: minute.clamp(0, 59).toInt(),
  );
}

bool _sameStringList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

class _ResultadoControlRapidoExamen {
  const _ResultadoControlRapidoExamen({
    required this.status,
    required this.actEnabled,
    required this.actUrl,
  });

  final EstadoEventoExamen status;
  final bool actEnabled;
  final String? actUrl;
}

class _HojaControlRapidoExamenAtlassian extends StatefulWidget {
  const _HojaControlRapidoExamenAtlassian({required this.event});

  final EventoExamen event;

  @override
  State<_HojaControlRapidoExamenAtlassian> createState() =>
      _HojaControlRapidoExamenAtlassianState();
}

class _HojaControlRapidoExamenAtlassianState
    extends State<_HojaControlRapidoExamenAtlassian> {
  late EstadoEventoExamen _status;
  late bool _actEnabled;
  late final TextEditingController _actUrlController;
  String? _actUrlError;

  @override
  void initState() {
    super.initState();
    _status = widget.event.estado;
    _actEnabled = widget.event.actaHabilitada;
    _actUrlController = TextEditingController(
      text: widget.event.actaUrl?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _actUrlController.dispose();
    super.dispose();
  }

  String get _normalizedActUrl => _actUrlController.text.trim();

  bool get _hadActUrl => widget.event.actaUrl?.trim().isNotEmpty ?? false;

  bool get _hasValidActUrl {
    final raw = _normalizedActUrl;
    if (raw.isEmpty) return false;
    final uri = Uri.tryParse(raw);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  List<EstadoEventoExamen> get _availableStatuses {
    return <EstadoEventoExamen>[
      EstadoEventoExamen.activa,
      EstadoEventoExamen.suspendida,
      EstadoEventoExamen.cancelada,
      if (widget.event.fechaReprogramada != null &&
          (widget.event.horaReprogramada?.trim().isNotEmpty ?? false))
        EstadoEventoExamen.reprogramada,
    ];
  }

  void _selectStatus(EstadoEventoExamen status) {
    setState(() {
      _status = status;
      _actUrlError = null;
      if (!_hadActUrl && _hasValidActUrl) {
        _actEnabled = true;
      }
    });
  }

  Future<void> _pasteActUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _actUrlController.text = text;
      _actUrlController.selection = TextSelection.collapsed(
        offset: _actUrlController.text.length,
      );
      _actUrlError = null;
      _actEnabled = _hasValidActUrl;
    });
  }

  void _submit() {
    final isAddingActUrl = !_hadActUrl;
    if (isAddingActUrl && _normalizedActUrl.isNotEmpty && !_hasValidActUrl) {
      setState(() {
        _actUrlError =
            'Ingresá un enlace válido que comience con http:// o https://';
      });
      return;
    }

    final actUrl = isAddingActUrl && _hasValidActUrl
        ? _normalizedActUrl
        : widget.event.actaUrl?.trim();

    Navigator.of(context).pop(
      _ResultadoControlRapidoExamen(
        status: _status,
        actEnabled: _actEnabled && (actUrl?.isNotEmpty ?? false),
        actUrl: actUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAddingActUrl = !_hadActUrl;
    final canEnableAct = _hadActUrl || _hasValidActUrl;
    final effectiveActEnabled = canEnableAct && _actEnabled;
    final originalUrl = widget.event.actaUrl?.trim() ?? '';
    final urlChanged =
        isAddingActUrl &&
        _normalizedActUrl.isNotEmpty &&
        _normalizedActUrl != originalUrl;
    final changed =
        _status != widget.event.estado ||
        effectiveActEnabled != widget.event.actaHabilitada ||
        urlChanged;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Control de la mesa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Estado', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final status in _availableStatuses) ...[
              PanelAtlassian(
                selected: _status == status,
                onTap: () => _selectStatus(status),
                child: Row(
                  children: [
                    Icon(
                      _status == status
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _status == status
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusLabel(status),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    EtiquetaAcademicaAtlassian(
                      label: status.etiqueta,
                      appearance: _statusAppearance(status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            if (isAddingActUrl)
              PanelAtlassian(
                child: TextField(
                  controller: _actUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    setState(() {
                      _actUrlError = null;
                      _actEnabled = _hasValidActUrl;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Enlace al acta',
                    hintText: 'https://...',
                    errorText: _actUrlError,
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Pegar enlace',
                      onPressed: _pasteActUrl,
                      icon: const Icon(Icons.content_paste_rounded),
                    ),
                  ),
                ),
              )
            else
              PanelAtlassian(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar acceso al acta'),
                  secondary: const Icon(Icons.description_outlined),
                  value: effectiveActEnabled,
                  onChanged: canEnableAct
                      ? (value) => setState(() => _actEnabled = value)
                      : null,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BotonAtlassian(
                    label: 'Cancelar',
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BotonAtlassian(
                    label: 'Guardar',
                    icon: Icons.save_outlined,
                    primary: true,
                    expanded: true,
                    onPressed: changed ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(EstadoEventoExamen status) {
  return switch (status) {
    EstadoEventoExamen.activa => 'Activa',
    EstadoEventoExamen.suspendida => 'Suspendida',
    EstadoEventoExamen.cancelada => 'Cancelada',
    EstadoEventoExamen.reprogramada => 'Reprogramada',
  };
}

class _AvisoEstadoExamenAtlassian extends StatelessWidget {
  const _AvisoEstadoExamenAtlassian({required this.event});

  final EventoExamen event;

  @override
  Widget build(BuildContext context) {
    final foreground = _statusForeground(context, event.estado);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusBackground(context, event.estado),
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        border: Border.all(
          color: foreground.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusIconBackground(context, event.estado),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(event.estado), color: foreground, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.tituloEstadoEfectivo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.mensajeEstadoEfectivo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
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

AparienciaLozengeAtlassian _statusAppearance(EstadoEventoExamen status) {
  return switch (status) {
    EstadoEventoExamen.activa => AparienciaLozengeAtlassian.success,
    EstadoEventoExamen.suspendida => AparienciaLozengeAtlassian.warning,
    EstadoEventoExamen.cancelada => AparienciaLozengeAtlassian.danger,
    EstadoEventoExamen.reprogramada => AparienciaLozengeAtlassian.discovery,
  };
}

IconData _statusIcon(EstadoEventoExamen status) {
  return switch (status) {
    EstadoEventoExamen.activa => Icons.check_circle_outline_rounded,
    EstadoEventoExamen.suspendida => Icons.warning_amber_rounded,
    EstadoEventoExamen.cancelada => Icons.cancel_outlined,
    EstadoEventoExamen.reprogramada => Icons.event_repeat_rounded,
  };
}

Color _statusBackground(BuildContext context, EstadoEventoExamen status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    EstadoEventoExamen.activa => Colors.transparent,
    EstadoEventoExamen.suspendida =>
      dark ? const Color(0xFF262112) : const Color(0xFFFFFBE6),
    EstadoEventoExamen.cancelada =>
      dark ? const Color(0xFF321A1A) : const Color(0xFFFFEBE6),
    EstadoEventoExamen.reprogramada =>
      dark ? const Color(0xFF16233A) : const Color(0xFFE9F2FF),
  };
}

Color _statusIconBackground(BuildContext context, EstadoEventoExamen status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    EstadoEventoExamen.activa => Theme.of(context).colorScheme.primaryContainer,
    EstadoEventoExamen.suspendida =>
      dark ? const Color(0xFF4A3B00) : const Color(0xFFFFF3CD),
    EstadoEventoExamen.cancelada =>
      dark ? const Color(0xFF5A2020) : const Color(0xFFFFD5D2),
    EstadoEventoExamen.reprogramada =>
      dark ? const Color(0xFF173A66) : const Color(0xFFD6E8FF),
  };
}

Color _statusForeground(BuildContext context, EstadoEventoExamen status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    EstadoEventoExamen.activa => Theme.of(context).colorScheme.primary,
    EstadoEventoExamen.suspendida =>
      dark ? const Color(0xFFFFD54F) : const Color(0xFF8A5D00),
    EstadoEventoExamen.cancelada =>
      dark ? const Color(0xFFFF8F85) : const Color(0xFFAE2A19),
    EstadoEventoExamen.reprogramada =>
      dark ? const Color(0xFF85B8FF) : const Color(0xFF0052CC),
  };
}

class _DatoExamenAtlassian extends StatelessWidget {
  const _DatoExamenAtlassian({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

String _instanceLabel(String raw) {
  return switch (raw) {
    'llamado_1' => 'Primer llamado',
    'llamado_2' => 'Segundo llamado',
    'coloquio' => 'Coloquios',
    _ => 'Exámenes',
  };
}

String _shortInstanceLabel(String raw) {
  return switch (raw) {
    'llamado_1' => 'Llamado 1',
    'llamado_2' => 'Llamado 2',
    'coloquio' => 'Coloquio',
    _ => 'Examen',
  };
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

class _EsqueletoExamenesAtlassian extends StatelessWidget {
  const _EsqueletoExamenesAtlassian();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SeparadorTituloAtlassian(
          title: 'Primer llamado',
          subtitle: '4 registros',
        ),
        const SizedBox(height: 8),
        PanelAtlassian(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                _FilaExamenAtlassian(
                  event: EventoExamen(
                    careerId: 'historia',
                    anio: 1,
                    fecha: DateTime.now(),
                    hora: '19:00',
                    materia: i % 2 == 0
                        ? 'Problemática del Conocimiento Histórico'
                        : 'Didáctica General y Práctica Docente',
                    instancia: 'llamado_1',
                    docentes: const ['Docente Ficticio Uno', 'Docente Dos'],
                    actaUrl: null,
                  ),
                  onTap: () {},
                ),
                if (i != 3) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SeparadorTituloAtlassian(
          title: 'Segundo llamado',
          subtitle: '3 registros',
        ),
        const SizedBox(height: 8),
        PanelAtlassian(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                _FilaExamenAtlassian(
                  event: EventoExamen(
                    careerId: 'historia',
                    anio: 2,
                    fecha: DateTime.now(),
                    hora: '19:00',
                    materia: 'Historia de las Ideas Políticas y Sociales',
                    instancia: 'llamado_2',
                    docentes: const ['Docente Ficticio Tres'],
                    actaUrl: null,
                  ),
                  onTap: () {},
                ),
                if (i != 2) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
