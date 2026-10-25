import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/proveedores/estado_app.dart';
import '../../../modelos/materia.dart';
import '../../calculadora/evaluation_panel.dart';
import '../../calculadora/pantalla/componentes/contenido_animado_calculadora.dart';
import '../../calculadora/pantalla/tema/estilos_calculadora.dart';
import '../../preguntas_frecuentes/preguntas_frecuentes_pantalla.dart';
import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../componentes/componentes_atlassian.dart';
import '../componentes/trayectoria_activa_atlassian.dart';
import '../tema/tema_atlassian.dart';
import 'utilidades_atlassian.dart';

class PantallaEscenariosInicializadosAtlassian extends ConsumerStatefulWidget {
  const PantallaEscenariosInicializadosAtlassian({
    super.key,
    this.careerId,
    this.year,
    this.subjectId,
  });

  final String? careerId;
  final int? year;
  final String? subjectId;

  @override
  ConsumerState<PantallaEscenariosInicializadosAtlassian> createState() =>
      _PantallaEscenariosInicializadosAtlassianState();
}

class _PantallaEscenariosInicializadosAtlassianState
    extends ConsumerState<PantallaEscenariosInicializadosAtlassian> {
  bool _baseApplied = false;
  bool _subjectApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyBase());
  }

  void _applyBase() {
    if (!mounted || _baseApplied) return;
    _baseApplied = true;
    final careerId = widget.careerId?.trim();
    if (careerId != null && careerId.isNotEmpty) {
      ref.read(proveedorIdCarreraSeleccionada.notifier).state = careerId;
    }
    if (widget.year != null) {
      ref.read(proveedorAnioEvaluacion.notifier).state = widget.year!;
    }
    ref.read(proveedorIdMateriaCalculadoraSeleccionada.notifier).state = null;
    ref.read(proveedorMapaEstadosCorrelativas.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(proveedorPlan);
    final requestedSubjectId = widget.subjectId?.trim();
    if (!_subjectApplied &&
        requestedSubjectId != null &&
        requestedSubjectId.isNotEmpty) {
      planAsync.whenData((plan) {
        final exists = plan.materias.any(
          (subject) => subject.id == requestedSubjectId,
        );
        if (!exists || _subjectApplied) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _subjectApplied) return;
          _subjectApplied = true;
          ref.read(proveedorIdMateriaCalculadoraSeleccionada.notifier).state =
              requestedSubjectId;
          ref.read(proveedorMapaEstadosCorrelativas.notifier).clear();
        });
      });
    }
    return const PantallaEscenariosAtlassian();
  }
}

class PantallaEscenariosAtlassian extends ConsumerWidget {
  const PantallaEscenariosAtlassian({super.key});

