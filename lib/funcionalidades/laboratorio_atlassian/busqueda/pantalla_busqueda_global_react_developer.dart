import 'dart:async';
import 'dart:math' as math;

import 'package:correlativas_historia/compartido/proveedores/datos_catalogo.dart';
import 'package:correlativas_historia/compartido/utilidades/sanitizar_texto.dart';
import 'package:correlativas_historia/datos/cargador_fuente_html.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/utilidades_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_react_developer.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:correlativas_historia/modelos/materia.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/navegacion/barra_busqueda_app.dart';
import '../../../compartido/tema/tema_herramientas_app.dart';
import 'modelos_busqueda_atlassian.dart';
import 'pantalla_busqueda_global_atlassian.dart'
    show
        canonicalSubjectKeyAtlassian,
        careerNameAtlassian,
        formatExamInstanceAtlassian,
        materiaDesdeContenidoAtlassian,
        minimumScoreBusquedaAtlassian,
        monthNameAtlassian,
        normalizarBusquedaAtlassian,
        readableProfileLabelAtlassian,
        scoreBusquedaAtlassian,
        searchableDateAtlassian,
        shortCareerNameAtlassian;

class PantallaBusquedaGlobalReactDeveloper extends ConsumerStatefulWidget {
  const PantallaBusquedaGlobalReactDeveloper({
    super.key,
    required this.trajectoryListenable,
    required this.selectedCareerListenable,
    required this.onOpenDestination,
  });

  final ValueListenable<TrayectoriaSageLaboratorio?> trajectoryListenable;
  final ValueListenable<int> selectedCareerListenable;
  final Future<void> Function(DestinoBusquedaAtlassian destination)
  onOpenDestination;

  @override
  ConsumerState<PantallaBusquedaGlobalReactDeveloper> createState() =>
      _PantallaBusquedaGlobalReactDeveloperState();
}

// Conserva la progresión entre rutas durante esta ejecución de la app.
final _demoraEntradaBusquedaProvider = Provider<_DemoraEntradaBusqueda>(
  (ref) => _DemoraEntradaBusqueda(),
);

class _DemoraEntradaBusqueda {
  int _aperturas = 0;

  Duration siguiente() {
    final milliseconds = math.max(0, 2000 - _aperturas * 500);
    _aperturas = math.min(4, _aperturas + 1);
    return Duration(milliseconds: milliseconds);
  }
}

enum _ReactSearchCategory { all, subjects, events, actions, careers, profile }

