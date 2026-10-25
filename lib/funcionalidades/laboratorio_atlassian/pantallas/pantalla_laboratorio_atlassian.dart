import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/navegacion/barra_busqueda_app.dart';
import '../../administrador/pantallas/acceso_administrador_pantalla.dart';
import '../../trayectoria_sage_laboratorio/datos/repositorio_estado_sincronizacion_sage.dart';
import '../../trayectoria_sage_laboratorio/datos/repositorio_trayectoria_sage_laboratorio.dart';
import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../busqueda/modelos_busqueda_atlassian.dart';
import '../busqueda/pantalla_busqueda_global_react_developer.dart';
import '../componentes/componentes_atlassian.dart';
import '../componentes/trayectoria_activa_atlassian.dart';
import '../tema/tema_atlassian.dart';
import 'pantalla_calendario_atlassian.dart';
import 'pantalla_datos_atlassian.dart';
import 'pantalla_disenos_atlassian.dart';
import 'pantalla_examenes_atlassian.dart';
import 'pantalla_inicio_react_developer.dart';
import 'pantalla_materias_atlassian.dart';
import 'pantalla_plan_atlassian.dart';
import 'pantallas_herramientas_atlassian.dart';
import 'utilidades_atlassian.dart';

class PantallaLaboratorioAtlassian extends StatefulWidget {
  const PantallaLaboratorioAtlassian({super.key, this.hideExit = false});

  final bool hideExit;

  @override
  State<PantallaLaboratorioAtlassian> createState() =>
      _PantallaLaboratorioAtlassianState();
}

