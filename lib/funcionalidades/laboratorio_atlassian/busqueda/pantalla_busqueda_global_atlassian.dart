import 'dart:async';
import 'dart:math' as math;

import 'package:correlativas_historia/compartido/proveedores/datos_catalogo.dart';
import 'package:correlativas_historia/compartido/utilidades/sanitizar_texto.dart';
import 'package:correlativas_historia/datos/cargador_fuente_html.dart';
import 'package:correlativas_historia/funcionalidades/curriculum/proveedores/proveedores_curriculum.dart';
import 'package:correlativas_historia/funcionalidades/examenes/modelos/evento_examen.dart';
import 'package:correlativas_historia/funcionalidades/examenes/proveedores/proveedores_examenes.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/componentes/componentes_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/utilidades_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/modelos/contenido_curricular.dart';
import 'package:correlativas_historia/modelos/materia.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/navegacion/barra_busqueda_app.dart';
import 'modelos_busqueda_atlassian.dart';

class PantallaBusquedaGlobalAtlassian extends ConsumerStatefulWidget {
  const PantallaBusquedaGlobalAtlassian({
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
  ConsumerState<PantallaBusquedaGlobalAtlassian> createState() =>
      _PantallaBusquedaGlobalAtlassianState();
}

class _PantallaBusquedaGlobalAtlassianState
    extends ConsumerState<PantallaBusquedaGlobalAtlassian> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<_PlanCarreraBusqueda> _planes = <_PlanCarreraBusqueda>[];
  final List<String> _recentQueries = <String>[];

  bool _loadingPlans = true;
  String _query = '';
  Timer? _debounce;
  Animation<double>? _entradaRuta;
  bool _focoInicialSolicitado = false;

  _SearchModel? _cachedModel;
  List<EventoExamen>? _cachedExams;
  TrayectoriaSageLaboratorio? _cachedTrajectory;
  List<ContenidoCurricular>? _cachedCurricular;
  String? _lastQueryKey;

  List<CareerInfo> get _visibleCareers =>
      kCareers.where((career) => !career.hidden).toList(growable: false);

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlans());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focoInicialSolicitado) return;
    final entrada = ModalRoute.of(context)?.animation;
    if (!identical(_entradaRuta, entrada)) {
      _entradaRuta?.removeStatusListener(_estadoEntradaRuta);
      _entradaRuta = entrada;
    }
    if (entrada == null || entrada.status == AnimationStatus.completed) {
      _solicitarFocoInicial();
    } else {
      entrada.removeStatusListener(_estadoEntradaRuta);
      entrada.addStatusListener(_estadoEntradaRuta);
    }
  }

  void _estadoEntradaRuta(AnimationStatus estado) {
    if (estado == AnimationStatus.completed) _solicitarFocoInicial();
  }

  void _solicitarFocoInicial() {
    if (_focoInicialSolicitado) return;
    _focoInicialSolicitado = true;
    _entradaRuta?.removeStatusListener(_estadoEntradaRuta);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _focusNode.requestFocus();
      }
    });
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
      _loadingPlans = false;
    });
  }

  @override
  void dispose() {
    _entradaRuta?.removeStatusListener(_estadoEntradaRuta);
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _query = value);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
    _focusNode.requestFocus();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
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

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(proveedorTodosLosExamenes);
    final curricularAsync = ref.watch(proveedorContenidosCurriculares);
    final exams = examsAsync.value ?? const <EventoExamen>[];
    final curricular = curricularAsync.value ?? const <ContenidoCurricular>[];
    final loading =
        _loadingPlans || examsAsync.isLoading || curricularAsync.isLoading;

    return ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
      valueListenable: widget.trajectoryListenable,
      builder: (context, trajectory, _) {
        final query = normalizarBusquedaAtlassian(_query);
        final queryKey =
            '$query|${trajectory?.carreras.length}|${exams.length}|${curricular.length}|${_planes.length}';
        if (_cachedModel == null ||
            _lastQueryKey != queryKey ||
            !identical(_cachedExams, exams) ||
            !identical(_cachedTrajectory, trajectory) ||
            !identical(_cachedCurricular, curricular)) {
          _cachedExams = exams;
          _cachedTrajectory = trajectory;
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
        return Theme(
          data: atlassianTheme,
          child: Scaffold(
            backgroundColor: atlassianTheme.scaffoldBackgroundColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      _TopBarAtlassian(
                        loading: loading,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      _FloatingSearchBarAtlassian(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        onSubmitted: (_) => _rememberQuery(),
                        onClear: _clearQuery,
                      ),
                      Expanded(
                        child: query.isEmpty
                            ? _buildLanding(context, trajectory)
                            : _buildResults(context, model, trajectory),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanding(
    BuildContext context,
    TrayectoriaSageLaboratorio? trajectory,
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

    final suggested = <String>[
      'Profesorado de Historia',
      'Antigüedad',
      'Materias aprobadas',
      'Práctica Docente',
      'Mesas de agosto',
      'Diseño curricular',
      'Sincronizar con SAGE',
    ];

    return ListView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const SeparadorTituloAtlassian(title: 'Accesos directos'),
        const SizedBox(height: 10),
        _QuickActionsGrid(
          actions: navigation,
          onTap: (item) => _open(item.destination),
        ),
        const SizedBox(height: 22),
        const SeparadorTituloAtlassian(title: 'Herramientas'),
        const SizedBox(height: 10),
        _QuickActionsGrid(
          actions: tools,
          onTap: (item) => _open(item.destination),
        ),
        const SizedBox(height: 22),
        const SeparadorTituloAtlassian(title: 'SAGE y sesión'),
        const SizedBox(height: 10),
        _ActionListAtlassian(
          actions: sage,
          onTap: (item) => _open(item.destination),
        ),
        const SizedBox(height: 22),
        const SeparadorTituloAtlassian(title: 'Profesorados'),
        const SizedBox(height: 10),
        for (final career in _visibleCareers) ...[
          _CareerSearchCard(
            career: career,
            institutions: kInstitutions
                .where(
                  (institution) =>
                      !institution.hidden && institution.careerId == career.id,
                )
                .toList(growable: false),
            onPlan: () => _open(
              DestinoBusquedaAtlassian(
                tipo: TipoDestinoBusquedaAtlassian.seccion,
                seccion: 2,
                careerId: career.id,
              ),
            ),
            onExams: () => _open(
              DestinoBusquedaAtlassian(
                tipo: TipoDestinoBusquedaAtlassian.seccion,
                seccion: 1,
                careerId: career.id,
              ),
            ),
            onCalendar: () => _open(
              DestinoBusquedaAtlassian(
                tipo: TipoDestinoBusquedaAtlassian.calendario,
                careerId: career.id,
              ),
            ),
            onDesigns: () => _open(
              DestinoBusquedaAtlassian(
                tipo: TipoDestinoBusquedaAtlassian.disenos,
                careerId: career.id,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        const SeparadorTituloAtlassian(title: 'Búsquedas sugeridas'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._recentQueries.map(
              (query) => InputChip(
                avatar: const Icon(Icons.history_rounded, size: 17),
                label: Text(query),
                onPressed: () => _setQuery(query),
              ),
            ),
            ...suggested.map(
              (query) => ActionChip(
                avatar: const Icon(Icons.north_west_rounded, size: 17),
                label: Text(query),
                onPressed: () => _setQuery(query),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    _SearchModel model,
    TrayectoriaSageLaboratorio? trajectory,
  ) {
    final total =
        model.actions.length +
        model.careers.length +
        model.subjects.length +
        model.events.length +
        model.profile.length;

    if (total == 0) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Color(0xFF6B778C),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin coincidencias',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in const [
                  'Historia',
                  'Antigüedad',
                  'Aprobadas',
                  'Calendario',
                  'SAGE',
                ])
                  ActionChip(
                    label: Text(term),
                    onPressed: () => _setQuery(term),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        Text(
          total == 1 ? '1 coincidencia' : '$total coincidencias',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (model.actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SeparadorTituloAtlassian(title: 'Acciones'),
          const SizedBox(height: 8),
          _ActionListAtlassian(
            actions: model.actions,
            onTap: (item) => _open(item.destination),
          ),
        ],
        if (model.careers.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SeparadorTituloAtlassian(title: 'Profesorados'),
          const SizedBox(height: 8),
          for (final result in model.careers) ...[
            _CareerSearchCard(
              career: result.career,
              institutions: result.institutions,
              onPlan: () => _open(
                DestinoBusquedaAtlassian(
                  tipo: TipoDestinoBusquedaAtlassian.seccion,
                  seccion: 2,
                  careerId: result.career.id,
                ),
              ),
              onExams: () => _open(
                DestinoBusquedaAtlassian(
                  tipo: TipoDestinoBusquedaAtlassian.seccion,
                  seccion: 1,
                  careerId: result.career.id,
                ),
              ),
              onCalendar: () => _open(
                DestinoBusquedaAtlassian(
                  tipo: TipoDestinoBusquedaAtlassian.calendario,
                  careerId: result.career.id,
                ),
              ),
              onDesigns: () => _open(
                DestinoBusquedaAtlassian(
                  tipo: TipoDestinoBusquedaAtlassian.disenos,
                  careerId: result.career.id,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (model.subjects.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SeparadorTituloAtlassian(title: 'Materias conectadas'),
          const SizedBox(height: 8),
          for (final subject in model.subjects) ...[
            _ConnectedSubjectCard(result: subject, onOpen: _open),
            const SizedBox(height: 10),
          ],
        ],
        if (model.events.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SeparadorTituloAtlassian(title: 'Mesas y fechas'),
          const SizedBox(height: 8),
          for (final event in model.events) ...[
            _ExamSearchCard(event: event, onOpen: _open),
            const SizedBox(height: 10),
          ],
        ],
        if (model.profile.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SeparadorTituloAtlassian(title: 'Tus datos'),
          const SizedBox(height: 8),
          PanelAtlassian(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < model.profile.length; index++) ...[
                  _ProfileSearchRow(
                    result: model.profile[index],
                    onTap: () => _open(
                      const DestinoBusquedaAtlassian(
                        tipo: TipoDestinoBusquedaAtlassian.seccion,
                        seccion: 4,
                      ),
                    ),
                  ),
                  if (index != model.profile.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
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
        title: 'Inicio',
        subtitle: 'Dashboard y actividad académica',
        icon: Icons.home_outlined,
        keywords: 'inicio principal dashboard trayectoria actividad academica',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 0,
        ),
      ),
      _SearchAction(
        title: 'Exámenes',
        subtitle: 'Mesas, llamados, coloquios y docentes',
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
        subtitle: 'Materias, años y correlatividades',
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
        subtitle: 'Estados de la trayectoria sincronizada',
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
        subtitle: 'Perfil, carreras y sincronización',
        icon: Icons.person_outline_rounded,
        keywords:
            'datos perfil dni documento telefono nacimiento localidad estudiante carrera institucion sincronizacion',
        group: _ActionGroup.navigation,
        destination: const DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.seccion,
          seccion: 4,
        ),
      ),
      _SearchAction(
        title: 'Calendario',
        subtitle: 'Mesas y fechas publicadas',
        icon: Icons.calendar_month_outlined,
        keywords:
            'calendario agenda fecha fechas mes meses enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre mesas',
        group: _ActionGroup.tools,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.calendario,
          careerId: _trajectoryCareerId(trajectory),
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
      const _SearchAction(
        title: 'Salir',
        subtitle: 'Cerrar el laboratorio',
        icon: Icons.close_rounded,
        keywords:
            'salir cerrar cierre x cerrar sesion desconectar laboratorio volver',
        group: _ActionGroup.sage,
        destination: DestinoBusquedaAtlassian(
          tipo: TipoDestinoBusquedaAtlassian.salir,
        ),
      ),
    ];
  }

  List<_SearchAction> _rankActions(
    String query,
    TrayectoriaSageLaboratorio? trajectory,
  ) {
    final actions = <_SearchAction>[..._baseActions(trajectory)];
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
      final score = math.max(
        scoreBusquedaAtlassian(query, action.title) * 2,
        scoreBusquedaAtlassian(
          query,
          '${action.title} ${action.subtitle} ${action.keywords}',
        ),
      );
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

class _TopBarAtlassian extends StatelessWidget {
  const _TopBarAtlassian({required this.loading, required this.onBack});

  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  BotonIconoAtlassian(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Búsqueda y accesos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }
}

class _FloatingSearchBarAtlassian extends StatelessWidget {
  const _FloatingSearchBarAtlassian({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: BarraBusquedaApp(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
    ),
  );
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions, required this.onTap});

  final List<_SearchAction> actions;
  final ValueChanged<_SearchAction> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: _QuickActionCard(
                    action: action,
                    onTap: () => onTap(action),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final _SearchAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color containerColor;
    Color iconColor;
    switch (action.group) {
      case _ActionGroup.navigation:
        containerColor = const Color(
          0xFF0C66E4,
        ).withOpacity(isDark ? 0.25 : 0.08);
        iconColor = isDark ? const Color(0xFF579DFF) : const Color(0xFF0C66E4);
        break;
      case _ActionGroup.tools:
        containerColor = const Color(
          0xFF22C55E,
        ).withOpacity(isDark ? 0.25 : 0.08);
        iconColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
        break;
      case _ActionGroup.sage:
        containerColor = const Color(
          0xFF8B5CF6,
        ).withOpacity(isDark ? 0.25 : 0.08);
        iconColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
        break;
      case _ActionGroup.dynamic:
        containerColor = scheme.primary.withOpacity(isDark ? 0.25 : 0.08);
        iconColor = scheme.primary;
        break;
    }

    return PanelAtlassian(
      onTap: action.enabled ? onTap : null,
      padding: const EdgeInsets.all(14),
      radius: RadioAtlassian.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(RadioAtlassian.small),
            ),
            child: Icon(
              action.icon,
              color: action.enabled
                  ? iconColor
                  : scheme.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            action.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.8),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionListAtlassian extends StatelessWidget {
  const _ActionListAtlassian({required this.actions, required this.onTap});

  final List<_SearchAction> actions;
  final ValueChanged<_SearchAction> onTap;

  @override
  Widget build(BuildContext context) {
    return PanelAtlassian(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            _ActionRowAtlassian(
              action: actions[index],
              onTap: () => onTap(actions[index]),
            ),
            if (index != actions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ActionRowAtlassian extends StatelessWidget {
  const _ActionRowAtlassian({required this.action, required this.onTap});

  final _SearchAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                action.icon,
                size: 20,
                color: action.enabled
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(action.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerSearchCard extends StatelessWidget {
  const _CareerSearchCard({
    required this.career,
    required this.institutions,
    required this.onPlan,
    required this.onExams,
    required this.onCalendar,
    required this.onDesigns,
  });

  final CareerInfo career;
  final List<InstitutionInfo> institutions;
  final VoidCallback onPlan;
  final VoidCallback onExams;
  final VoidCallback onCalendar;
  final VoidCallback onDesigns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: career.iconAsset == null
                    ? Icon(
                        Icons.school_outlined,
                        color: theme.colorScheme.primary,
                      )
                    : Image.asset(
                        career.iconAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.school_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(career.nombre, style: theme.textTheme.titleMedium),
                    if (institutions.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        institutions.map((item) => item.nombre).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DestinationChip(
                icon: Icons.account_tree_outlined,
                label: 'Plan',
                onTap: onPlan,
              ),
              _DestinationChip(
                icon: Icons.event_note_outlined,
                label: 'Exámenes',
                onTap: onExams,
              ),
              _DestinationChip(
                icon: Icons.calendar_month_outlined,
                label: 'Calendario',
                onTap: onCalendar,
              ),
              _DestinationChip(
                icon: Icons.auto_stories_outlined,
                label: 'Diseños',
                onTap: onDesigns,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectedSubjectCard extends StatelessWidget {
  const _ConnectedSubjectCard({required this.result, required this.onOpen});

  final _ConnectedSubjectResult result;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <Widget>[
      if (result.trajectory.isNotEmpty)
        LozengeAtlassian(
          label: 'Trayectoria',
          appearance: AparienciaLozengeAtlassian.discovery,
        ),
      if (result.plans.isNotEmpty)
        const LozengeAtlassian(
          label: 'Plan',
          appearance: AparienciaLozengeAtlassian.brand,
        ),
      if (result.designs.isNotEmpty)
        const LozengeAtlassian(
          label: 'Diseño',
          appearance: AparienciaLozengeAtlassian.success,
        ),
      if (result.events.isNotEmpty)
        const LozengeAtlassian(
          label: 'Mesas',
          appearance: AparienciaLozengeAtlassian.warning,
        ),
    ];

    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.title, style: theme.textTheme.titleMedium),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final occurrence in result.trajectory.take(2))
                _DestinationChip(
                  icon: Icons.person_search_outlined,
                  label: occurrence.subject.estado.etiqueta,
                  onTap: () => onOpen(
                    DestinoBusquedaAtlassian(
                      tipo: TipoDestinoBusquedaAtlassian.detalleTrayectoria,
                      materiaTrayectoria: occurrence.subject,
                      carreraTrayectoria: occurrence.career,
                    ),
                  ),
                ),
              for (final occurrence in result.plans.take(4))
                _DestinationChip(
                  icon: Icons.account_tree_outlined,
                  label:
                      'Plan · ${shortCareerNameAtlassian(occurrence.career.id)}',
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
                _DestinationChip(
                  icon: Icons.auto_graph_outlined,
                  label: 'Probar en Escenarios',
                  onTap: () {
                    final occurrence = result.plans.first;
                    onOpen(
                      DestinoBusquedaAtlassian(
                        tipo: TipoDestinoBusquedaAtlassian.escenarios,
                        careerId: occurrence.career.id,
                        year: occurrence.subject.anio,
                        materiaPlan: occurrence.subject,
                      ),
                    );
                  },
                ),
              for (final content in result.designs.take(2))
                _DestinationChip(
                  icon: Icons.auto_stories_outlined,
                  label: 'Diseño curricular',
                  onTap: () {
                    final planOccurrence = result.plans
                        .where((item) => item.career.id == 'historia')
                        .firstOrNull;
                    final subject =
                        planOccurrence?.subject ??
                        materiaDesdeContenidoAtlassian(content);
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
                    );
                  },
                ),
              for (final event in result.events.take(3))
                _DestinationChip(
                  icon: Icons.event_available_outlined,
                  label: event.fechaVigente == null
                      ? 'Mesa'
                      : formatoFechaAtlassian(event.fechaVigente),
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

class _ExamSearchCard extends StatelessWidget {
  const _ExamSearchCard({required this.event, required this.onOpen});

  final _ExamResult event;
  final Future<void> Function(DestinoBusquedaAtlassian destination) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = event.event;
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event_note_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.materia, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      '${careerNameAtlassian(item.careerId)} · ${formatExamInstanceAtlassian(item.instancia)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatoFechaHoraAtlassian(
                        item.fechaVigente,
                        item.horaVigente,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DestinationChip(
                icon: Icons.open_in_new_rounded,
                label: 'Abrir mesa',
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.detalleExamen,
                    evento: item,
                  ),
                ),
              ),
              _DestinationChip(
                icon: Icons.calendar_month_outlined,
                label: 'Ver en calendario',
                onTap: () => onOpen(
                  DestinoBusquedaAtlassian(
                    tipo: TipoDestinoBusquedaAtlassian.calendario,
                    careerId: item.careerId,
                    fecha: item.fechaVigente,
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

class _ProfileSearchRow extends StatelessWidget {
  const _ProfileSearchRow({required this.result, required this.onTap});

  final _ProfileResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(result.value, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onPressed: onTap,
    );
  }
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

String normalizarBusquedaAtlassian(String value) {
  var normalized = sanitizeLowerNoAccents(value)
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  const replacements = <String, String>{
    'prof ': 'profesorado ',
    'profes ': 'profesorado ',
    'geo ': 'geografia ',
    'politicas': 'politica',
    'cs politicas': 'ciencia politica',
    'artes visual': 'artes visuales',
    'finales': 'examenes mesas',
    'final ': 'examen mesa ',
    'sync': 'sincronizar',
  };
  replacements.forEach((from, to) {
    normalized = normalized.replaceAll(from, to);
  });

  const stopWords = <String>{
    'a',
    'al',
    'de',
    'del',
    'el',
    'en',
    'ir',
    'la',
    'las',
    'lo',
    'los',
    'me',
    'mi',
    'para',
    'por',
    'que',
    'quiero',
    'un',
    'una',
    'ver',
  };
  const canonicalWords = <String, String>{
    'aprobadas': 'aprobada',
    'aprobados': 'aprobada',
    'aprobado': 'aprobada',
    'regulares': 'regular',
    'regularizada': 'regular',
    'regularizadas': 'regular',
    'pendientes': 'pendiente',
    'desaprobada': 'pendiente',
    'desaprobadas': 'pendiente',
    'desaprobado': 'pendiente',
    'desaprobados': 'pendiente',
    'reprobada': 'pendiente',
    'reprobadas': 'pendiente',
    'materias': 'materia',
    'planes': 'plan',
    'examenes': 'examen',
    'mesas': 'mesa',
    'fechas': 'fecha',
    'disenos': 'diseno',
    'ciencias': 'ciencia',
    'primero': '1',
    'primer': '1',
    '1ro': '1',
    '1er': '1',
    'segundo': '2',
    '2do': '2',
    'tercero': '3',
    'tercer': '3',
    '3ro': '3',
    '3er': '3',
    'cuarto': '4',
    '4to': '4',
  };
  final tokens = normalized
      .split(' ')
      .where((token) => token.isNotEmpty && !stopWords.contains(token))
      .map((token) => canonicalWords[token] ?? token)
      .toList(growable: false);
  return tokens.isEmpty ? normalized : tokens.join(' ');
}

String canonicalSubjectKeyAtlassian(String value) {
  return normalizarBusquedaAtlassian(value)
      .replaceFirst(
        RegExp(r'^procesos sociales politicos economicos culturales\s+'),
        '',
      )
      .replaceAll('practica profesional docente', 'practica docente')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int minimumScoreBusquedaAtlassian(String query) {
  if (query.length <= 2) return 24;
  if (query.length <= 4) return 28;
  return 32;
}

int scoreBusquedaAtlassian(String rawQuery, String rawTarget) {
  final query = normalizarBusquedaAtlassian(rawQuery);
  final target = normalizarBusquedaAtlassian(rawTarget);
  if (query.isEmpty || target.isEmpty) return 0;

  var score = 0;
  if (target == query) score += 220;
  if (target.startsWith(query)) score += 110;
  if (target.contains(query)) score += 84;

  final queryTokens = query
      .split(' ')
      .where((item) => item.isNotEmpty)
      .toList();
  final targetTokens = target
      .split(' ')
      .where((item) => item.isNotEmpty)
      .toList();
  var matched = 0;

  for (final queryToken in queryTokens) {
    var best = 0;
    for (final targetToken in targetTokens) {
      if (targetToken == queryToken) {
        best = math.max(best, 42);
      } else if (targetToken.startsWith(queryToken)) {
        best = math.max(best, queryToken.length <= 2 ? 24 : 34);
      } else if (queryToken.startsWith(targetToken) &&
          targetToken.length >= 3) {
        best = math.max(best, 22);
      } else if (queryToken.length >= 4 && targetToken.length >= 4) {
        final distance = levenshteinAtlassian(queryToken, targetToken);
        if (distance == 1) {
          best = math.max(best, 26);
        } else if (distance == 2 && queryToken.length >= 6) {
          best = math.max(best, 16);
        }
      }
    }
    if (best > 0) matched++;
    score += best;
  }

  if (queryTokens.length > 1 && matched == queryTokens.length) score += 54;
  if (queryTokens.length > 1 && matched < queryTokens.length) score -= 16;
  return score;
}

int levenshteinAtlassian(String first, String second) {
  if (first == second) return 0;
  if (first.isEmpty) return second.length;
  if (second.isEmpty) return first.length;

  var previous = List<int>.generate(second.length + 1, (index) => index);
  for (var firstIndex = 0; firstIndex < first.length; firstIndex++) {
    final current = List<int>.filled(second.length + 1, 0);
    current[0] = firstIndex + 1;
    for (var secondIndex = 0; secondIndex < second.length; secondIndex++) {
      final insertion = current[secondIndex] + 1;
      final deletion = previous[secondIndex + 1] + 1;
      final substitution =
          previous[secondIndex] +
          (first.codeUnitAt(firstIndex) == second.codeUnitAt(secondIndex)
              ? 0
              : 1);
      current[secondIndex + 1] = math.min(
        insertion,
        math.min(deletion, substitution),
      );
    }
    previous = current;
  }
  return previous.last;
}

String monthNameAtlassian(int month) {
  const months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  if (month < 1 || month > 12) return 'mes';
  return months[month - 1];
}

String searchableDateAtlassian(DateTime? date, String? hour) {
  if (date == null) return hour ?? 'sin fecha';
  const months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year} '
      '${date.day}/${date.month}/${date.year} ${hour ?? ''}';
}

String careerNameAtlassian(String careerId) {
  for (final career in kCareers) {
    if (career.id == careerId) return career.nombre;
  }
  return careerId;
}

String shortCareerNameAtlassian(String careerId) {
  return switch (careerId) {
    'historia' => 'Historia',
    'geografia' => 'Geografía',
    'politica' => 'C. Política',
    'artes_visuales' => 'Artes',
    'musica' => 'Música',
    _ => careerNameAtlassian(careerId),
  };
}

String formatExamInstanceAtlassian(String value) {
  final normalized = normalizarBusquedaAtlassian(value);
  if (normalized.contains('coloquio')) return 'Coloquio';
  if (normalized.contains('2')) return 'Segundo llamado';
  return 'Primer llamado';
}

String readableProfileLabelAtlassian(String key) {
  final normalized = normalizarBusquedaAtlassian(key);
  if (normalized.contains('tipo') && normalized.contains('document')) {
    return 'Tipo de documento';
  }
  if (normalized == 'dni' || normalized.contains('documento')) return 'DNI';
  if (normalized.contains('apenom') || normalized.contains('nombre')) {
    return 'Nombre completo';
  }
  if (normalized.contains('telefono') || normalized.contains('celular')) {
    return 'Teléfono';
  }
  if (normalized.contains('nacimiento')) return 'Fecha de nacimiento';
  if (normalized.contains('localidad')) return 'Localidad';
  final cleanKey = key
      .replaceAll(RegExp(r'^[^.]+\.'), '')
      .replaceAll('_', ' ')
      .trim();
  if (cleanKey.isEmpty) return key;
  return cleanKey
      .split(' ')
      .where((item) => item.trim().isNotEmpty)
      .map(
        (item) => item.isEmpty
            ? item
            : '${item[0].toUpperCase()}${item.length > 1 ? item.substring(1) : ''}',
      )
      .join(' ');
}

Materia materiaDesdeContenidoAtlassian(ContenidoCurricular content) {
  return Materia(
    id: content.id,
    codigo: content.id.toUpperCase(),
    nombre: content.nombre,
    anio: content.anio,
    tipo: content.tipo,
    formato: content.formato,
    correlativas: const <String>[],
    correlativasDetalladas: const <CorrelativaDetallada>[],
    horas: content.cargaHoraria,
  );
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