class _PantallaBusquedaGlobalReactDeveloperState
    extends ConsumerState<PantallaBusquedaGlobalReactDeveloper> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final PageController _careerPageController = PageController(
    viewportFraction: 0.86,
  );

  final List<_PlanCarreraBusqueda> _planes = <_PlanCarreraBusqueda>[];
  final List<String> _recentQueries = <String>[];

  // Conserva el contenido y sus posiciones al retirar el skeleton.
  final GlobalKey _contentKey = GlobalKey();
  bool _preparingEntry = false;
  Timer? _entryDelay;

  bool _sageExpanded = false;
  String _query = '';
  Timer? _debounce;
  _ReactSearchCategory _category = _ReactSearchCategory.all;
  int _careerPage = 0;

  _SearchModel? _cachedModel;
  List<EventoExamen>? _cachedExams;
  List<ContenidoCurricular>? _cachedCurricular;
  String? _lastQueryKey;

  List<CareerInfo> get _visibleCareers =>
      kCareers.where((career) => !career.hidden).toList(growable: false);

  @override
  void initState() {
    super.initState();
    final delay = ref.read(_demoraEntradaBusquedaProvider).siguiente();
    _preparingEntry = delay > Duration.zero;
    if (_preparingEntry) {
      _entryDelay = Timer(delay, () {
        if (!mounted) return;
        setState(() => _preparingEntry = false);
      });
    }
    unawaited(_loadPlans());
  }

  Future<void> _loadPlans() async {
    final loaded = await Future.wait<_PlanCarreraBusqueda>(
      _visibleCareers.map((career) async {
        try {
          final plan = await cargarPlanDesdeAssetHtml(career.assetHtml);
          return _PlanCarreraBusqueda(career: career, plan: plan);
        } catch (_) {
          return _PlanCarreraBusqueda(
            career: career,
            plan: DatosPlan(materias: const <Materia>[], pdfUrl: null),
          );
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _planes
        ..clear()
        ..addAll(loaded);
      _cachedModel = null;
      _lastQueryKey = null;
    });
  }

  @override
  void dispose() {
    _entryDelay?.cancel();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _careerPageController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        if (normalizarBusquedaAtlassian(value).isEmpty) {
          _category = _ReactSearchCategory.all;
        }
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _setQuery(String value) {
    _debounce?.cancel();
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {
      _query = value;
      _category = _ReactSearchCategory.all;
    });
    _focusNode.requestFocus();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _category = _ReactSearchCategory.all;
    });
    _focusNode.requestFocus();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _rememberQuery() {
    final value = _query.trim();
    if (value.length < 2) return;
    setState(() {
      _recentQueries.removeWhere(
        (item) =>
            normalizarBusquedaAtlassian(item) ==
            normalizarBusquedaAtlassian(value),
      );
      _recentQueries.insert(0, value);
      if (_recentQueries.length > 5) _recentQueries.removeLast();
    });
  }

  Future<void> _open(DestinoBusquedaAtlassian destination) async {
    _rememberQuery();
    _focusNode.unfocus();
    await widget.onOpenDestination(destination);
  }

  String _trajectoryFingerprint(
    TrayectoriaSageLaboratorio? trajectory,
    int selectedCareer,
  ) {
    if (trajectory == null) return 'none|$selectedCareer';
    final careers = trajectory.carreras
        .map(
          (career) => <Object?>[
            career.gridRowId,
            career.careerKey,
            career.materias.length,
            career.aprobadas,
            career.cursando,
          ].join(':'),
        )
        .join(',');
    return <Object?>[
      identityHashCode(trajectory),
      trajectory.sincronizadaEn?.microsecondsSinceEpoch,
      trajectory.totalMaterias,
      selectedCareer,
      careers,
    ].join('|');
  }

  int _examsFingerprint(List<EventoExamen> exams) {
    return Object.hashAll(
      exams.map(
        (event) => Object.hash(
          event.id,
          event.careerId,
          event.materia,
          event.instancia,
          event.fechaVigente,
          event.horaVigente,
          event.visible,
        ),
      ),
    );
  }

  int _curricularFingerprint(List<ContenidoCurricular> curricular) {
    return Object.hashAll(
      curricular.map(
        (content) => Object.hash(
          content.id,
          content.nombre,
          content.anio,
          content.cargaHoraria,
          content.ejes.length,
        ),
      ),
    );
  }

  List<String> _suggestedQueries(
    List<EventoExamen> exams,
    TrayectoriaSageLaboratorio? trajectory,
    int selectedCareer,
  ) {
    final now = DateTime.now();
    final future =
        exams
            .where(
              (event) => event.visible && event.fechaHora?.isAfter(now) == true,
            )
            .toList(growable: false)
          ..sort((a, b) => a.fechaHora!.compareTo(b.fechaHora!));
    final targetMonth = future.firstOrNull?.fechaVigente?.month ?? now.month;
    final suggestions = <String>[
      'Mesas de ${monthNameAtlassian(targetMonth)}',
      'Práctica Docente',
      'Diseño curricular',
      'SAGE',
    ];
    if (trajectory != null && trajectory.carreras.isNotEmpty) {
      final index = selectedCareer
          .clamp(0, trajectory.carreras.length - 1)
          .toInt();
      final career = trajectory.carreras[index];
      suggestions.insert(0, career.nombre);
      if (career.aprobadas > 0) suggestions.add('Materias aprobadas');
      if (career.cursando > 0) suggestions.add('Materias cursando');
      final years =
          career.materias
              .map((subject) => subject.anio)
              .whereType<int>()
              .toSet()
              .toList()
            ..sort();
      if (years.isNotEmpty) suggestions.add('${years.last}° año');
    } else {
      suggestions.insert(0, 'Profesorado de Historia');
      suggestions.add('Materias aprobadas');
    }
    return suggestions.toSet().take(8).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(proveedorTodosLosExamenes);
    final curricularAsync = ref.watch(proveedorContenidosCurriculares);
    final exams = examsAsync.value ?? const <EventoExamen>[];
    final curricular = curricularAsync.value ?? const <ContenidoCurricular>[];
    return ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
      valueListenable: widget.trajectoryListenable,
      builder: (context, trajectory, _) {
        return ValueListenableBuilder<int>(
          valueListenable: widget.selectedCareerListenable,
          builder: (context, selectedCareer, _) {
            final query = normalizarBusquedaAtlassian(_query);
            final queryKey = <Object?>[
              query,
              _trajectoryFingerprint(trajectory, selectedCareer),
              _examsFingerprint(exams),
              exams.length,
              _curricularFingerprint(curricular),
              curricular.length,
              _planes.length,
            ].join('|');
            if (_cachedModel == null ||
                _lastQueryKey != queryKey ||
                !identical(_cachedExams, exams) ||
                !identical(_cachedCurricular, curricular)) {
              _cachedExams = exams;
              _cachedCurricular = curricular;
              _lastQueryKey = queryKey;
              _cachedModel = _buildSearchModel(
                query: query,
                trajectory: trajectory,
                exams: exams,
                curricular: curricular,
              );
            }
            final model = _cachedModel!;
            final atlassianTheme = temaLaboratorioAtlassian(context);
            final reactTheme = TemaReactDeveloper.of(context);

            return Theme(
              data: atlassianTheme,
              child: Scaffold(
                backgroundColor: reactTheme.isDark
                    ? atlassianTheme.scaffoldBackgroundColor
                    : reactTheme.canvas,
                resizeToAvoidBottomInset: true,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 8),
                        child: RepaintBoundary(
                          child: Semantics(
                            label: _preparingEntry
                                ? 'Preparando búsqueda'
                                : null,
                            child: ExcludeSemantics(
                              excluding: _preparingEntry,
                              child: ExcludeFocus(
                                excluding: _preparingEntry,
                                child: Skeletonizer(
                                  key: const ValueKey(
                                    'busqueda-react-skeleton',
                                  ),
                                  enabled: _preparingEntry,
                                  enableSwitchAnimation: false,
                                  effect:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? SolidColorEffect(
                                          color: reactTheme.isDark
                                              ? const Color(0xFF303645)
                                              : const Color(0xFFE0E8F2),
                                        )
                                      : null,
                                  child: KeyedSubtree(
                                    key: _contentKey,
                                    child: query.isEmpty
                                        ? _buildLanding(
                                            context,
                                            trajectory,
                                            selectedCareer,
                                            exams,
                                          )
                                        : _buildResults(context, model),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 70,
                      right: 16,
                      top: MediaQuery.paddingOf(context).top + 8,
                      child: BarraBusquedaApp(
                        key: const ValueKey<String>(
                          'busqueda-react-liquid-field',
                        ),
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        onSubmitted: (_) => _rememberQuery(),
                        onClear: _clearQuery,
                      ),
                    ),
                    _TopFadeReact(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanding(
    BuildContext context,
    TrayectoriaSageLaboratorio? trajectory,
    int selectedCareer,
    List<EventoExamen> exams,
  ) {
    final actions = _baseActions(trajectory);
    final navigation = actions
        .where((item) => item.group == _ActionGroup.navigation)
        .toList(growable: false);
    final tools = actions
        .where((item) => item.group == _ActionGroup.tools)
        .toList(growable: false);
    final sage = actions
        .where((item) => item.group == _ActionGroup.sage)
        .toList(growable: false);
    final suggestions = _suggestedQueries(exams, trajectory, selectedCareer);
    final topSpacing = MediaQuery.paddingOf(context).top + 90;

    return CustomScrollView(
      key: const ValueKey<String>('busqueda-react-landing'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topSpacing)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          sliver: SliverToBoxAdapter(
            child: _SplitSearchTitleReact(
              title: 'buscá',
              subtitle: 'o saltá directo',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _EntradaMenuReact(
              key: const ValueKey('menu-accesos'),
              lista: !_preparingEntry,
              orden: 1,
              child: _AccessMagicBentoReact(
                actions: navigation,
                onTap: (action) => _open(action.destination),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: _ReactSectionTitle(
              primary: 'herramientas',
              accent: 'a mano',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: _EntradaMenuReact(
            key: const ValueKey('menu-herramientas'),
            lista: !_preparingEntry,
            orden: 2,
            child: _ToolsDockReact(
              actions: tools,
              onTap: (action) => _open(action.destination),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _SageCardNavReact(
              actions: sage,
              expanded: _sageExpanded,
              onToggle: () => setState(() => _sageExpanded = !_sageExpanded),
              onTap: (action) => _open(action.destination),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: _ReactSectionTitle(
                    primary: 'elegí la',
                    accent: 'institución',
                  ),
                ),
                Text(
                  '${_careerPage + 1}/${_visibleCareers.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.reactTheme.muted(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: _EntradaMenuReact(
            key: const ValueKey('menu-instituciones'),
            lista: !_preparingEntry,
            orden: 3,
            child: _CareerDepthCarouselReact(
              controller: _careerPageController,
              careers: _visibleCareers,
              onPageChanged: (index) => setState(() => _careerPage = index),
              onOpen: _open,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: _ReactSectionTitle(primary: 'probá una', accent: 'búsqueda'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _BubbleSuggestionsReact(
              recent: _recentQueries,
              suggested: suggestions,
              onTap: _setQuery,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 138)),
      ],
    );
  }

  Widget _buildResults(BuildContext context, _SearchModel model) {
    final total = _categoryCount(model, _ReactSearchCategory.all);
    final activeCount = _categoryCount(model, _category);
    final topSpacing = MediaQuery.paddingOf(context).top + 90;
    final slivers = <Widget>[
      SliverToBoxAdapter(child: SizedBox(height: topSpacing)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
        sliver: SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _SplitSearchTitleReact(
                  title: total == 0 ? 'sin resultados' : 'encontramos',
                  subtitle: total == 1
                      ? '1 coincidencia'
                      : '$total coincidencias',
                  compact: true,
                ),
              ),
              if (total > 0) _ResultCountOrbReact(count: activeCount),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
      SliverToBoxAdapter(
        child: _GooeyFilterReact(
          selected: _category,
          model: model,
          onSelected: (category) => setState(() => _category = category),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
    ];

    if (total == 0 || activeCount == 0) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: _NoResultsReact(onSuggestion: _setQuery),
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 132)));
      return CustomScrollView(
        key: ValueKey<String>('busqueda-react-results-${_category.name}'),
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: slivers,
      );
    }

    if (_category == _ReactSearchCategory.all) {
      final best = _bestMatchWidget(model);
      if (best != null) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: best),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
      }
    }

    void addHeading(String title, String subtitle) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          sliver: SliverToBoxAdapter(
            child: _ResultSectionHeadingReact(title: title, subtitle: subtitle),
          ),
        ),
      );
    }

    if (_category == _ReactSearchCategory.all ||
        _category == _ReactSearchCategory.actions) {
      if (model.actions.isNotEmpty) {
        addHeading('accesos y acciones', '${model.actions.length} disponibles');
        slivers.add(
          _sliverCards<_SearchAction>(
            model.actions,
            (action, index) => _ActionResultReact(
              action: action,
              index: index,
              onTap: () => _open(action.destination),
            ),
          ),
        );
      }
    }

    if (_category == _ReactSearchCategory.all ||
        _category == _ReactSearchCategory.subjects) {
      if (model.subjects.isNotEmpty) {
        addHeading(
          'materias conectadas',
          '${model.subjects.length} resultados',
        );
        slivers.add(
          _sliverCards<_ConnectedSubjectResult>(
            model.subjects,
            (result, index) => _SubjectResultReact(
              result: result,
              index: index,
              onOpen: _open,
            ),
          ),
        );
      }
    }

    if (_category == _ReactSearchCategory.all ||
        _category == _ReactSearchCategory.events) {
      if (model.events.isNotEmpty) {
        addHeading('mesas y fechas', '${model.events.length} coincidencias');
        slivers.add(
          _sliverCards<_ExamResult>(
            model.events,
            (result, index) =>
                _ExamResultReact(result: result, index: index, onOpen: _open),
          ),
        );
      }
    }

    if (_category == _ReactSearchCategory.all ||
        _category == _ReactSearchCategory.careers) {
      if (model.careers.isNotEmpty) {
        addHeading('profesorados', '${model.careers.length} coincidencias');
        slivers.add(
          _sliverCards<_CareerResult>(
            model.careers,
            (result, index) =>
                _CareerResultReact(result: result, index: index, onOpen: _open),
          ),
        );
      }
    }

    if (_category == _ReactSearchCategory.all ||
        _category == _ReactSearchCategory.profile) {
      if (model.profile.isNotEmpty) {
        addHeading('tus datos', '${model.profile.length} coincidencias');
        slivers.add(
          _sliverCards<_ProfileResult>(
            model.profile,
            (result, index) => _ProfileResultReact(
              result: result,
              index: index,
              onTap: () => _open(
                const DestinoBusquedaAtlassian(
                  tipo: TipoDestinoBusquedaAtlassian.seccion,
                  seccion: 4,
                ),
              ),
            ),
          ),
        );
      }
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 132)));
    return CustomScrollView(
      key: ValueKey<String>('busqueda-react-results-${_category.name}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: slivers,
    );
  }

  Widget _sliverCards<T>(
    List<T> items,
    Widget Function(T item, int index) builder,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StaggeredRevealReact(
              index: index,
              child: builder(items[index], index),
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget? _bestMatchWidget(_SearchModel model) {
    if (model.actions.isNotEmpty) {
      final action = model.actions.first;
      return _SpotlightBestMatchReact(
        eyebrow: 'mejor coincidencia',
        title: action.title,
        subtitle: action.subtitle,
        icon: action.icon,
        onTap: () => _open(action.destination),
      );
    }
    if (model.subjects.isNotEmpty) {
      final subject = model.subjects.first;
      return _SpotlightBestMatchReact(
        eyebrow: 'materia destacada',
        title: subject.title,
        subtitle: _subjectSourcesLabel(subject),
        icon: Icons.auto_awesome_mosaic_rounded,
        onTap: () => _openSubjectPrimary(subject),
      );
    }
    if (model.events.isNotEmpty) {
      final event = model.events.first.event;
      return _SpotlightBestMatchReact(
        eyebrow: 'próxima coincidencia',
        title: event.materia,
        subtitle: formatoFechaHoraAtlassian(
          event.fechaVigente,
          event.horaVigente,
        ),
        icon: Icons.event_available_rounded,
        onTap: () => _open(
          DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.detalleExamen,
            evento: event,
          ),
        ),
      );
    }
    return null;
  }

  Future<void> _openSubjectPrimary(_ConnectedSubjectResult result) async {
    if (result.trajectory.isNotEmpty) {
      final occurrence = result.trajectory.first;
      await _open(
        DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.detalleTrayectoria,
          materiaTrayectoria: occurrence.subject,
          carreraTrayectoria: occurrence.career,
        ),
      );
      return;
    }
    if (result.plans.isNotEmpty) {
      final occurrence = result.plans.first;
      await _open(
        DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.detallePlan,
          career: occurrence.career,
          materiaPlan: occurrence.subject,
          materiasPlan: occurrence.allSubjects,
        ),
      );
      return;
    }
    if (result.designs.isNotEmpty) {
      final content = result.designs.first;
      await _open(
        DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.detalleDiseno,
          career: kCareers.firstWhere((item) => item.id == 'historia'),
          materiaPlan: materiaDesdeContenidoAtlassian(content),
          contenidoCurricular: content,
        ),
      );
      return;
    }
    if (result.events.isNotEmpty) {
      await _open(
        DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.detalleExamen,
          evento: result.events.first,
        ),
      );
    }
  }

  int _categoryCount(_SearchModel model, _ReactSearchCategory category) {
    return switch (category) {
      _ReactSearchCategory.all =>
        model.actions.length +
            model.subjects.length +
            model.events.length +
            model.careers.length +
            model.profile.length,
      _ReactSearchCategory.actions => model.actions.length,
      _ReactSearchCategory.subjects => model.subjects.length,
      _ReactSearchCategory.events => model.events.length,
      _ReactSearchCategory.careers => model.careers.length,
      _ReactSearchCategory.profile => model.profile.length,
    };
  }

  String _subjectSourcesLabel(_ConnectedSubjectResult result) {
    final labels = <String>[
      if (result.trajectory.isNotEmpty) 'tu trayectoria',
      if (result.plans.isNotEmpty) 'plan',
      if (result.designs.isNotEmpty) 'diseño',
      if (result.events.isNotEmpty) 'mesas',
    ];
    return labels.join(' · ');
  }

  _SearchModel _buildSearchModel({
    required String query,
    required TrayectoriaSageLaboratorio? trajectory,
    required List<EventoExamen> exams,
    required List<ContenidoCurricular> curricular,
  }) {
    final actions = _rankActions(query, trajectory);
    final careers = _rankCareers(query);
    final subjects = _rankSubjects(
      query: query,
      trajectory: trajectory,
      exams: exams,
      curricular: curricular,
    );
    final events = _rankEvents(query, exams);
    final profile = _rankProfile(query, trajectory?.perfil);
    return _SearchModel(
      actions: actions.take(12).toList(growable: false),
      careers: careers.take(5).toList(growable: false),
      subjects: subjects.take(28).toList(growable: false),
      events: events.take(16).toList(growable: false),
      profile: profile.take(12).toList(growable: false),
    );
  }

  List<_SearchAction> _baseActions(TrayectoriaSageLaboratorio? trajectory) {
    return <_SearchAction>[
      _SearchAction(
        title: 'Calendario',
        subtitle: 'Mesas y fechas publicadas',
        icon: Icons.calendar_month_outlined,
        keywords:
            'calendario agenda fecha fechas mes meses enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre mesas',
        group: _ActionGroup.navigation,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.calendario,
          careerId: _trajectoryCareerId(trajectory),
        ),
      ),
      _SearchAction(
        title: 'Exámenes',
        subtitle: 'Mesas y llamados',
        icon: Icons.event_note_outlined,
        keywords:
            'examen examenes mesa mesas final finales llamado llamados coloquio coloquios docentes fechas',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 1,
        ),
      ),
      _SearchAction(
        title: 'Plan completo',
        subtitle: 'Materias y correlatividades',
        icon: Icons.account_tree_outlined,
        keywords:
            'plan completo carrera materias correlativas correlatividades primer segundo tercer cuarto año mapa',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 2,
        ),
      ),
      _SearchAction(
        title: 'Mis materias',
        subtitle: 'Estados de tu trayectoria',
        icon: Icons.menu_book_outlined,
        keywords:
            'materia materias trayectoria aprobada aprobadas regular regulares cursando no regularizada pendiente estado',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 3,
        ),
      ),
      _SearchAction(
        title: 'Datos',
        subtitle: 'Perfil y carreras',
        icon: Icons.person_outline_rounded,
        keywords:
            'datos perfil dni documento telefono nacimiento localidad estudiante carrera institucion sincronizacion',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 4,
        ),
      ),
      const _SearchAction(
        title: 'Diseños curriculares',
        subtitle: 'Marcos, ejes y bibliografía',
        icon: Icons.auto_stories_outlined,
        keywords:
            'diseño diseno diseños disenos curricular curriculares marco orientador ejes contenidos bibliografia horas carga horaria',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.disenos,
        ),
      ),
      const _SearchAction(
        title: 'Escenarios',
        subtitle: 'Evaluar correlativas y posibilidades',
        icon: Icons.auto_graph_outlined,
        keywords:
            'escenario escenarios calculadora puedo cursar habilitada habilitadas correlativas promocion rendir',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.escenarios,
        ),
      ),
      const _SearchAction(
        title: 'Ayuda',
        subtitle: 'Preguntas frecuentes y reglamento',
        icon: Icons.help_outline_rounded,
        keywords:
            'ayuda preguntas frecuentes faq reglamento regularidad promocion ingreso correlativas asistencia libre',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.ayuda,
        ),
      ),
      const _SearchAction(
        title: 'Próximos pasos',
        subtitle: 'Acciones sugeridas para avanzar',
        icon: Icons.flag_outlined,
        keywords: 'proximos pasos siguiente pendientes avanzar recomendaciones',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.proximosPasos,
        ),
      ),
      const _SearchAction(
        title: 'Mi avance',
        subtitle: 'Resumen de la trayectoria',
        icon: Icons.insights_outlined,
        keywords:
            'avance progreso estadistica aprobadas regulares cursando trayectoria',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.avance,
        ),
      ),
      const _SearchAction(
        title: 'Abrir SAGE',
        subtitle: 'Entrar al portal académico',
        icon: Icons.open_in_browser_rounded,
        keywords: 'sage abrir portal entrar sistema academico legajo alumnos',
        group: _ActionGroup.sage,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.sage,
        ),
      ),
      const _SearchAction(
        title: 'Sincronizar con SAGE',
        subtitle: 'Iniciar sesión, leer y guardar la trayectoria',
        icon: Icons.sync_rounded,
        keywords:
            'sincronizar sync guardar importar actualizar trayectoria sage conectar',
        group: _ActionGroup.sage,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.sincronizar,
        ),
      ),
      _SearchAction(
        title: 'Situación académica',
        subtitle: trajectory == null
            ? 'Sin trayectoria sincronizada'
            : 'Descargar desde SAGE',
        icon: Icons.assignment_ind_outlined,
        keywords:
            'situacion situación academica académica resumen academico resumen académico estado academico estado académico documento descargar pdf sage alumno carrera',
        group: _ActionGroup.sage,
        enabled: trajectory != null,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.documentoAcademico,
          tipoDocumento: TipoDocumentoAcademicoSage.situacionAcademica,
        ),
      ),
      _SearchAction(
        title: 'Analítico',
        subtitle: trajectory == null
            ? 'Sin trayectoria sincronizada'
            : 'Descargar desde SAGE',
        icon: Icons.fact_check_outlined,
        keywords:
            'analitico analítico analitico academico analítico académico certificado materias aprobadas notas documento descargar pdf sage',
        group: _ActionGroup.sage,
        enabled: trajectory != null,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.documentoAcademico,
          tipoDocumento: TipoDocumentoAcademicoSage.analitico,
        ),
      ),
      _SearchAction(
        title: 'Libreta',
        subtitle: trajectory == null
            ? 'Sin trayectoria sincronizada'
            : 'Descargar desde SAGE',
        icon: Icons.menu_book_outlined,
        keywords:
            'libreta libreta academica libreta académica boletin boletín calificaciones notas materias documento descargar pdf sage',
        group: _ActionGroup.sage,
        enabled: trajectory != null,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.documentoAcademico,
          tipoDocumento: TipoDocumentoAcademicoSage.libreta,
        ),
      ),
      const _SearchAction(
        title: 'Cerrar sesión de SAGE',
        subtitle: 'Desconectar la sesión académica activa',
        icon: Icons.logout_rounded,
        keywords:
            'sage cerrar sesion logout desconectar salir cuenta usuario seguridad',
        group: _ActionGroup.sage,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.cerrarSesionSage,
        ),
      ),
      _SearchAction(
        title: 'Desincronizar trayectoria',
        subtitle: trajectory == null
            ? 'Sin trayectoria guardada'
            : 'Eliminar la copia local',
        icon: Icons.link_off_rounded,
        keywords:
            'desincronizar desconectar sage borrar eliminar trayectoria local desvincular',
        group: _ActionGroup.sage,
        enabled: trajectory != null,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.desincronizar,
        ),
      ),
    ];
  }

  TipoDocumentoAcademicoSage? _documentTypeFromQuery(String query) {
    final tokens = normalizarBusquedaAtlassian(query).split(' ').toSet();
    if (tokens.contains('analitico')) {
      return TipoDocumentoAcademicoSage.analitico;
    }
    if (tokens.contains('libreta') || tokens.contains('boletin')) {
      return TipoDocumentoAcademicoSage.libreta;
    }
    final isAcademicSummary =
        tokens.contains('academico') &&
        (tokens.contains('resumen') ||
            tokens.contains('situacion') ||
            tokens.contains('estado'));
    if (isAcademicSummary ||
        (tokens.contains('resumen') && tokens.contains('trayectoria'))) {
      return TipoDocumentoAcademicoSage.situacionAcademica;
    }
    return null;
  }

  List<_SearchAction> _rankActions(
    String query,
    TrayectoriaSageLaboratorio? trajectory,
  ) {
    final actions = <_SearchAction>[..._baseActions(trajectory)];
    final detectedDocument = _documentTypeFromQuery(query);
    final detectedState = _stateFromQuery(query);
    final detectedYear = _yearFromQuery(query);
    final detectedMonth = _monthFromQuery(query);
    final detectedCareer = _careerFromQuery(query);

    if (detectedMonth != null) {
      final now = DateTime.now();
      actions.insert(
        0,
        _SearchAction(
          title: 'Abrir ${monthNameAtlassian(detectedMonth)} en el calendario',
          subtitle: detectedCareer?.nombre ?? 'Mesas de todos los profesorados',
          icon: Icons.calendar_month_outlined,
          keywords:
              '${monthNameAtlassian(detectedMonth)} calendario fechas mesas mes',
          group: _ActionGroup.dynamic,
          destination: DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.calendario,
            careerId: detectedCareer?.id ?? _trajectoryCareerId(trajectory),
            fecha: DateTime(now.year, detectedMonth),
          ),
        ),
      );
    }

    if (detectedState != null) {
      actions.insert(
        0,
        _SearchAction(
          title: 'Ver materias ${detectedState.etiqueta.toLowerCase()}',
          subtitle: 'Aplicar el estado en Mis materias',
          icon: Icons.filter_alt_outlined,
          keywords: '${detectedState.etiqueta} estado materias trayectoria',
          group: _ActionGroup.dynamic,
          enabled: trajectory != null,
          destination: DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.seccion,
            seccion: 3,
            status: detectedState,
          ),
        ),
      );
    }

    if (detectedYear != null) {
      actions.insertAll(0, <_SearchAction>[
        _SearchAction(
          title: 'Ver $detectedYear° año en el plan',
          subtitle: detectedCareer?.nombre ?? 'Todos los profesorados',
          icon: Icons.account_tree_outlined,
          keywords: '$detectedYear año plan materias',
          group: _ActionGroup.dynamic,
          destination: DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.seccion,
            seccion: 2,
            careerId: detectedCareer?.id,
            year: detectedYear,
          ),
        ),
        _SearchAction(
          title: 'Ver $detectedYear° año en mi trayectoria',
          subtitle: 'Materias sincronizadas',
          icon: Icons.menu_book_outlined,
          keywords: '$detectedYear año trayectoria materias',
          group: _ActionGroup.dynamic,
          enabled: trajectory != null,
          destination: DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.seccion,
            seccion: 3,
            year: detectedYear,
          ),
        ),
      ]);
    }

    final ranked = <_ScoredAction>[];
    for (final action in actions) {
      if (!action.enabled) continue;
      final textScore = math.max(
        scoreBusquedaAtlassian(query, action.title) * 2,
        scoreBusquedaAtlassian(
          query,
          '${action.title} ${action.subtitle} ${action.keywords}',
        ),
      );
      final isDetectedDocument =
          detectedDocument != null &&
          action.destination.tipoDocumento == detectedDocument;
      final score = isDetectedDocument ? math.max(textScore, 320) : textScore;
      if (score >= minimumScoreBusquedaAtlassian(query)) {
        ranked.add(_ScoredAction(action: action, score: score));
      }
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.map((item) => item.action).toList(growable: false);
  }

  List<_CareerResult> _rankCareers(String query) {
    final results = <_CareerResult>[];
    for (final career in _visibleCareers) {
      final institutions = kInstitutions
          .where(
            (institution) =>
                !institution.hidden && institution.careerId == career.id,
          )
          .toList(growable: false);
      final synonyms = switch (career.id) {
        'historia' => 'historia historico historiador',
        'geografia' => 'geografia geografico territorio',
        'politica' => 'politica politicas ciencia ciencias politicas',
        'artes_visuales' => 'arte artes visual visuales artistica',
        'musica' => 'musica musical educacion musical',
        _ => '',
      };
      final target = <String>[
        career.id,
        career.nombre,
        career.categoria,
        synonyms,
        ...institutions.map((item) => item.nombre),
      ].join(' ');
      final score = math.max(
        scoreBusquedaAtlassian(query, career.nombre) * 2,
        scoreBusquedaAtlassian(query, target),
      );
      if (score >= minimumScoreBusquedaAtlassian(query)) {
        results.add(
          _CareerResult(
            career: career,
            institutions: institutions,
            score: score,
          ),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  List<_ConnectedSubjectResult> _rankSubjects({
    required String query,
    required TrayectoriaSageLaboratorio? trajectory,
    required List<EventoExamen> exams,
    required List<ContenidoCurricular> curricular,
  }) {
    final builders = <String, _SubjectClusterBuilder>{};

    _SubjectClusterBuilder clusterFor(String name) {
      final key = canonicalSubjectKeyAtlassian(name);
      return builders.putIfAbsent(
        key,
        () => _SubjectClusterBuilder(title: sanitizarTexto(name)),
      );
    }

    for (final planEntry in _planes) {
      for (final subject in planEntry.plan.materias) {
        clusterFor(subject.displayNombre).plans.add(
          _PlanSubjectOccurrence(
            career: planEntry.career,
            subject: subject,
            allSubjects: planEntry.plan.materias,
          ),
        );
      }
    }

    if (trajectory != null) {
      for (
        var careerIndex = 0;
        careerIndex < trajectory.carreras.length;
        careerIndex++
      ) {
        final career = trajectory.carreras[careerIndex];
        for (final subject in career.materias) {
          clusterFor(subject.nombre).trajectory.add(
            _TrajectorySubjectOccurrence(
              careerIndex: careerIndex,
              career: career,
              subject: subject,
            ),
          );
        }
      }
    }

    for (final content in curricular) {
      final cluster = clusterFor(content.nombre);
      cluster.designs.add(content);
    }

    for (final exam in exams) {
      if (!exam.visible) continue;
      clusterFor(exam.materia).events.add(exam);
    }

    final results = <_ConnectedSubjectResult>[];
    for (final builder in builders.values) {
      final titleScore = scoreBusquedaAtlassian(query, builder.title) * 2;
      final codes = builder.plans.map((item) => item.subject.codigo).join(' ');
      final planMetadata = builder.plans
          .map(
            (item) =>
                '${item.career.nombre} ${item.subject.anio} año ${item.subject.tipo} ${item.subject.formato} ${item.subject.horas ?? ''}',
          )
          .join(' ');
      final trajectoryMetadata = builder.trajectory
          .map(
            (item) =>
                '${item.career.nombre} ${item.subject.estado.etiqueta} ${item.subject.estadoOriginal} ${item.subject.anio ?? ''} año ${item.subject.nota ?? ''} ${item.subject.fecha ?? ''}',
          )
          .join(' ');
      final examMetadata = builder.events
          .map(
            (event) =>
                '${event.careerId} ${event.instancia} ${event.docentes.join(' ')} ${event.division ?? ''} ${searchableDateAtlassian(event.fechaVigente, event.horaVigente)}',
          )
          .join(' ');
      final designMetadata = builder.designs
          .map(
            (content) =>
                '${content.formato} ${content.cargaHoraria} ${content.regimenCursado} ${content.tipo} ${content.marcoOrientador} ${content.ejes.map((eje) => '${eje.titulo} ${eje.descripcion}').join(' ')} ${content.bibliografia.join(' ')}',
          )
          .join(' ');
      final metadataScore = scoreBusquedaAtlassian(
        query,
        '${builder.title} $codes $planMetadata $trajectoryMetadata $examMetadata',
      );
      final designScore = scoreBusquedaAtlassian(query, designMetadata);
      final score = math.max(titleScore, math.max(metadataScore, designScore));
      if (score < minimumScoreBusquedaAtlassian(query)) continue;
      results.add(
        _ConnectedSubjectResult(
          title: builder.title,
          plans: List<_PlanSubjectOccurrence>.unmodifiable(builder.plans),
          trajectory: List<_TrajectorySubjectOccurrence>.unmodifiable(
            builder.trajectory,
          ),
          designs: List<ContenidoCurricular>.unmodifiable(builder.designs),
          events: List<EventoExamen>.unmodifiable(builder.events),
          score: score,
        ),
      );
    }
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.title.compareTo(b.title);
    });
    return results;
  }

  List<_ExamResult> _rankEvents(String query, List<EventoExamen> exams) {
    final results = <_ExamResult>[];
    for (final event in exams) {
      if (!event.visible) continue;
      final careerName = careerNameAtlassian(event.careerId);
      final target = <String>[
        event.materia,
        careerName,
        event.instancia,
        event.docentes.join(' '),
        event.division ?? '',
        event.anio?.toString() ?? '',
        searchableDateAtlassian(event.fechaVigente, event.horaVigente),
        'mesa examen final coloquio calendario fecha',
      ].join(' ');
      final score = math.max(
        scoreBusquedaAtlassian(query, event.materia) * 2,
        scoreBusquedaAtlassian(query, target),
      );
      if (score >= minimumScoreBusquedaAtlassian(query)) {
        results.add(_ExamResult(event: event, score: score));
      }
    }
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final aDate = a.event.fechaHora;
      final bDate = b.event.fechaHora;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return results;
  }

  List<_ProfileResult> _rankProfile(
    String query,
    PerfilTrayectoriaSageLaboratorio? profile,
  ) {
    if (profile == null) return const <_ProfileResult>[];
    final fields = <_ProfileResult>[
      _ProfileResult(label: 'Nombre completo', value: profile.nombre, score: 0),
      if ((profile.dni ?? '').trim().isNotEmpty)
        _ProfileResult(label: 'DNI', value: profile.dni!, score: 0),
      for (final entry in profile.campos.entries)
        if (entry.value.trim().isNotEmpty)
          _ProfileResult(
            label: readableProfileLabelAtlassian(entry.key),
            value: entry.value,
            score: 0,
          ),
    ];
    final results = <_ProfileResult>[];
    for (final item in fields) {
      final score = scoreBusquedaAtlassian(
        query,
        '${item.label} ${item.value} datos perfil estudiante',
      );
      if (score >= minimumScoreBusquedaAtlassian(query)) {
        results.add(
          _ProfileResult(label: item.label, value: item.value, score: score),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  CareerInfo? _careerFromQuery(String query) {
    CareerInfo? best;
    var bestScore = 0;
    for (final career in _visibleCareers) {
      final score = scoreBusquedaAtlassian(
        query,
        '${career.id} ${career.nombre}',
      );
      if (score > bestScore && score >= 45) {
        best = career;
        bestScore = score;
      }
    }
    return best;
  }

  int? _monthFromQuery(String query) {
    const months = <String, int>{
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };
    for (final entry in months.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(query)) {
        return entry.value;
      }
    }
    return null;
  }

  EstadoMateriaSageLaboratorio? _stateFromQuery(String query) {
    if (_containsAny(query, const ['no regular', 'pendiente'])) {
      return EstadoMateriaSageLaboratorio.noRegularizada;
    }
    if (_containsAny(query, const ['aprobada'])) {
      return EstadoMateriaSageLaboratorio.aprobada;
    }
    if (_containsAny(query, const ['regular'])) {
      return EstadoMateriaSageLaboratorio.regular;
    }
    if (_containsAny(query, const ['cursando', 'curso', 'cursada'])) {
      return EstadoMateriaSageLaboratorio.cursando;
    }
    if (_containsAny(query, const ['sin clasificar', 'desconocida'])) {
      return EstadoMateriaSageLaboratorio.desconocida;
    }
    return null;
  }

  int? _yearFromQuery(String query) {
    if (RegExp(r'\b(1|1ro|1er|primero|primer)\b').hasMatch(query)) return 1;
    if (RegExp(r'\b(2|2do|segundo)\b').hasMatch(query)) return 2;
    if (RegExp(r'\b(3|3ro|3er|tercero|tercer)\b').hasMatch(query)) return 3;
    if (RegExp(r'\b(4|4to|cuarto)\b').hasMatch(query)) return 4;
    return null;
  }

  bool _containsAny(String query, List<String> terms) {
    return terms.any((term) => query.contains(term));
  }

  String _trajectoryCareerId(TrayectoriaSageLaboratorio? trajectory) {
    if (trajectory == null || trajectory.carreras.isEmpty) return 'historia';
    final index = widget.selectedCareerListenable.value
        .clamp(0, trajectory.carreras.length - 1)
        .toInt();
    return idCarreraExamenAtlassian(trajectory.carreras[index].nombre);
  }
}

class _TopFadeReact extends StatelessWidget {
  const _TopFadeReact({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 16,
    top: MediaQuery.paddingOf(context).top + 15,
    child: _FloatingBackReact(onTap: onBack),
  );
}

class _FloatingBackReact extends StatefulWidget {
  const _FloatingBackReact({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingBackReact> createState() => _FloatingBackReactState();
}

class _FloatingBackReactState extends State<_FloatingBackReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Volver',
      child: AnimatedScale(
        duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
        scale: _pressed ? 0.92 : 1,
        child: DecoratedBox(
          key: const ValueKey<String>('busqueda-react-back-shadow'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            key: const ValueKey<String>('busqueda-react-back-material'),
            color: Theme.of(context).colorScheme.surface,
            shape: CircleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey<String>('busqueda-react-back'),
              onTap: widget.onTap,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 45,
                height: 45,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitSearchTitleReact extends StatelessWidget {
  const _SplitSearchTitleReact({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('split-$title-$subtitle'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : MovimientoApp.entrada,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - progress)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: compact ? 32 : 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
              height: 0.98,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF579DFF), Color(0xFFA78BFA), Color(0xFF36B37E)],
            ).createShader(bounds),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontSize: compact ? 20 : 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactSectionTitle extends StatelessWidget {
  const _ReactSectionTitle({required this.primary, required this.accent});

  final String primary;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
      height: 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primary, style: style),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF579DFF), Color(0xFFA78BFA)],
          ).createShader(bounds),
          child: Text(accent, style: style?.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

// La entrada conserva los elementos y sus posiciones al retirar el skeleton.
// Sólo cambia la opacidad del contenido; la barra pertenece a otra capa.
class _EntradaMenuReact extends StatefulWidget {
  const _EntradaMenuReact({
    super.key,
    required this.lista,
    required this.orden,
    required this.child,
  });

  final bool lista;
  final int orden;
  final Widget child;

  @override
  State<_EntradaMenuReact> createState() => _EntradaMenuReactState();
}

class _EntradaMenuReactState extends State<_EntradaMenuReact>
    with SingleTickerProviderStateMixin {
  late final _reloj = AnimationController(vsync: this);
  bool _iniciado = false;
  bool _reducido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducido = MediaQuery.disableAnimationsOf(context);
    _reloj.duration = _reducido
        ? Duration.zero
        : MovimientoApp.entrada + Duration(milliseconds: widget.orden * 25);
    if (_reducido || !widget.lista) {
      _reloj.value = 1;
    } else if (!_iniciado) {
      _reloj.forward();
    }
    _iniciado = true;
  }

  @override
  void didUpdateWidget(_EntradaMenuReact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.lista && widget.lista && !_reducido) {
      _reloj.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _reloj,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: MovimientoApp.curva.transform(_reloj.value),
      child: child,
    ),
  );
}

class _AccessMagicBentoReact extends StatelessWidget {
  const _AccessMagicBentoReact({required this.actions, required this.onTap});

  final List<_SearchAction> actions;
  final ValueChanged<_SearchAction> onTap;

  @override
  Widget build(BuildContext context) {
    final byTitle = <String, _SearchAction>{
      for (final action in actions) action.title: action,
    };
    final calendar = byTitle['Calendario']!;
    final exams = byTitle['Exámenes']!;
    final plan = byTitle['Plan completo']!;
    final subjects = byTitle['Mis materias']!;
    final data = byTitle['Datos']!;
    return Column(
      key: const ValueKey<String>('busqueda-react-magic-bento'),
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: _MagicAccessCardReact(
                action: calendar,
                height: 148,
                colors: const [Color(0xFF063970), Color(0xFF201650)],
                onTap: () => onTap(calendar),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _MagicAccessCardReact(
                action: exams,
                height: 148,
                colors: const [Color(0xFF0B3A4C), Color(0xFF122335)],
                onTap: () => onTap(exams),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _MagicAccessCardReact(
                action: data,
                height: 148,
                colors: const [Color(0xFF3A285A), Color(0xFF1D203D)],
                onTap: () => onTap(data),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: _MagicAccessCardReact(
                action: subjects,
                height: 148,
                colors: const [Color(0xFF0E4A3A), Color(0xFF102D38)],
                onTap: () => onTap(subjects),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MagicAccessCardReact(
          action: plan,
          height: 104,
          horizontal: true,
          colors: const [Color(0xFF322846), Color(0xFF182238)],
          onTap: () => onTap(plan),
        ),
      ],
    );
  }
}

class _MagicAccessCardReact extends StatelessWidget {
  const _MagicAccessCardReact({
    required this.action,
    required this.height,
    required this.colors,
    required this.onTap,
    this.horizontal = false,
  });

  final _SearchAction action;
  final double height;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final accent = reactTheme.decorativeAccent(colors.first);
    final foreground = reactTheme.isDark
        ? const Color(0xFFF2F4FF)
        : reactTheme.text;
    final secondary = reactTheme.isDark
        ? const Color(0xFFD4DBEC)
        : reactTheme.textMuted;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodySmall;
    final scaler = MediaQuery.textScalerOf(context);
    final labelsHeight =
        (scaler.scale(titleStyle?.fontSize ?? 16) * 1.05).ceilToDouble() * 2 +
        4 +
        (scaler.scale(subtitleStyle?.fontSize ?? 12) * 1.15).ceilToDouble() *
            (horizontal ? 1 : 2);
    final cardHeight = math.max(
      height,
      labelsHeight + 40 + (horizontal ? 0 : 54),
    );
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reactTheme.isDark
            ? Colors.white.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10),
        border: Border.all(
          color: reactTheme.isDark
              ? Colors.white.withValues(alpha: 0.28)
              : accent.withValues(alpha: 0.62),
        ),
      ),
      child: Icon(action.icon, color: foreground, size: 21),
    );
    final labels = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          action.title.toLowerCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          action.subtitle.toLowerCase(),
          maxLines: horizontal ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle?.copyWith(color: secondary, height: 1.15),
        ),
      ],
    );
    return ToqueMovimientoApp(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            key: ValueKey<String>('busqueda-react-access-${action.title}'),
            height: cardHeight,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: reactTheme.cardGradient(colors),
              ),
              border: Border.all(
                color: reactTheme.isDark
                    ? const Color(0xFF687386)
                    : accent.withValues(alpha: 0.62),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: reactTheme.isDark ? 0.26 : 0.10,
                  ),
                  blurRadius: 24,
                  spreadRadius: -8,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: horizontal
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(child: labels),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [icon, const Spacer(), labels],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ToolsDockReact extends StatelessWidget {
  const _ToolsDockReact({required this.actions, required this.onTap});

  final List<_SearchAction> actions;
  final ValueChanged<_SearchAction> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('busqueda-react-tools-dock'),
      height: math.max(
        110,
        52 +
            MediaQuery.textScalerOf(context).scale(
                  Theme.of(context).textTheme.labelSmall?.fontSize ?? 11,
                ) *
                2.1,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _ToolDockItemReact(
          action: actions[index],
          onTap: () => onTap(actions[index]),
        ),
      ),
    );
  }
}

class _ToolDockItemReact extends StatelessWidget {
  const _ToolDockItemReact({required this.action, required this.onTap});

  final _SearchAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return ToqueMovimientoApp(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            key: ValueKey<String>('busqueda-react-tool-${action.title}'),
            width: 98 * scale.clamp(1.0, 1.65),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: reactTheme.isDark ? const Color(0xFF191C25) : Colors.white,
              border: Border.all(
                color: reactTheme.isDark
                    ? const Color(0xFF687386)
                    : reactTheme.border,
              ),
              boxShadow: reactTheme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: reactTheme.shadow,
                        blurRadius: 18,
                        spreadRadius: -8,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: reactTheme.isDark
                      ? const Color(0xFF85B8FF)
                      : const Color(0xFF0C66E4),
                ),
                const SizedBox(height: 8),
                Text(
                  action.title.toLowerCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: reactTheme.isDark
                        ? const Color(0xFFF2F4FF)
                        : reactTheme.text,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SageCardNavReact extends StatelessWidget {
  const _SageCardNavReact({
    required this.actions,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  final List<_SearchAction> actions;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<_SearchAction> onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final reactTheme = context.reactTheme;
    final actionGrid = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: width,
                      child: _SageActionReact(
                        action: action,
                        onTap: () => onTap(action),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    return ReactGlassBlur(
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        key: const ValueKey<String>('busqueda-react-sage-card'),
        duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF579DFF), Color(0xFFA78BFA), Color(0xFF36B37E)],
          ),
        ),
        child: Container(
          key: const ValueKey<String>('busqueda-react-sage-surface'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: reactTheme.sageGradient(),
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(29),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'assets/sage_wordmark_react.png',
                                width: 112,
                                height: 36,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                color: reactTheme.isDark
                                    ? null
                                    : reactTheme.wordmark,
                                colorBlendMode: BlendMode.srcIn,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(width: 112, height: 36),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              expanded
                                  ? 'elegí una acción académica'
                                  : 'portal, sesión y sincronización',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: reactTheme.muted(0.82)),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        duration: reduceMotion
                            ? Duration.zero
                            : MovimientoApp.respuesta,
                        turns: expanded ? 0.125 : 0,
                        child: Icon(Icons.add_rounded, color: reactTheme.text),
                      ),
                    ],
                  ),
                ),
              ),
              if (reduceMotion)
                expanded
                    ? actionGrid
                    : const SizedBox(width: double.infinity, height: 0)
              else
                AnimatedCrossFade(
                  duration: MovimientoApp.respuesta,
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: actionGrid,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SageActionReact extends StatelessWidget {
  const _SageActionReact({required this.action, required this.onTap});

  final _SearchAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final accent = switch (action.title) {
      'Sincronizar con SAGE' => const Color(0xFF6554C0),
      'Cerrar sesión de SAGE' => const Color(0xFF00A3BF),
      'Desincronizar trayectoria' => const Color(0xFFC9372C),
      _ => const Color(0xFF0C66E4),
    };
    final iconColor = action.enabled ? accent : accent.withValues(alpha: 0.38);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          key: ValueKey<String>('busqueda-react-sage-action-${action.title}'),
          height: 118,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: reactTheme.isDark
                ? reactTheme.neutralOverlay(action.enabled ? 0.07 : 0.025)
                : null,
            gradient: reactTheme.isDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(Colors.white, accent, 0.075)!,
                      Colors.white,
                      Colors.white,
                      Color.lerp(Colors.white, accent, 0.03)!,
                    ],
                  ),
            border: Border.all(
              color: reactTheme.isDark
                  ? reactTheme.neutralOverlay(action.enabled ? 0.10 : 0.05)
                  : accent.withValues(alpha: action.enabled ? 0.38 : 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(
                    alpha: action.enabled ? 0.10 : 0.05,
                  ),
                  border: Border.all(
                    color: iconColor.withValues(
                      alpha: action.enabled ? 0.30 : 0.12,
                    ),
                  ),
                ),
                child: Icon(
                  action.enabled ? action.icon : Icons.lock_outline_rounded,
                  key: ValueKey<String>(
                    'busqueda-react-sage-action-icon-${action.title}',
                  ),
                  color: iconColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                action.title.toLowerCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: action.enabled
                      ? reactTheme.foreground(0.90)
                      : reactTheme.muted(0.48),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle.toLowerCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: action.enabled
                      ? reactTheme.muted(0.72)
                      : reactTheme.muted(0.38),
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _tituloInstitucionReact(BuildContext context) =>
    temaHerramientasApp(context).textTheme.titleLarge!.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.15,
    );

double _altoTextoInstitucionReact(
  BuildContext context,
  String texto,
  TextStyle estilo,
  double ancho, {
  int maxLines = 3,
}) {
  final painter = TextPainter(
    text: TextSpan(text: texto, style: estilo),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: maxLines,
  )..layout(maxWidth: math.max(1, ancho));
  final height = painter.height.ceilToDouble();
  painter.dispose();
  return height;
}

double _alturaAccionInstitucionReact(BuildContext context, double ancho) {
  final style = temaHerramientasApp(
    context,
  ).textTheme.labelMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w700);
  final texto = _altoTextoInstitucionReact(
    context,
    'calendario',
    style,
    (ancho - 10) / 2 - 48,
    maxLines: 2,
  );
  return math.max(48, texto + 20);
}

double _alturaCarruselInstitucionesReact(
  BuildContext context,
  double fraccionPagina,
  List<CareerInfo> careers,
) {
  final theme = temaHerramientasApp(context);
  final ancho = math.max(
    1.0,
    MediaQuery.sizeOf(context).width * fraccionPagina - 50,
  );
  var contenido = 0.0;
  for (final career in careers) {
    final title = _altoTextoInstitucionReact(
      context,
      career.nombre,
      _tituloInstitucionReact(context),
      ancho - 64,
    );
    final institutions = kInstitutions.where(
      (item) => !item.hidden && item.careerId == career.id,
    );
    final subtitle = _altoTextoInstitucionReact(
      context,
      institutions.isEmpty
          ? 'Institución sin asignar'
          : institutions.map((item) => item.nombre).join(' · '),
      theme.textTheme.bodySmall!.copyWith(height: 1.35),
      ancho,
    );
    contenido = math.max(contenido, math.max(52, title) + 12 + subtitle);
  }
  return 50 +
      contenido +
      18 +
      2 * _alturaAccionInstitucionReact(context, ancho) +
      10;
}

class _CareerDepthCarouselReact extends StatelessWidget {
  const _CareerDepthCarouselReact({
    required this.controller,
    required this.careers,
    required this.onPageChanged,
    required this.onOpen,
  });

  final PageController controller;
  final List<CareerInfo> careers;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('busqueda-react-career-carousel'),
      height: _alturaCarruselInstitucionesReact(
        context,
        controller.viewportFraction,
        careers,
      ),
      child: PageView.builder(
        controller: controller,
        itemCount: careers.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final career = careers[index];
          final institutions = kInstitutions
              .where(
                (institution) =>
                    !institution.hidden && institution.careerId == career.id,
              )
              .toList(growable: false);
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              var page = index.toDouble();
              if (controller.hasClients &&
                  controller.position.hasContentDimensions) {
                page = controller.page ?? controller.initialPage.toDouble();
              }
              final delta = MediaQuery.disableAnimationsOf(context)
                  ? 0.0
                  : (page - index).abs().clamp(0.0, 1.0);
              final scale = 1 - delta * 0.04;
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: 1 - delta * 0.16, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _CareerDepthCardReact(
                career: career,
                institutions: institutions,
                onOpen: onOpen,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CareerDepthCardReact extends StatelessWidget {
  const _CareerDepthCardReact({
    required this.career,
    required this.institutions,
    required this.onOpen,
  });

  final CareerInfo career;
  final List<InstitutionInfo> institutions;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) => TemaHerramientasApp(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final accent = _careerAccent(career.id);
      final logo = _careerWatermarkAsset(career);
      final acciones = [
        (
          'plan',
          Icons.account_tree_rounded,
          DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.seccion,
            seccion: 2,
            careerId: career.id,
          ),
        ),
        (
          'mesas',
          Icons.event_note_rounded,
          DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.seccion,
            seccion: 1,
            careerId: career.id,
          ),
        ),
        (
          'calendario',
          Icons.calendar_month_rounded,
          DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.calendario,
            careerId: career.id,
          ),
        ),
        (
          'diseños',
          Icons.auto_stories_rounded,
          DestinoBusquedaAtlassian(
            tipo: TipoDestinoBusquedaAtlassian.disenos,
            careerId: career.id,
          ),
        ),
      ];
      return Container(
        key: ValueKey<String>('busqueda-react-career-${career.id}'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                accent.withValues(alpha: dark ? 0.12 : 0.07),
                scheme.surface,
              ),
              scheme.surface,
            ],
          ),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: logo == null
                      ? const Icon(
                          Icons.school_outlined,
                          color: Color(0xFF173D8F),
                        )
                      : Image.asset(
                          logo,
                          fit: BoxFit.contain,
                          cacheWidth:
                              (52 * MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF173D8F),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    career.nombre,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _tituloInstitucionReact(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              institutions.isEmpty
                  ? 'Institución sin asignar'
                  : institutions.map((item) => item.nombre).join(' · '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const Spacer(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final height = _alturaAccionInstitucionReact(
                  context,
                  constraints.maxWidth,
                );
                return Column(
                  children: [
                    for (var fila = 0; fila < 2; fila++) ...[
                      if (fila > 0) const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var columna = 0; columna < 2; columna++) ...[
                            if (columna > 0) const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: height,
                                child: _AccionInstitucionReact(
                                  key: ValueKey(
                                    'busqueda-react-career-${career.id}-${acciones[fila * 2 + columna].$1}',
                                  ),
                                  label: acciones[fila * 2 + columna].$1,
                                  icon: acciones[fila * 2 + columna].$2,
                                  onTap: () =>
                                      onOpen(acciones[fila * 2 + columna].$3),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _AccionInstitucionReact extends StatelessWidget {
  const _AccionInstitucionReact({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToqueMovimientoApp(
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _careerWatermarkAsset(CareerInfo career) {
  switch (career.id) {
    case 'historia':
    case 'geografia':
    case 'politica':
      return 'assets/career_icons/logo_pscs_overlay_circular.png';
    case 'artes_visuales':
    case 'musica':
      return 'assets/career_icons/logo_artes_circular.png';
    default:
      return career.iconAsset;
  }
}

class _MiniGlassActionReact extends StatelessWidget {
  const _MiniGlassActionReact({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final highlight = reactTheme.isDark
        ? const Color(0xFF85B8FF)
        : const Color(0xFF0C66E4);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: highlight.withValues(alpha: reactTheme.isDark ? 0.28 : 0.16),
            blurRadius: 10,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: Material(
        color: reactTheme.isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: reactTheme.isDark
                  ? reactTheme.neutralOverlay(0.07)
                  : Colors.white,
              border: Border.all(
                color: highlight.withValues(
                  alpha: reactTheme.isDark ? 0.72 : 0.48,
                ),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: reactTheme.text),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: reactTheme.foreground(0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleSuggestionsReact extends StatelessWidget {
  const _BubbleSuggestionsReact({
    required this.recent,
    required this.suggested,
    required this.onTap,
  });

  final List<String> recent;
  final List<String> suggested;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <(String, bool)>[
      for (final item in recent) (item, true),
      for (final item in suggested) (item, false),
    ];
    return Wrap(
      key: const ValueKey<String>('busqueda-react-bubbles'),
      spacing: 8,
      runSpacing: 9,
      children: [
        for (var index = 0; index < items.length; index++)
          _StaggeredRevealReact(
            index: index,
            child: _SuggestionBubbleReact(
              text: items[index].$1,
              recent: items[index].$2,
              onTap: () => onTap(items[index].$1),
            ),
          ),
      ],
    );
  }
}

class _SuggestionBubbleReact extends StatelessWidget {
  const _SuggestionBubbleReact({
    required this.text,
    required this.recent,
    required this.onTap,
  });

  final String text;
  final bool recent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final accent = recent ? const Color(0xFF6554C0) : const Color(0xFF0C66E4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: reactTheme.suggestionGradient(accent),
            ),
            border: Border.all(color: reactTheme.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 78,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  recent ? Icons.history_rounded : Icons.north_west_rounded,
                  size: 15,
                  color: recent
                      ? (reactTheme.isDark
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF6554C0))
                      : (reactTheme.isDark
                            ? const Color(0xFF85B8FF)
                            : const Color(0xFF0C66E4)),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GooeyFilterReact extends StatelessWidget {
  const _GooeyFilterReact({
    required this.selected,
    required this.model,
    required this.onSelected,
  });

  final _ReactSearchCategory selected;
  final _SearchModel model;
  final ValueChanged<_ReactSearchCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    const labels = <_ReactSearchCategory, String>{
      _ReactSearchCategory.all: 'todo',
      _ReactSearchCategory.actions: 'accesos',
      _ReactSearchCategory.subjects: 'materias',
      _ReactSearchCategory.events: 'mesas',
      _ReactSearchCategory.careers: 'carreras',
      _ReactSearchCategory.profile: 'datos',
    };
    int count(_ReactSearchCategory category) => switch (category) {
      _ReactSearchCategory.all =>
        model.actions.length +
            model.subjects.length +
            model.events.length +
            model.careers.length +
            model.profile.length,
      _ReactSearchCategory.actions => model.actions.length,
      _ReactSearchCategory.subjects => model.subjects.length,
      _ReactSearchCategory.events => model.events.length,
      _ReactSearchCategory.careers => model.careers.length,
      _ReactSearchCategory.profile => model.profile.length,
    };
    return SizedBox(
      key: const ValueKey<String>('busqueda-react-gooey-filter'),
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _ReactSearchCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = _ReactSearchCategory.values[index];
          final active = category == selected;
          final itemCount = count(category);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey<String>('busqueda-react-filter-${category.name}'),
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : MovimientoApp.respuesta,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF0C66E4), Color(0xFF7C66E8)],
                        )
                      : null,
                  color: active ? null : reactTheme.neutralOverlay(0.04),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF85B8FF).withValues(alpha: 0.72)
                        : reactTheme.border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF0C66E4,
                            ).withValues(alpha: 0.24),
                            blurRadius: 16,
                            spreadRadius: -4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[category]!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active
                            ? Colors.white
                            : reactTheme.foreground(0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$itemCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active
                            ? Colors.white.withValues(alpha: 0.82)
                            : reactTheme.muted(0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCountOrbReact extends StatelessWidget {
  const _ResultCountOrbReact({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0C66E4), Color(0xFF6554C0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C66E4).withValues(alpha: 0.28),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ResultSectionHeadingReact extends StatelessWidget {
  const _ResultSectionHeadingReact({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.reactTheme.muted(0.68),
          ),
        ),
      ],
    );
  }
}

class _SpotlightBestMatchReact extends StatefulWidget {
  const _SpotlightBestMatchReact({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SpotlightBestMatchReact> createState() =>
      _SpotlightBestMatchReactState();
}

class _SpotlightBestMatchReactState extends State<_SpotlightBestMatchReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final reactTheme = context.reactTheme;
    return AnimatedScale(
      duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(28),
          child: ReactGlassBlur(
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: reactTheme.spotlightGradient(),
                ),
                border: Border.all(
                  color: const Color(
                    0xFF579DFF,
                  ).withValues(alpha: reactTheme.isDark ? 0.42 : 0.62),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF0C66E4,
                    ).withValues(alpha: reactTheme.isDark ? 0.20 : 0.08),
                    blurRadius: 26,
                    spreadRadius: -9,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reactTheme.neutralOverlay(0.08),
                    ),
                    child: Icon(
                      widget.icon,
                      color: reactTheme.isDark
                          ? const Color(0xFF85B8FF)
                          : const Color(0xFF0C66E4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.eyebrow,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: const Color(0xFFA78BFA),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: reactTheme.text,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: reactTheme.muted(0.78)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: reactTheme.text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredRevealReact extends StatelessWidget {
  const _StaggeredRevealReact({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      EntradaContenidoApp(orden: index, child: child);
}

class _ActionResultReact extends StatelessWidget {
  const _ActionResultReact({
    required this.action,
    required this.index,
    required this.onTap,
  });

  final _SearchAction action;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (action.group) {
      _ActionGroup.navigation => const Color(0xFF579DFF),
      _ActionGroup.tools => const Color(0xFF36B37E),
      _ActionGroup.sage => const Color(0xFFA78BFA),
      _ActionGroup.dynamic => const Color(0xFFF5CD47),
    };
    return _GlassResultShellReact(
      onTap: onTap,
      accent: accent,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(action.icon, color: accent, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.reactTheme.muted(0.76),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: accent),
        ],
      ),
    );
  }
}

class _CareerResultReact extends StatelessWidget {
  const _CareerResultReact({
    required this.result,
    required this.index,
    required this.onOpen,
  });

  final _CareerResult result;
  final int index;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = _careerAccent(result.career.id);
    return _GlassResultShellReact(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.career.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (result.institutions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.institutions.map((item) => item.nombre).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.reactTheme.muted(0.74),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _MiniGlassActionReact(
                label: 'plan',
                icon: Icons.account_tree_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.seccion,
                    seccion: 2,
                    careerId: result.career.id,
                  ),
                ),
              ),
              _MiniGlassActionReact(
                label: 'mesas',
                icon: Icons.event_note_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.seccion,
                    seccion: 1,
                    careerId: result.career.id,
                  ),
                ),
              ),
              _MiniGlassActionReact(
                label: 'calendario',
                icon: Icons.calendar_month_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.calendario,
                    careerId: result.career.id,
                  ),
                ),
              ),
              _MiniGlassActionReact(
                label: 'diseños',
                icon: Icons.auto_stories_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.disenos,
                    careerId: result.career.id,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectResultReact extends StatelessWidget {
  const _SubjectResultReact({
    required this.result,
    required this.index,
    required this.onOpen,
  });

  final _ConnectedSubjectResult result;
  final int index;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = result.trajectory.isNotEmpty
        ? _subjectStateColor(result.trajectory.first.subject.estado)
        : const Color(0xFF579DFF);
    return _GlassResultShellReact(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  result.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
              if (result.trajectory.firstOrNull?.subject.nota
                      ?.trim()
                      .isNotEmpty ==
                  true)
                Text(
                  _compactGradeReact(result.trajectory.first.subject.nota!),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (result.trajectory.isNotEmpty)
                _SourceBadgeReact(label: 'trayectoria', color: accent),
              if (result.plans.isNotEmpty)
                const _SourceBadgeReact(
                  label: 'plan',
                  color: Color(0xFF579DFF),
                ),
              if (result.designs.isNotEmpty)
                const _SourceBadgeReact(
                  label: 'diseño',
                  color: Color(0xFF36B37E),
                ),
              if (result.events.isNotEmpty)
                const _SourceBadgeReact(
                  label: 'mesas',
                  color: Color(0xFFF5CD47),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final occurrence in result.trajectory.take(1))
                _MiniGlassActionReact(
                  label: occurrence.subject.estado.etiqueta.toLowerCase(),
                  icon: Icons.person_search_rounded,
                  onTap: () => onOpen(
                    DestinoBusquedaAtlassian(
                      tipo: TipoDestinoBusquedaAtlassian.detalleTrayectoria,
                      materiaTrayectoria: occurrence.subject,
                      carreraTrayectoria: occurrence.career,
                    ),
                  ),
                ),
              for (final occurrence in result.plans.take(2))
                _MiniGlassActionReact(
                  label:
                      'plan ${shortCareerNameAtlassian(occurrence.career.id)}',
                  icon: Icons.account_tree_rounded,
                  onTap: () => onOpen(
                    DestinoBusquedaAtlassian(
                      tipo: TipoDestinoBusquedaAtlassian.detallePlan,
                      career: occurrence.career,
                      materiaPlan: occurrence.subject,
                      materiasPlan: occurrence.allSubjects,
                    ),
                  ),
                ),
              if (result.plans.isNotEmpty)
                _MiniGlassActionReact(
                  label: 'escenarios',
                  icon: Icons.auto_graph_rounded,
                  onTap: () {
                    final occurrence = result.plans.first;
                    unawaited(
                      onOpen(
                        DestinoBusquedaAtlassian(
                          tipo: TipoDestinoBusquedaAtlassian.escenarios,
                          careerId: occurrence.career.id,
                          year: occurrence.subject.anio,
                          materiaPlan: occurrence.subject,
                        ),
                      ),
                    );
                  },
                ),
              for (final content in result.designs.take(1))
                _MiniGlassActionReact(
                  label: 'diseño',
                  icon: Icons.auto_stories_rounded,
                  onTap: () {
                    final planOccurrence = result.plans
                        .where((item) => item.career.id == 'historia')
                        .firstOrNull;
                    final subject =
                        planOccurrence?.subject ??
                        materiaDesdeContenidoAtlassian(content);
                    unawaited(
                      onOpen(
                        DestinoBusquedaAtlassian(
                          tipo: TipoDestinoBusquedaAtlassian.detalleDiseno,
                          career:
                              planOccurrence?.career ??
                              kCareers.firstWhere(
                                (item) => item.id == 'historia',
                              ),
                          materiaPlan: subject,
                          contenidoCurricular: content,
                        ),
                      ),
                    );
                  },
                ),
              for (final event in result.events.take(1))
                _MiniGlassActionReact(
                  label: event.fechaVigente == null
                      ? 'mesa'
                      : formatoFechaAtlassian(event.fechaVigente),
                  icon: Icons.event_available_rounded,
                  onTap: () => onOpen(
                    DestinoBusquedaAtlassian(
                      tipo: TipoDestinoBusquedaAtlassian.detalleExamen,
                      evento: event,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamResultReact extends StatelessWidget {
  const _ExamResultReact({
    required this.result,
    required this.index,
    required this.onOpen,
  });

  final _ExamResult result;
  final int index;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    final event = result.event;
    const accent = Color(0xFFF5CD47);
    return _GlassResultShellReact(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.materia,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${careerNameAtlassian(event.careerId)} · '
            '${formatExamInstanceAtlassian(event.instancia)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.reactTheme.muted(0.74),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatoFechaHoraAtlassian(event.fechaVigente, event.horaVigente),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.reactTheme.foreground(0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            children: [
              _MiniGlassActionReact(
                label: 'abrir mesa',
                icon: Icons.open_in_new_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.detalleExamen,
                    evento: event,
                  ),
                ),
              ),
              _MiniGlassActionReact(
                label: 'calendario',
                icon: Icons.calendar_month_rounded,
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.calendario,
                    careerId: event.careerId,
                    fecha: event.fechaVigente,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileResultReact extends StatelessWidget {
  const _ProfileResultReact({
    required this.result,
    required this.index,
    required this.onTap,
  });

  final _ProfileResult result;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassResultShellReact(
      onTap: onTap,
      accent: const Color(0xFFA78BFA),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Color(0xFFA78BFA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.label.toLowerCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.reactTheme.muted(0.70),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _GlassResultShellReact extends StatefulWidget {
  const _GlassResultShellReact({
    required this.child,
    required this.accent,
    this.onTap,
  });

  final Widget child;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<_GlassResultShellReact> createState() => _GlassResultShellReactState();
}

class _GlassResultShellReactState extends State<_GlassResultShellReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final reactTheme = context.reactTheme;
    final content = ReactGlassBlur(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: reactTheme.resultGradient(widget.accent, pressed: _pressed),
          ),
          border: Border.all(
            color: widget.accent.withValues(alpha: _pressed ? 0.62 : 0.42),
          ),
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return content;
    return AnimatedScale(
      duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
      scale: _pressed ? 0.987 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(24),
          child: content,
        ),
      ),
    );
  }
}

class _SourceBadgeReact extends StatelessWidget {
  const _SourceBadgeReact({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoResultsReact extends StatelessWidget {
  const _NoResultsReact({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    const suggestions = <String>['Historia', 'Aprobadas', 'Calendario', 'SAGE'];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: reactTheme.noResultsGradient()),
        border: Border.all(color: reactTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xFF8993A4),
          ),
          const SizedBox(height: 10),
          Text(
            'probá con otra idea',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final suggestion in suggestions)
                _SuggestionBubbleReact(
                  text: suggestion,
                  recent: false,
                  onTap: () => onSuggestion(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _careerAccent(String careerId) => switch (careerId) {
  'historia' => const Color(0xFF579DFF),
  'geografia' => const Color(0xFF36B37E),
  'politica' => const Color(0xFFA78BFA),
  'artes_visuales' => const Color(0xFFFF8F73),
  'musica' => const Color(0xFFF5CD47),
  _ => const Color(0xFF85B8FF),
};

Color _subjectStateColor(EstadoMateriaSageLaboratorio state) => switch (state) {
  EstadoMateriaSageLaboratorio.aprobada => const Color(0xFF36B37E),
  EstadoMateriaSageLaboratorio.cursando => const Color(0xFF579DFF),
  EstadoMateriaSageLaboratorio.regular => const Color(0xFFA78BFA),
  EstadoMateriaSageLaboratorio.noRegularizada => const Color(0xFFF5CD47),
  EstadoMateriaSageLaboratorio.desconocida => const Color(0xFF8993A4),
};

String _compactGradeReact(String raw) {
  final parsed = double.tryParse(raw.replaceAll(',', '.'));
  if (parsed == null) return raw;
  if (parsed == parsed.roundToDouble()) return parsed.round().toString();
  return parsed.toStringAsFixed(1);
}

class _SearchModel {
  const _SearchModel({
    required this.actions,
    required this.careers,
    required this.subjects,
    required this.events,
    required this.profile,
  });

  final List<_SearchAction> actions;
  final List<_CareerResult> careers;
  final List<_ConnectedSubjectResult> subjects;
  final List<_ExamResult> events;
  final List<_ProfileResult> profile;
}

enum _ActionGroup { navigation, tools, sage, dynamic }

class _SearchAction {
  const _SearchAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
    required this.group,
    required this.destination,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String keywords;
  final _ActionGroup group;
  final DestinoBusquedaAtlassian destination;
  final bool enabled;
}

class _ScoredAction {
  const _ScoredAction({required this.action, required this.score});

  final _SearchAction action;
  final int score;
}

class _CareerResult {
  const _CareerResult({
    required this.career,
    required this.institutions,
    required this.score,
  });

  final CareerInfo career;
  final List<InstitutionInfo> institutions;
  final int score;
}

class _PlanCarreraBusqueda {
  const _PlanCarreraBusqueda({required this.career, required this.plan});

  final CareerInfo career;
  final DatosPlan plan;
}

class _SubjectClusterBuilder {
  _SubjectClusterBuilder({required this.title});

  final String title;
  final List<_PlanSubjectOccurrence> plans = <_PlanSubjectOccurrence>[];
  final List<_TrajectorySubjectOccurrence> trajectory =
      <_TrajectorySubjectOccurrence>[];
  final List<ContenidoCurricular> designs = <ContenidoCurricular>[];
  final List<EventoExamen> events = <EventoExamen>[];
}

class _PlanSubjectOccurrence {
  const _PlanSubjectOccurrence({
    required this.career,
    required this.subject,
    required this.allSubjects,
  });

  final CareerInfo career;
  final Materia subject;
  final List<Materia> allSubjects;
}

class _TrajectorySubjectOccurrence {
  const _TrajectorySubjectOccurrence({
    required this.careerIndex,
    required this.career,
    required this.subject,
  });

  final int careerIndex;
  final CarreraTrayectoriaSageLaboratorio career;
  final MateriaTrayectoriaSageLaboratorio subject;
}

class _ConnectedSubjectResult {
  const _ConnectedSubjectResult({
    required this.title,
    required this.plans,
    required this.trajectory,
    required this.designs,
    required this.events,
    required this.score,
  });

  final String title;
  final List<_PlanSubjectOccurrence> plans;
  final List<_TrajectorySubjectOccurrence> trajectory;
  final List<ContenidoCurricular> designs;
  final List<EventoExamen> events;
  final int score;
}

class _ExamResult {
  const _ExamResult({required this.event, required this.score});

  final EventoExamen event;
  final int score;
}

class _ProfileResult {
  const _ProfileResult({
    required this.label,
    required this.value,
    required this.score,
  });

  final String label;
  final String value;
  final int score;
}