  Future<void> _chooseCareer(
    BuildContext context,
    WidgetRef ref,
    List<CareerInfo> careers,
    CareerInfo? selectedCareer,
  ) async {
    final selectedId = await _mostrarHojaEscenarios<String>(
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
                  'Carrera de referencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final career in careers) ...[
                  PanelAtlassian(
                    selected: selectedCareer?.id == career.id,
                    onTap: () => Navigator.of(sheetContext).pop(career.id),
                    child: Row(
                      children: [
                        Icon(
                          selectedCareer?.id == career.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selectedCareer?.id == career.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (selectedId == null ||
        selectedId == selectedCareer?.id ||
        !context.mounted) {
      return;
    }
    ref.read(proveedorIdCarreraSeleccionada.notifier).state = selectedId;
    ref.read(proveedorAnioEvaluacion.notifier).state = 2;
    ref.read(proveedorIdMateriaCalculadoraSeleccionada.notifier).state = null;
    ref.read(proveedorMapaEstadosCorrelativas.notifier).clear();
  }

  Future<void> _chooseYear(
    BuildContext context,
    WidgetRef ref,
    int selectedYear,
  ) async {
    final selected = await _mostrarHojaEscenarios<int>(
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
                  'Tramo del plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final year in const [1, 2, 3, 4]) ...[
                  PanelAtlassian(
                    selected: selectedYear == year,
                    onTap: () => Navigator.of(sheetContext).pop(year),
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
    if (selected == null || selected == selectedYear || !context.mounted) {
      return;
    }
    ref.read(proveedorAnioEvaluacion.notifier).state = selected;
    ref.read(proveedorIdMateriaCalculadoraSeleccionada.notifier).state = null;
    ref.read(proveedorMapaEstadosCorrelativas.notifier).clear();
  }

  Future<void> _chooseSubject(
    BuildContext context,
    WidgetRef ref,
    List<Materia> subjects,
    String? selectedId,
  ) async {
    final selected = await _mostrarHojaEscenarios<String>(
      context: context,
      builder: (_) => _SelectorMateriaEscenarios(
        subjects: subjects,
        selectedId: selectedId,
      ),
    );
    if (selected == null || selected == selectedId || !context.mounted) return;
    ref.read(proveedorIdMateriaCalculadoraSeleccionada.notifier).state =
        selected;
    ref.read(proveedorMapaEstadosCorrelativas.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TemaCalculadora(builder: (context) => _contenido(context, ref));

  Widget _contenido(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(proveedorPlan);
    final careers = ref.watch(proveedorCarreras);
    final selectedCareer = ref.watch(proveedorCarreraSeleccionadaONula);
    final selectedYear = ref.watch(proveedorAnioEvaluacion);
    final selectedId = ref.watch(proveedorIdMateriaCalculadoraSeleccionada);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            EncabezadoPaginaAtlassian(
              title: 'Escenarios',
              subtitle: 'Condiciones y posibilidades de cursada',
              leading: BotonIconoAtlassian(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onPressed: () => volverPantallaAtlassian(context),
              ),
            ),
            Expanded(
              child: planAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => EstadoVacioAtlassian(
                  icon: Icons.error_outline_rounded,
                  title: 'No se pudo cargar el plan',
                  message: error.toString(),
                ),
                data: (plan) {
                  final subjects =
                      plan.materias
                          .where((subject) => subject.anio == selectedYear)
                          .toList()
                        ..sort(
                          (first, second) => first.displayNombre.compareTo(
                            second.displayNombre,
                          ),
                        );
                  Materia? selectedSubject;
                  for (final subject in plan.materias) {
                    if (subject.id == selectedId) {
                      selectedSubject = subject;
                      break;
                    }
                  }
                  if (selectedId != null && selectedSubject == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                              .read(
                                proveedorIdMateriaCalculadoraSeleccionada
                                    .notifier,
                              )
                              .state =
                          null;
                      ref
                          .read(proveedorMapaEstadosCorrelativas.notifier)
                          .clear();
                    });
                  }

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      const EntradaContenidoApp(
                        child: _IntroduccionEscenarios(),
                      ),
                      const SizedBox(height: 12),
                      PanelAtlassian(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Datos de referencia',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ToqueMovimientoApp(
                              child: SelectorAtlassian(
                                label: 'Carrera',
                                value: selectedCareer?.nombre ?? 'Seleccionar',
                                icon: Icons.school_outlined,
                                onTap: () => _chooseCareer(
                                  context,
                                  ref,
                                  careers,
                                  selectedCareer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ToqueMovimientoApp(
                              child: SelectorAtlassian(
                                label: 'Tramo del plan',
                                value: '$selectedYear° año',
                                icon: Icons.calendar_view_month_outlined,
                                enabled: selectedCareer != null,
                                onTap: selectedCareer == null
                                    ? null
                                    : () => _chooseYear(
                                        context,
                                        ref,
                                        selectedYear,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ToqueMovimientoApp(
                              child: SelectorAtlassian(
                                label: 'Materia',
                                value:
                                    selectedSubject?.displayNombre ??
                                    'Seleccionar materia',
                                icon: Icons.menu_book_outlined,
                                enabled:
                                    selectedCareer != null &&
                                    subjects.isNotEmpty,
                                onTap:
                                    selectedCareer == null || subjects.isEmpty
                                    ? null
                                    : () => _chooseSubject(
                                        context,
                                        ref,
                                        subjects,
                                        selectedId,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ContenidoAnimadoCalculadora(
                        identidad: selectedSubject?.id ?? 'espera',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (selectedSubject == null)
                              EstadoVacioAtlassian(
                                icon: Icons.account_tree_outlined,
                                title: selectedCareer == null
                                    ? 'Seleccioná una carrera'
                                    : 'Seleccioná una materia',
                                message: selectedCareer == null
                                    ? 'La carrera define el plan que se utilizará.'
                                    : 'El resultado aparecerá después de elegir una materia.',
                              )
                            else ...[
                              PanelAtlassian(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LozengeAtlassian(
                                      label: '$selectedYear° año',
                                      appearance:
                                          AparienciaLozengeAtlassian.brand,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      selectedSubject.displayNombre,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (selectedSubject.codigo
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedSubject.codigo,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const PanelEvaluacion(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorMateriaEscenarios extends StatefulWidget {
  const _SelectorMateriaEscenarios({required this.subjects, this.selectedId});

  final List<Materia> subjects;
  final String? selectedId;

  @override
  State<_SelectorMateriaEscenarios> createState() =>
      _SelectorMateriaEscenariosState();
}

class _SelectorMateriaEscenariosState
    extends State<_SelectorMateriaEscenarios> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    // La hoja conserva el controlador hasta terminar su animación de salida.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final normalized = _query.trim().toLowerCase();
      final visible = widget.subjects
          .where((subject) {
            if (normalized.isEmpty) return true;
            return '${subject.codigo} ${subject.displayNombre}'
                .toLowerCase()
                .contains(normalized);
          })
          .toList(growable: false);
      final height = (constraints.maxHeight * .85).clamp(0.0, 680.0);
      return SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Materia a evaluar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                CampoBusquedaAtlassian(
                  controller: _controller,
                  hintText: 'Buscar materia o código',
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                  onClear: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: visible.isEmpty
                      ? const EstadoVacioAtlassian(
                          icon: Icons.search_off_rounded,
                          title: 'Sin resultados',
                          message: 'Probá con otro término.',
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final subject = visible[index];
                            return PanelAtlassian(
                              selected: widget.selectedId == subject.id,
                              onTap: () =>
                                  Navigator.of(context).pop(subject.id),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.displayNombre,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          subject.codigo,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.selectedId == subject.id)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
    },
  );
}

Future<T?> _mostrarHojaEscenarios<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: EstilosCalculadora.fondoTarjeta(context),
  sheetAnimationStyle: AnimationStyle(
    duration: MovimientoApp.duracion(context, MovimientoApp.ruta),
    reverseDuration: MovimientoApp.duracion(context, MovimientoApp.salida),
  ),
  builder: (context) => TemaCalculadora(
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  ),
);

class _IntroduccionEscenarios extends StatelessWidget {
  const _IntroduccionEscenarios();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_graph_rounded, color: scheme.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculadora de correlatividades',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Elegí la carrera, el tramo y la materia para construir el escenario académico actual.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class PantallaAyudaAtlassian extends StatelessWidget {
  const PantallaAyudaAtlassian({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          EncabezadoPaginaAtlassian(
            title: 'Ayuda',
            subtitle: 'Normativa, cursada y trayectorias',
            leading: BotonIconoAtlassian(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: () => volverPantallaAtlassian(context),
            ),
          ),
          const Expanded(
            child: PantallaPreguntasFrecuentes(
              showHeader: false,
              atlassianStyle: true,
            ),
          ),
        ],
      ),
    );
  }
}

class PantallaProximosPasosAtlassian extends StatelessWidget {
  const PantallaProximosPasosAtlassian({super.key, required this.career});

  final CarreraTrayectoriaSageLaboratorio? career;

  @override
  Widget build(BuildContext context) {
    final activa = TrayectoriaActivaAtlassian.de(context);
    final current = activa == null ? career : activa.carreraActual;
    final regular =
        current?.materias
            .where(
              (item) => item.estado == EstadoMateriaSageLaboratorio.regular,
            )
            .toList() ??
        const <MateriaTrayectoriaSageLaboratorio>[];
    final studying =
        current?.materias
            .where(
              (item) => item.estado == EstadoMateriaSageLaboratorio.cursando,
            )
            .toList() ??
        const <MateriaTrayectoriaSageLaboratorio>[];
    final pending =
        current?.materias
            .where(
              (item) =>
                  item.estado == EstadoMateriaSageLaboratorio.noRegularizada ||
                  item.estado == EstadoMateriaSageLaboratorio.desconocida,
            )
            .toList() ??
        const <MateriaTrayectoriaSageLaboratorio>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          EncabezadoPaginaAtlassian(
            title: 'Próximos pasos',
            subtitle: current == null
                ? 'Trayectoria sin sincronizar'
                : nombreCarreraAtlassian(current.nombre),
            leading: BotonIconoAtlassian(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: () => volverPantallaAtlassian(context),
            ),
          ),
          Expanded(
            child: current == null
                ? const EstadoVacioAtlassian(
                    icon: Icons.flag_outlined,
                    title: 'Sin trayectoria',
                    message: 'Sincronizá SAGE para generar prioridades.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BloquePasosAtlassian(
                        title: 'Finales pendientes',
                        subtitle: '${regular.length} materias regularizadas',
                        icon: Icons.assignment_turned_in_outlined,
                        subjects: regular,
                        appearance: AparienciaLozengeAtlassian.brand,
                      ),
                      const SizedBox(height: 12),
                      _BloquePasosAtlassian(
                        title: 'Cursada activa',
                        subtitle: '${studying.length} materias en curso',
                        icon: Icons.pending_actions_rounded,
                        subjects: studying,
                        appearance: AparienciaLozengeAtlassian.discovery,
                      ),
                      const SizedBox(height: 12),
                      _BloquePasosAtlassian(
                        title: 'Materias a revisar',
                        subtitle:
                            '${pending.length} pendientes o sin clasificar',
                        icon: Icons.fact_check_outlined,
                        subjects: pending,
                        appearance: AparienciaLozengeAtlassian.warning,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class PantallaAvanceAtlassian extends StatelessWidget {
  const PantallaAvanceAtlassian({super.key, required this.career});

  final CarreraTrayectoriaSageLaboratorio? career;

  @override
  Widget build(BuildContext context) {
    final activa = TrayectoriaActivaAtlassian.de(context);
    final current = activa == null ? career : activa.carreraActual;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          EncabezadoPaginaAtlassian(
            title: 'Mi avance',
            subtitle: current == null
                ? 'Trayectoria sin sincronizar'
                : nombreCarreraAtlassian(current.nombre),
            leading: BotonIconoAtlassian(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: () => volverPantallaAtlassian(context),
            ),
          ),
          Expanded(
            child: current == null
                ? const EstadoVacioAtlassian(
                    icon: Icons.insights_outlined,
                    title: 'Sin datos de avance',
                    message: 'Sincronizá SAGE desde Inicio.',
                  )
                : _ContenidoAvanceAtlassian(career: current),
          ),
        ],
      ),
    );
  }
}

class _ContenidoAvanceAtlassian extends StatelessWidget {
  const _ContenidoAvanceAtlassian({required this.career});

  final CarreraTrayectoriaSageLaboratorio career;

  @override
  Widget build(BuildContext context) {
    final total = career.materias.length;
    final progress = total == 0 ? 0.0 : career.aprobadas / total;
    final byYear = <int?, List<MateriaTrayectoriaSageLaboratorio>>{};
    for (final item in career.materias) {
      byYear.putIfAbsent(item.anio, () => []).add(item);
    }
    final years = byYear.keys.toList()
      ..sort((a, b) => (a ?? 99).compareTo(b ?? 99));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PanelAtlassian(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Progreso general',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(RadioAtlassian.pill),
                child: LinearProgressIndicator(value: progress, minHeight: 8),
              ),
              const SizedBox(height: 8),
              Text(
                '${career.aprobadas} de $total materias aprobadas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final year in years) ...[
          SeparadorTituloAtlassian(
            title: year == null ? 'Sin año' : '$year° año',
            subtitle: '${byYear[year]!.length} materias',
          ),
          const SizedBox(height: 8),
          PanelAtlassian(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final state in EstadoMateriaSageLaboratorio.values)
                  if (byYear[year]!
                      .where((item) => item.estado == state)
                      .isNotEmpty)
                    LozengeAtlassian(
                      label:
                          '${state.etiqueta}: ${byYear[year]!.where((item) => item.estado == state).length}',
                      appearance: aparienciaEstadoAtlassian(state),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _BloquePasosAtlassian extends StatelessWidget {
  const _BloquePasosAtlassian({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.subjects,
    required this.appearance,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<MateriaTrayectoriaSageLaboratorio> subjects;
  final AparienciaLozengeAtlassian appearance;

  @override
  Widget build(BuildContext context) {
    return PanelAtlassian(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in subjects.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    LozengeAtlassian(
                      label: item.estado.etiqueta,
                      appearance: appearance,
                    ),
                  ],
                ),
              ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Sin materias en esta categoría.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