class _PantallaLaboratorioAtlassianState
    extends State<PantallaLaboratorioAtlassian> {
  static const _repository = RepositorioTrayectoriaSageLaboratorio();
  static const _syncStateRepository = RepositorioEstadoSincronizacionSage();

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
        5,
        (_) => GlobalKey<NavigatorState>(),
      );
  final ValueNotifier<TrayectoriaSageLaboratorio?> _trajectory =
      ValueNotifier<TrayectoriaSageLaboratorio?>(null);
  final ValueNotifier<bool> _localLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<int> _selectedCareer = ValueNotifier<int>(0);
  final ValueNotifier<int> _resetRevision = ValueNotifier<int>(0);
  final ValueNotifier<SolicitudExamenesAtlassian?> _examRequest =
      ValueNotifier<SolicitudExamenesAtlassian?>(null);
  final ValueNotifier<SolicitudPlanAtlassian?> _planRequest =
      ValueNotifier<SolicitudPlanAtlassian?>(null);
  final ValueNotifier<SolicitudMateriasAtlassian?> _subjectRequest =
      ValueNotifier<SolicitudMateriasAtlassian?>(null);
  final ValueNotifier<SolicitudInicioAtlassian?> _homeRequest =
      ValueNotifier<SolicitudInicioAtlassian?>(null);
  final Set<int> _builtSections = <int>{0};
  late final Listenable _trajectoryChanges = Listenable.merge([
    _trajectory,
    _selectedCareer,
  ]);
  bool _resolvingSearch = false;
  bool _searchOpen = false;
  int _searchRevision = 0;
  ({int origen, int destino})? _searchReturn;
  PageRoute<void>? _searchReturnRoute;

  int _section = 0;
  bool _sidebarHidden = false;
  final ValueNotifier<double> _topBlurProgress = ValueNotifier(0);

  void _handleSectionRouteChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocal());
  }

  Future<void> _loadLocal() async {
    final loaded = await _repository.cargar();
    if (!mounted) return;
    _trajectory.value = loaded;
    _selectedCareer.value = _safeCareerIndex(loaded, _selectedCareer.value);
    _localLoaded.value = true;
  }

  int _safeCareerIndex(TrayectoriaSageLaboratorio? trajectory, int requested) {
    final count = trajectory?.carreras.length ?? 0;
    if (count == 0) return 0;
    return requested.clamp(0, count - 1).toInt();
  }

  void _replaceTrajectory(TrayectoriaSageLaboratorio? trajectory) {
    _trajectory.value = trajectory;
    _selectedCareer.value = _safeCareerIndex(trajectory, _selectedCareer.value);
  }

  Future<void> _desynchronize() async {
    final atlassianTheme = temaLaboratorioAtlassian(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: atlassianTheme,
        child: AlertDialog(
          backgroundColor: atlassianTheme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadioAtlassian.large),
            side: BorderSide(color: atlassianTheme.colorScheme.outlineVariant),
          ),
          title: Text(
            'Desincronizar trayectoria',
            style: atlassianTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Se borrarán los datos locales.',
            style: atlassianTheme.textTheme.bodyMedium?.copyWith(
              color: atlassianTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PaletaAtlassian.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Desincronizar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await Future.wait<void>([
      _repository.borrar(),
      _syncStateRepository.borrarPreferencias(),
    ]);
    if (!mounted) return;
    _replaceTrajectory(null);
    _resetRevision.value++;
    setState(() => _section = 0);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trayectoria desincronizada')));
  }

  void _activateSection(int section) {
    if (_section == section && _builtSections.contains(section)) return;
    setState(() {
      _builtSections.add(section);
      _section = section;
      _topBlurProgress.value = 0;
    });
  }

  void _selectSection(int section) {
    _searchReturn = null;
    _searchReturnRoute = null;
    if (_section == section) {
      _navigatorKeys[section].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    final firstVisit = !_builtSections.contains(section);
    _activateSection(section);
    final career = _currentTrajectoryCareer();
    if (firstVisit && career != null) {
      final careerId = idCarreraExamenAtlassian(career.nombre);
      if (section == 1) {
        _examRequest.value = SolicitudExamenesAtlassian(careerId: careerId);
      } else if (section == 2) {
        _planRequest.value = SolicitudPlanAtlassian(careerId: careerId);
      }
    }
  }

  Future<void> _openSearch({
    int? restoreSection,
    PageRoute<void>? discardRoute,
  }) async {
    if (_searchOpen || !mounted) return;
    _searchOpen = true;
    _searchReturn = null;
    _searchReturnRoute = null;
    late final PageRoute<void> route;
    route = RutaBusquedaApp<void>(
      builder: (_) => PantallaBusquedaGlobalReactDeveloper(
        trajectoryListenable: _trajectory,
        selectedCareerListenable: _selectedCareer,
        onOpenDestination: (destination) =>
            _handleSearchDestination(destination, route),
      ),
    );
    void restoreOrigin(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.animation?.removeStatusListener(restoreOrigin);
      // Restaurar el origen cuando el menú ya cubre la sección evita un
      // destello de Inicio durante el vuelo de la barra hacia el buscador.
      if (mounted && route.isCurrent && restoreSection != null) {
        if (discardRoute?.isActive ?? false) {
          discardRoute!.navigator?.removeRoute(discardRoute);
        }
        _activateSection(restoreSection);
      }
    }

    try {
      final navigation = Navigator.of(
        context,
        rootNavigator: true,
      ).push<void>(route);
      if (restoreSection != null) {
        route.animation?.addStatusListener(restoreOrigin);
        restoreOrigin(route.animation!.status);
      }
      await navigation;
      await route.completed;
    } finally {
      route.animation?.removeStatusListener(restoreOrigin);
      _searchOpen = false;
      // Una salida hacia otro destino no devuelve el Hero al origen. Al
      // finalizar el vuelo, renovar su estado libera la barra de Inicio.
      if (mounted) setState(() => _searchRevision++);
    }
  }

  Future<void> _pushInSection(int section, Widget page) async {
    final originSection = _section;
    _activateSection(section);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final route = rutaAtlassian<void>(
      builder: (_) => RegresoBusquedaApp(
        onVolver: () => unawaited(_handleBack()),
        child: PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_handleBack());
          },
          child: page,
        ),
      ),
      animarEntrada: false,
    );
    _searchReturn = (origen: originSection, destino: section);
    _searchReturnRoute = route;
    // El buscador cubre el destino mientras se monta: no hay una segunda
    // entrada que deje ver la página anterior después de retirar la búsqueda.
    unawaited(_navigatorKeys[section].currentState?.push<void>(route));
    await WidgetsBinding.instance.endOfFrame;
  }

  int? _trajectoryCareerIndex(String? careerId) {
    if (careerId == null || _trajectory.value == null) return null;
    final careers = _trajectory.value!.carreras;
    for (var index = 0; index < careers.length; index++) {
      if (idCarreraExamenAtlassian(careers[index].nombre) == careerId) {
        return index;
      }
    }
    return null;
  }

  Future<void> _handleSearchDestination(
    DestinoBusquedaAtlassian destination,
    PageRoute<void> searchRoute,
  ) async {
    if (_resolvingSearch || !searchRoute.isCurrent) return;
    _resolvingSearch = true;
    final originSection = _section;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final prepararPantalla = switch (destination.tipo) {
      TipoDestinoBusquedaAtlassian.sage ||
      TipoDestinoBusquedaAtlassian.sincronizar ||
      TipoDestinoBusquedaAtlassian.documentoAcademico ||
      TipoDestinoBusquedaAtlassian.desincronizar ||
      TipoDestinoBusquedaAtlassian.cerrarSesionSage ||
      TipoDestinoBusquedaAtlassian.salir => false,
      _ => true,
    };
    try {
      if (prepararPantalla) {
        await _applySearchDestination(destination);
        if (destination.tipo == TipoDestinoBusquedaAtlassian.seccion &&
            _section != 0) {
          _searchReturn = (origen: originSection, destino: _section);
        }
        // La sección y sus filtros deben haber pintado antes de comenzar
        // la salida del buscador, que ahora revela directamente el destino.
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted || !searchRoute.isCurrent) return;
      rootNavigator.pop();
      await searchRoute.completed;
      if (!mounted) return;
      if (!prepararPantalla) await _applySearchDestination(destination);
    } finally {
      _resolvingSearch = false;
    }
  }

  Future<void> _applySearchDestination(
    DestinoBusquedaAtlassian destination,
  ) async {
    switch (destination.tipo) {
      case TipoDestinoBusquedaAtlassian.seccion:
        final section = destination.seccion ?? 0;
        _activateSection(section);
        if (section == 1) {
          _examRequest.value = SolicitudExamenesAtlassian(
            careerId: destination.careerId,
            query: destination.query,
            year: destination.year,
            scope: destination.scope,
          );
        } else if (section == 2) {
          _planRequest.value = SolicitudPlanAtlassian(
            careerId: destination.careerId,
            query: destination.query,
            year: destination.year,
          );
        } else if (section == 3) {
          final careerIndex = _trajectoryCareerIndex(destination.careerId);
          if (careerIndex != null) _selectedCareer.value = careerIndex;
          _subjectRequest.value = SolicitudMateriasAtlassian(
            careerIndex: careerIndex,
            query: destination.query,
            year: destination.year,
            status: destination.status,
            focusSearch: (destination.query ?? '').trim().isNotEmpty,
          );
        }
        return;
      case TipoDestinoBusquedaAtlassian.calendario:
        await _pushInSection(
          0,
          PantallaCalendarioAtlassian(
            careerId: destination.careerId ?? 'historia',
            initialDate: destination.fecha,
            trayectoria: _trajectory.value,
          ),
        );
        return;
      case TipoDestinoBusquedaAtlassian.disenos:
        await _pushInSection(
          0,
          PantallaDisenosAtlassian(
            initialCareerId: destination.careerId,
            initialQuery: destination.query,
          ),
        );
        return;
      case TipoDestinoBusquedaAtlassian.escenarios:
        await _pushInSection(
          0,
          PantallaEscenariosInicializadosAtlassian(
            careerId: destination.careerId,
            year: destination.year,
            subjectId: destination.materiaPlan?.id,
          ),
        );
        return;
      case TipoDestinoBusquedaAtlassian.ayuda:
        await _pushInSection(0, const PantallaAyudaAtlassian());
        return;
      case TipoDestinoBusquedaAtlassian.proximosPasos:
        final career = _currentTrajectoryCareer();
        await _pushInSection(0, PantallaProximosPasosAtlassian(career: career));
        return;
      case TipoDestinoBusquedaAtlassian.avance:
        final career = _currentTrajectoryCareer();
        await _pushInSection(0, PantallaAvanceAtlassian(career: career));
        return;
      case TipoDestinoBusquedaAtlassian.sage:
        _activateSection(0);
        _homeRequest.value = SolicitudInicioAtlassian(
          AccionInicioAtlassian.abrirSage,
        );
        return;
      case TipoDestinoBusquedaAtlassian.sincronizar:
        _activateSection(0);
        _homeRequest.value = SolicitudInicioAtlassian(
          AccionInicioAtlassian.sincronizar,
        );
        return;
      case TipoDestinoBusquedaAtlassian.documentoAcademico:
        final tipoDocumento = destination.tipoDocumento;
        if (tipoDocumento == null) return;
        _activateSection(0);
        _homeRequest.value = SolicitudInicioAtlassian(
          AccionInicioAtlassian.descargarDocumento,
          tipoDocumento: tipoDocumento,
        );
        return;
      case TipoDestinoBusquedaAtlassian.desincronizar:
        await _desynchronize();
        return;
      case TipoDestinoBusquedaAtlassian.cerrarSesionSage:
        _activateSection(0);
        _homeRequest.value = SolicitudInicioAtlassian(
          AccionInicioAtlassian.cerrarSesionSage,
        );
        return;
      case TipoDestinoBusquedaAtlassian.salir:
        if (mounted) Navigator.of(context).pop();
        return;
      case TipoDestinoBusquedaAtlassian.detalleExamen:
        final event = destination.evento;
        if (event != null) {
          await _pushInSection(1, PantallaDetalleExamenAtlassian(event: event));
        }
        return;
      case TipoDestinoBusquedaAtlassian.detallePlan:
        final subject = destination.materiaPlan;
        final allSubjects = destination.materiasPlan;
        if (subject != null && allSubjects != null) {
          await _pushInSection(
            2,
            PantallaDetallePlanAtlassian(
              subject: subject,
              allSubjects: allSubjects,
              careerName: destination.career?.nombre ?? 'Plan completo',
            ),
          );
        }
        return;
      case TipoDestinoBusquedaAtlassian.detalleDiseno:
        final subject = destination.materiaPlan;
        final content = destination.contenidoCurricular;
        if (subject != null) {
          await _pushInSection(
            0,
            PantallaDetalleDisenoAtlassian(
              subject: subject,
              content: content,
              careerName: destination.career?.nombre ?? 'Diseño curricular',
            ),
          );
        }
        return;
      case TipoDestinoBusquedaAtlassian.detalleTrayectoria:
        final subject = destination.materiaTrayectoria;
        final career = destination.carreraTrayectoria;
        if (subject != null && career != null) {
          final careers =
              _trajectory.value?.carreras ??
              const <CarreraTrayectoriaSageLaboratorio>[];
          final index = careers.indexWhere(
            (item) => item.gridRowId == career.gridRowId,
          );
          if (index >= 0) _selectedCareer.value = index;
          await _pushInSection(
            3,
            PantallaDetalleMateriaAtlassian(subject: subject, career: career),
          );
        }
        return;
    }
  }

  CarreraTrayectoriaSageLaboratorio? _currentTrajectoryCareer() {
    final trajectory = _trajectory.value;
    if (trajectory == null || trajectory.carreras.isEmpty) return null;
    final index = _selectedCareer.value
        .clamp(0, trajectory.carreras.length - 1)
        .toInt();
    return trajectory.carreras[index];
  }

  Future<bool> _handleBack() async {
    final navigator = _navigatorKeys[_section].currentState;
    if (navigator?.canPop() ?? false) {
      final returnRoute = _searchReturnRoute;
      final searchReturn = _searchReturn;
      if (returnRoute?.isCurrent == true && searchReturn != null) {
        unawaited(
          _openSearch(
            restoreSection: searchReturn.origen,
            discardRoute: returnRoute,
          ),
        );
        return false;
      }
      navigator!.pop();
      return false;
    }
    final searchReturn = _searchReturn;
    if (searchReturn != null && searchReturn.destino == _section) {
      _searchReturn = null;
      unawaited(_openSearch(restoreSection: searchReturn.origen));
      return false;
    }
    if (_section != 0) {
      setState(() => _section = 0);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _trajectory.dispose();
    _localLoaded.dispose();
    _selectedCareer.dispose();
    _resetRevision.dispose();
    _examRequest.dispose();
    _planRequest.dispose();
    _subjectRequest.dispose();
    _homeRequest.dispose();
    _topBlurProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = temaLaboratorioAtlassian(context);
    final dark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final desktop = size.width >= 720 || size.width > size.height;

    final sectionChildren = <Widget>[
      PantallaInicioReactDeveloper(
        trajectoryListenable: _trajectory,
        localLoadedListenable: _localLoaded,
        selectedCareerListenable: _selectedCareer,
        resetListenable: _resetRevision,
        actionRequestListenable: _homeRequest,
        onTrajectoryChanged: _replaceTrajectory,
        onNavigate: _selectSection,
        onSearch: _openSearch,
        onExit: widget.hideExit
            ? null
            : () {
                if (Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context).pop();
                }
              },
      ),
      PantallaExamenesAtlassian(
        onSearch: _openSearch,
        requestListenable: _examRequest,
      ),
      PantallaPlanAtlassian(
        onSearch: _openSearch,
        requestListenable: _planRequest,
      ),
      PantallaMateriasAtlassian(
        trajectoryListenable: _trajectory,
        localLoadedListenable: _localLoaded,
        selectedCareerListenable: _selectedCareer,
        requestListenable: _subjectRequest,
      ),
      PantallaDatosAtlassian(
        trajectoryListenable: _trajectory,
        localLoadedListenable: _localLoaded,
        selectedCareerListenable: _selectedCareer,
        onDesynchronize: _desynchronize,
        onNavigate: _selectSection,
        onSearch: _openSearch,
      ),
    ];

    final tabs = List<Widget>.generate(5, (index) {
      if (!_builtSections.contains(index)) {
        return KeyedSubtree(
          key: ValueKey<int>(index),
          child: const SizedBox.shrink(),
        );
      }
      return KeyedSubtree(
        key: ValueKey<int>(index),
        child: Navigator(
          key: _navigatorKeys[index],
          observers: <NavigatorObserver>[
            _SectionNavigatorObserver(_handleSectionRouteChanged),
          ],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => sectionChildren[index]),
        ),
      );
    });

    final rawContent = SeccionesMovimientoApp(index: _section, children: tabs);
    final content = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          final pixels = notification.metrics.pixels;
          final progress = (pixels / 48.0).clamp(0.0, 1.0);
          if ((progress - _topBlurProgress.value).abs() > 0.02) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && (progress - _topBlurProgress.value).abs() > 0.02) {
                _topBlurProgress.value = progress;
              }
            });
          }
        }
        return false;
      },
      child: rawContent,
    );
    final isSubRoute = _navigatorKeys[_section].currentState?.canPop() ?? false;
    final allowBlursAndSearch = !desktop && !isSubRoute;
    final showFloatingSearch = allowBlursAndSearch;
    final searchBackground = _section == 0 && !dark
        ? const Color(0xFFF7FAFF)
        : theme.scaffoldBackgroundColor;
    final body = desktop
        ? ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
            valueListenable: _trajectory,
            builder: (context, trajectory, _) {
              return Stack(
                children: [
                  AnimatedPadding(
                    duration: MovimientoApp.duracion(
                      context,
                      MovimientoApp.ruta,
                    ),
                    curve: MovimientoApp.curva,
                    padding: EdgeInsets.only(
                      left: _sidebarHidden ? 0.0 : 180.0,
                    ),
                    child: content,
                  ),
                  NavegacionLateralAtlassian(
                    selectedIndex: _section,
                    onSelected: _selectSection,
                    onExit: widget.hideExit
                        ? null
                        : () {
                            if (Navigator.of(
                              context,
                              rootNavigator: true,
                            ).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    nombreEstudiante: trajectory?.perfil.nombre,
                    hidden: _sidebarHidden,
                  ),
                  // Toggle button at the top-left corner of the screen
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _sidebarHidden = !_sidebarHidden),
                        borderRadius: BorderRadius.circular(
                          RadioAtlassian.medium,
                        ),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(
                              RadioAtlassian.medium,
                            ),
                            boxShadow: [
                              if (_sidebarHidden)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Icon(
                            _sidebarHidden
                                ? Icons.menu_rounded
                                : Icons.menu_open_rounded,
                            size: 26,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        : Stack(
            children: [
              content,
              // Sólo cambia la capa superior; el scroll no reconstruye navegadores.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _topBlurProgress,
                  builder: (context, progress, _) =>
                      !allowBlursAndSearch || progress <= 0.01
                      ? const SizedBox.shrink()
                      : IgnorePointer(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).top + 60,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    theme.scaffoldBackgroundColor.withValues(
                                      alpha: 0.98 * progress,
                                    ),
                                    theme.scaffoldBackgroundColor.withValues(
                                      alpha: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _section == 0 ? 100 : 120,
                child: !showFloatingSearch
                    ? const SizedBox.shrink()
                    : IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                searchBackground,
                                searchBackground.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              // La barra queda fuera de los navegadores y de la animación de
              // las secciones. Sólo su Hero anima la entrada y la salida.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: !showFloatingSearch
                    ? const SizedBox.shrink()
                    : SafeArea(
                        top: false,
                        maintainBottomViewPadding: true,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: _section == 0
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: BarraBusquedaApp(
                              key: _section == 0
                                  ? const ValueKey('inicio-react-liquid-search')
                                  : null,
                              onTap: _openSearch,
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: SafeArea(
                  child: Builder(
                    builder: (btnContext) {
                      final canGoBack =
                          _section != 0 ||
                          (_navigatorKeys[_section].currentState?.canPop() ??
                              false);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (canGoBack) {
                              unawaited(_handleBack());
                            } else {
                              Scaffold.of(btnContext).openDrawer();
                            }
                          },
                          borderRadius: BorderRadius.circular(
                            RadioAtlassian.pill,
                          ),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              canGoBack
                                  ? Icons.arrow_back_rounded
                                  : Icons.short_text_rounded,
                              size: 26,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );

    final overlayStyle = dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarColor: theme.colorScheme.surface,
            systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarColor: theme.colorScheme.surface,
            systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return TrayectoriaActivaAtlassian(
      trayectoria: _trajectory,
      carreraSeleccionada: _selectedCareer,
      cambios: _trajectoryChanges,
      child: Theme(
        data: theme,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final shouldExit = await _handleBack();
              if (shouldExit && !widget.hideExit && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
              valueListenable: _trajectory,
              builder: (context, trajectory, _) {
                return Scaffold(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  resizeToAvoidBottomInset: false,
                  body: CicloBusquedaApp(
                    revision: _searchRevision,
                    barraExterna: !desktop,
                    child: body,
                  ),
                  drawer: desktop
                      ? null
                      : DrawerMovilAtlassian(
                          selectedIndex: _section,
                          onSelected: _selectSection,
                          onSearch: _openSearch,
                          nombreEstudiante: trajectory?.perfil.nombre,
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionNavigatorObserver extends NavigatorObserver {
  _SectionNavigatorObserver(this.onRouteChanged);

  final VoidCallback onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
  }
}

class DrawerMovilAtlassian extends StatelessWidget {
  const DrawerMovilAtlassian({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSearch,
    this.nombreEstudiante,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;
  final String? nombreEstudiante;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iniciales = _obtenerInicialesAtlassian(nombreEstudiante);

    final destinos = <(IconData, String, int)>[
      (Icons.grid_view_rounded, 'Materias', 3),
      (Icons.event_note_rounded, 'Exámenes', 1),
      (Icons.account_tree_rounded, 'Plan', 2),
      (Icons.person_outline_rounded, 'Datos', 4),
    ];

    final topPadding = MediaQuery.paddingOf(context).top;
    final width = (MediaQuery.sizeOf(context).width * 0.70).clamp(250.0, 280.0);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Drawer(
        backgroundColor: scheme.surface,
        width: width,
        shape: const RoundedRectangleBorder(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              right: BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onSelected(0);
                        },
                        child: Text(
                          'Trayectorias',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onSearch();
                        },
                        borderRadius: BorderRadius.circular(
                          RadioAtlassian.pill,
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: scheme.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  for (final item in destinos) ...[
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(item.$3);
                      },
                      borderRadius: BorderRadius.circular(
                        RadioAtlassian.medium,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.$1,
                              color: selectedIndex == item.$3
                                  ? scheme.primary
                                  : scheme.onSurface,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              item.$2,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: selectedIndex == item.$3
                                    ? scheme.primary
                                    : scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          final navigator = Navigator.of(context);
                          Navigator.pop(context);
                          navigator.push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const AccesoAdministradorPantalla(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          RadioAtlassian.pill,
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: scheme.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onSelected(4);
                        },
                        borderRadius: BorderRadius.circular(
                          RadioAtlassian.pill,
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            iniciales,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _obtenerInicialesAtlassian(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return 'US';
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts[0].toUpperCase();
  }
}
