import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../compartido/movimiento/movimiento_app.dart';
import '../../../compartido/navegacion/barra_busqueda_app.dart';
import '../../trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart';
import '../../trayectoria_sage_laboratorio/datos/repositorio_trayectoria_sage_laboratorio.dart';
import '../../trayectoria_sage_laboratorio/documentos_pdf/abrir_documento_academico_sage.dart';
import '../../trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../../trayectoria_sage_laboratorio/sage/modelos_sincronizacion_sage_automatica.dart';
import '../../trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart';
import '../busqueda/modelos_busqueda_atlassian.dart';
import '../componentes/componentes_atlassian.dart';
import '../componentes/inicio_trayectoria_atlassian.dart';
import '../tema/tema_atlassian.dart';
import '../tema/tema_react_developer.dart';
import 'pantalla_calendario_atlassian.dart';
import 'pantalla_centro_sage_atlassian.dart';
import 'pantalla_disenos_atlassian.dart';
import 'pantallas_herramientas_atlassian.dart';
import 'utilidades_atlassian.dart';

class PantallaInicioReactDeveloper extends StatefulWidget {
  const PantallaInicioReactDeveloper({
    super.key,
    required this.trajectoryListenable,
    required this.localLoadedListenable,
    required this.selectedCareerListenable,
    required this.resetListenable,
    required this.actionRequestListenable,
    required this.onTrajectoryChanged,
    required this.onNavigate,
    required this.onSearch,
    this.onExit,
  });

  final ValueNotifier<TrayectoriaSageLaboratorio?> trajectoryListenable;
  final ValueNotifier<bool> localLoadedListenable;
  final ValueNotifier<int> selectedCareerListenable;
  final ValueNotifier<int> resetListenable;
  final ValueListenable<SolicitudInicioAtlassian?> actionRequestListenable;
  final ValueChanged<TrayectoriaSageLaboratorio?> onTrajectoryChanged;
  final ValueChanged<int> onNavigate;
  final VoidCallback onSearch;
  final VoidCallback? onExit;

  @override
  State<PantallaInicioReactDeveloper> createState() =>
      _PantallaInicioReactDeveloperState();
}

class _PantallaInicioReactDeveloperState
    extends State<PantallaInicioReactDeveloper> {
  static const _repository = RepositorioTrayectoriaSageLaboratorio();

  TrayectoriaSageLaboratorio? _draft;
  EstadoPreparacionSageLaboratorio _preparation =
      const EstadoPreparacionSageLaboratorio(mensaje: 'Pendiente');
  bool _saving = false;
  bool _sageFlowOpen = false;
  TipoDocumentoAcademicoSage? _openingDocumentType;
  Set<String> _documentosLocales = {};
  int _cargaDocumentos = 0;

  @override
  void initState() {
    super.initState();
    widget.trajectoryListenable.addListener(_cargarDocumentosLocales);
    widget.selectedCareerListenable.addListener(_cargarDocumentosLocales);
    unawaited(_cargarDocumentosLocales());
    widget.resetListenable.addListener(_resetLocalState);
    widget.actionRequestListenable.addListener(_handleActionRequest);
  }

  @override
  void didUpdateWidget(covariant PantallaInicioReactDeveloper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trajectoryListenable != widget.trajectoryListenable) {
      oldWidget.trajectoryListenable.removeListener(_cargarDocumentosLocales);
      widget.trajectoryListenable.addListener(_cargarDocumentosLocales);
      unawaited(_cargarDocumentosLocales());
    }
    if (oldWidget.selectedCareerListenable != widget.selectedCareerListenable) {
      oldWidget.selectedCareerListenable.removeListener(
        _cargarDocumentosLocales,
      );
      widget.selectedCareerListenable.addListener(_cargarDocumentosLocales);
      unawaited(_cargarDocumentosLocales());
    }
    if (oldWidget.resetListenable != widget.resetListenable) {
      oldWidget.resetListenable.removeListener(_resetLocalState);
      widget.resetListenable.addListener(_resetLocalState);
    }
    if (oldWidget.actionRequestListenable != widget.actionRequestListenable) {
      oldWidget.actionRequestListenable.removeListener(_handleActionRequest);
      widget.actionRequestListenable.addListener(_handleActionRequest);
    }
  }

  @override
  void dispose() {
    widget.trajectoryListenable.removeListener(_cargarDocumentosLocales);
    widget.selectedCareerListenable.removeListener(_cargarDocumentosLocales);
    widget.resetListenable.removeListener(_resetLocalState);
    widget.actionRequestListenable.removeListener(_handleActionRequest);
    super.dispose();
  }

  void _handleActionRequest() {
    final request = widget.actionRequestListenable.value;
    if (request == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (request.accion) {
        case AccionInicioAtlassian.abrirSage:
          unawaited(_openSagePortal());
          return;
        case AccionInicioAtlassian.sincronizar:
          unawaited(_sync());
          return;
        case AccionInicioAtlassian.descargarDocumento:
          final tipo = request.tipoDocumento;
          final documento = tipo == null
              ? null
              : _selectedAcademicDocument(tipo);
          if (documento != null) {
            unawaited(_openAcademicDocument(documento));
          }
          return;
        case AccionInicioAtlassian.cerrarSesionSage:
          unawaited(_openSage(logoutOnOpen: true));
          return;
      }
    });
  }

  void _resetLocalState() {
    if (!mounted) return;
    setState(() {
      _draft = null;
      _preparation = const EstadoPreparacionSageLaboratorio(
        mensaje: 'Pendiente',
      );
      _saving = false;
      _sageFlowOpen = false;
      _openingDocumentType = null;
    });
  }

  CarreraTrayectoriaSageLaboratorio? _currentCareer(
    TrayectoriaSageLaboratorio? trajectory,
    int selectedIndex,
  ) {
    if (trajectory == null || trajectory.carreras.isEmpty) return null;
    final index = selectedIndex
        .clamp(0, trajectory.carreras.length - 1)
        .toInt();
    return trajectory.carreras[index];
  }

  void _pushAtlassian(WidgetBuilder builder) {
    Navigator.of(context).push<void>(rutaAtlassian<void>(builder: builder));
  }

  CarreraTrayectoriaSageLaboratorio? _selectedCareerNow() {
    return _currentCareer(
      widget.trajectoryListenable.value,
      widget.selectedCareerListenable.value,
    );
  }

  DocumentoAcademicoSage? _selectedAcademicDocument(
    TipoDocumentoAcademicoSage tipo,
  ) {
    final trajectory = widget.trajectoryListenable.value;
    final career = _selectedCareerNow();
    if (trajectory == null || career == null) return null;
    final saved = trajectory
        .documentosDeCarrera(career)
        .where((document) => document.tipo == tipo)
        .firstOrNull;
    final documento =
        saved ??
        DocumentoAcademicoSage(
          tipo: tipo,
          gridRowId: career.gridRowId,
          careerKey: career.careerKey,
          carrera: career.nombre,
          institucion: career.institucion,
          disponible:
              career.gridRowId.trim().isNotEmpty ||
              career.careerKey.trim().isNotEmpty,
        );
    try {
      final clave = ClaveDocumentoAcademicoSage.de(
        trajectory.perfil,
        documento,
      );
      if (!documento.disponible && _documentosLocales.contains(clave.id)) {
        return DocumentoAcademicoSage.fromJson({
          ...documento.toJson(),
          'disponible': true,
        });
      }
    } on FormatException {
      /* La identidad se valida antes de obtenerlo. */
    }
    return documento;
  }

  Future<void> _cargarDocumentosLocales() async {
    final carga = ++_cargaDocumentos;
    final perfil = widget.trajectoryListenable.value?.perfil;
    final disponibles = <String>{};
    if (perfil != null) {
      for (final tipo in TipoDocumentoAcademicoSage.values) {
        final documento = _selectedAcademicDocument(tipo);
        if (documento == null) continue;
        try {
          final clave = ClaveDocumentoAcademicoSage.de(perfil, documento);
          if (await const RepositorioDocumentosAcademicosSage().cargar(clave) !=
              null) {
            disponibles.add(clave.id);
          }
        } catch (_) {}
      }
    }
    if (mounted && carga == _cargaDocumentos) {
      setState(() => _documentosLocales = disponibles);
    }
  }

  void _openScenarios() {
    _pushAtlassian((_) => const PantallaEscenariosAtlassian());
  }

  void _openHelp() {
    _pushAtlassian((_) => const PantallaAyudaAtlassian());
  }

  void _openNextSteps() {
    final career = _selectedCareerNow();
    _pushAtlassian((_) => PantallaProximosPasosAtlassian(career: career));
  }

  void _openProgress() {
    final career = _selectedCareerNow();
    _pushAtlassian((_) => PantallaAvanceAtlassian(career: career));
  }

  void _openCalendar() {
    final career = _selectedCareerNow();
    _pushAtlassian(
      (_) => PantallaCalendarioAtlassian(
        careerId: idCarreraExamenAtlassian(career?.nombre ?? 'historia'),
        trayectoria: widget.trajectoryListenable.value,
      ),
    );
  }

  void _openDesigns() {
    _pushAtlassian((_) => const PantallaDisenosAtlassian());
  }

  Future<TrayectoriaSageLaboratorio> _saveAutomaticTrajectory(
    TrayectoriaSageLaboratorio draft,
  ) async {
    if (!draft.listaParaSincronizar) {
      throw const ErrorSincronizacionSageAutomatica(
        'SAGE no entregó una trayectoria válida para guardar.',
      );
    }

    final current = widget.trajectoryListenable.value;
    if (current != null && !_sameProfile(current.perfil, draft.perfil)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reemplazar trayectoria'),
          content: Text('${current.perfil.nombre} → ${draft.perfil.nombre}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      if (replace != true) {
        throw const ErrorSincronizacionSageAutomatica(
          'La sincronización fue cancelada.',
        );
      }
    }

    if (mounted) setState(() => _saving = true);
    final previousCareer = _currentCareer(
      current,
      widget.selectedCareerListenable.value,
    );
    try {
      final stored = await _repository.guardarIdempotente(draft);
      if (!mounted) return stored;
      widget.onTrajectoryChanged(stored);
      widget.selectedCareerListenable.value = _matchingCareerIndex(
        stored,
        previousCareer,
      );
      setState(() {
        _draft = null;
        _preparation = EstadoPreparacionSageLaboratorio(
          mensaje: '${stored.totalMaterias} materias sincronizadas',
          progreso: 1,
        );
      });
      return stored;
    } catch (error) {
      if (error is ErrorSincronizacionSageAutomatica) rethrow;
      throw const ErrorSincronizacionSageAutomatica(
        'No se pudo guardar la trayectoria en el dispositivo.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSage({bool logoutOnOpen = false}) async {
    if (_saving || _sageFlowOpen) return;
    setState(() {
      _sageFlowOpen = true;
      _draft = null;
      _preparation = EstadoPreparacionSageLaboratorio(
        mensaje: logoutOnOpen
            ? 'Cerrando sesión de SAGE'
            : 'Preparando sincronización',
      );
    });
    try {
      await _runSageScreen(
        automatic: !logoutOnOpen,
        logoutOnOpen: logoutOnOpen,
      );
    } finally {
      if (mounted) setState(() => _sageFlowOpen = false);
    }
  }

  Future<void> _openSagePortal() async {
    if (_saving || _sageFlowOpen) return;
    setState(() {
      _sageFlowOpen = true;
      _draft = null;
      _preparation = const EstadoPreparacionSageLaboratorio(
        mensaje: 'Conectando con SAGE',
      );
    });
    final atlassianTheme = temaLaboratorioAtlassian(context);
    try {
      final authenticated = await Navigator.of(context, rootNavigator: true)
          .push<bool>(
            rutaAtlassian<bool>(
              builder: (sageContext) => PantallaSageLaboratorio(
                onClose: () => Navigator.of(sageContext).pop(false),
                onSesionAutenticada: () {
                  if (Navigator.of(sageContext).canPop()) {
                    Navigator.of(sageContext).pop(true);
                  }
                },
                themeOverride: atlassianTheme,
                appBarBackground: atlassianTheme.colorScheme.surface,
                appBarForeground: atlassianTheme.colorScheme.onSurface,
                title: 'Conectar con SAGE',
                modo: ModoPantallaSageLaboratorio.autenticacion,
                perfilEsperado: widget.trajectoryListenable.value?.perfil,
                onEstadoPreparacion: (status) {
                  if (!mounted) return;
                  setState(() => _preparation = status);
                },
              ),
            ),
          );
      if (!mounted || authenticated != true) return;

      final action = await Navigator.of(context, rootNavigator: true)
          .push<AccionCentroSageAtlassian>(
            rutaAtlassian<AccionCentroSageAtlassian>(
              builder: (_) => PantallaCentroSageAtlassian(
                ultimaSincronizacion:
                    widget.trajectoryListenable.value?.sincronizadaEn,
              ),
            ),
          );
      if (!mounted || action == null) return;

      switch (action) {
        case AccionCentroSageAtlassian.sincronizar:
          await _runSageScreen(automatic: true);
          return;
        case AccionCentroSageAtlassian.abrirSage:
          await _runSageScreen(automatic: false);
          return;
      }
    } finally {
      if (mounted) setState(() => _sageFlowOpen = false);
    }
  }

  Future<void> _runSageScreen({
    required bool automatic,
    bool logoutOnOpen = false,
  }) async {
    if (!mounted) return;
    final atlassianTheme = temaLaboratorioAtlassian(context);
    await Navigator.of(context, rootNavigator: true).push<void>(
      rutaAtlassian<void>(
        builder: (sageContext) => PantallaSageLaboratorio(
          onClose: () => Navigator.of(sageContext).pop(),
          themeOverride: atlassianTheme,
          appBarBackground: atlassianTheme.colorScheme.surface,
          appBarForeground: atlassianTheme.colorScheme.onSurface,
          title: logoutOnOpen
              ? 'Cerrar sesión de SAGE'
              : automatic
              ? 'Sincronizar con SAGE'
              : 'SAGE',
          logoutOnOpen: logoutOnOpen,
          modo: automatic
              ? ModoPantallaSageLaboratorio.sincronizacionAutomatica
              : ModoPantallaSageLaboratorio.manual,
          onGuardarTrayectoriaAutomatica: automatic
              ? _saveAutomaticTrajectory
              : null,
          perfilEsperado: widget.trajectoryListenable.value?.perfil,
          onSesionCerrada: () {
            if (!mounted) return;
            setState(() {
              _preparation = const EstadoPreparacionSageLaboratorio(
                mensaje: 'Sesión de SAGE cerrada',
              );
            });
          },
          onTrayectoriaLista: automatic
              ? null
              : (trajectory) {
                  if (!mounted) return;
                  setState(() {
                    _draft = trajectory;
                    _preparation = EstadoPreparacionSageLaboratorio(
                      mensaje:
                          '${trajectory.totalMaterias} materias listas para sincronizar.',
                      progreso: 1,
                    );
                  });
                },
          onEstadoPreparacion: (status) {
            if (!mounted) return;
            setState(() => _preparation = status);
          },
        ),
      ),
    );
  }

  Future<void> _openAcademicDocument(DocumentoAcademicoSage document) async {
    if (!document.disponible || _saving || _sageFlowOpen) return;
    setState(() {
      _sageFlowOpen = true;
      _openingDocumentType = document.tipo;
      _preparation = EstadoPreparacionSageLaboratorio(
        mensaje: 'Preparando ${document.tipo.etiqueta}',
      );
    });
    try {
      final perfil = widget.trajectoryListenable.value?.perfil;
      if (perfil == null) return;
      await abrirDocumentoAcademicoSage(
        context,
        documento: document,
        perfil: perfil,
        onEstadoPreparacion: (status) {
          if (mounted) setState(() => _preparation = status);
        },
      );
      await _cargarDocumentosLocales();
    } catch (error, stack) {
      // El diagnóstico no incluye credenciales ni datos del titular.
      debugPrint('SAGE documento: ${error.runtimeType}');
      debugPrint(stack.toString().split('\n').take(4).join('\n'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el documento académico.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sageFlowOpen = false;
          _openingDocumentType = null;
        });
      }
    }
  }

  Future<void> _sync() async {
    if (_saving || _sageFlowOpen) return;
    final draft = _draft;
    if (draft == null || !draft.listaParaSincronizar) {
      await _openSage();
      return;
    }
    final current = widget.trajectoryListenable.value;
    if (current != null && !_sameProfile(current.perfil, draft.perfil)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reemplazar trayectoria'),
          content: Text('${current.perfil.nombre} → ${draft.perfil.nombre}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final previousCareer = _currentCareer(
        current,
        widget.selectedCareerListenable.value,
      );
      final stored = await _repository.guardarIdempotente(draft);
      if (!mounted) return;
      widget.onTrajectoryChanged(stored);
      widget.selectedCareerListenable.value = _matchingCareerIndex(
        stored,
        previousCareer,
      );
      setState(() {
        _preparation = const EstadoPreparacionSageLaboratorio(
          mensaje: 'Sincronización completada',
          progreso: 1,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stored.totalMaterias} materias sincronizadas'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la trayectoria local.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _matchingCareerIndex(
    TrayectoriaSageLaboratorio trajectory,
    CarreraTrayectoriaSageLaboratorio? previous,
  ) {
    if (trajectory.carreras.isEmpty || previous == null) return 0;
    final previousKey = _careerIdentity(previous);
    final index = trajectory.carreras.indexWhere(
      (career) => _careerIdentity(career) == previousKey,
    );
    return index < 0 ? 0 : index;
  }

  String _careerIdentity(CarreraTrayectoriaSageLaboratorio career) {
    final structural = career.careerKey.trim();
    if (structural.isNotEmpty) return structural.toLowerCase();
    return <String>[
      career.nombre.trim().toLowerCase(),
      career.institucion.trim().toLowerCase(),
      career.anioInicio?.toString() ?? '',
    ].join('|');
  }

  Future<void> _chooseCareer(TrayectoriaSageLaboratorio trajectory) async {
    if (trajectory.carreras.length < 2) return;
    final selected = await mostrarHojaAtlassian<int>(
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
              for (var index = 0; index < trajectory.carreras.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PanelAtlassian(
                    selected: index == widget.selectedCareerListenable.value,
                    onTap: () => Navigator.of(sheetContext).pop(index),
                    child: Row(
                      children: [
                        Icon(
                          index == widget.selectedCareerListenable.value
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: index == widget.selectedCareerListenable.value
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (trajectory.carreras[index].institucion
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  trajectory.carreras[index].institucion,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    widget.selectedCareerListenable.value = selected;
  }

  @override
  Widget build(BuildContext context) {
    final mostrarBarra = !CicloBusquedaApp.barraExternaDe(context);
    return ValueListenableBuilder<bool>(
      valueListenable: widget.localLoadedListenable,
      builder: (context, loaded, _) {
        return ValueListenableBuilder<TrayectoriaSageLaboratorio?>(
          valueListenable: widget.trajectoryListenable,
          builder: (context, trajectory, _) {
            return ValueListenableBuilder<int>(
              valueListenable: widget.selectedCareerListenable,
              builder: (context, selectedCareer, _) {
                final reactTheme = context.reactTheme;
                final quickDocuments = trajectory == null
                    ? const <DocumentoAcademicoSage>[]
                    : <DocumentoAcademicoSage>[
                        for (final type in const <TipoDocumentoAcademicoSage>[
                          TipoDocumentoAcademicoSage.situacionAcademica,
                          TipoDocumentoAcademicoSage.analitico,
                          TipoDocumentoAcademicoSage.libreta,
                        ])
                          if (_selectedAcademicDocument(type)
                              case final document?)
                            document,
                      ];

                return Scaffold(
                  backgroundColor: reactTheme.canvas,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      Column(
                        key: const ValueKey<String>('inicio-react-layout'),
                        children: [
                          _EncabezadoInicioReact(
                            nombre: trajectory?.perfil.nombre,
                          ),
                          Expanded(
                            child: EntradaContenidoApp(
                              orden: 1,
                              child: _InicioReactSoloBusqueda(
                                loaded: loaded,
                                hasTrajectory: trajectory != null,
                                busy: _saving || _sageFlowOpen,
                                documents: quickDocuments,
                                onSync: _sync,
                                onOpenDocument: _openAcademicDocument,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (mostrarBarra)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    reactTheme.canvas,
                                    reactTheme.canvas.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (mostrarBarra)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            top: false,
                            maintainBottomViewPadding: true,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: _BusquedaLiquidGlassReact(
                                    onTap: widget.onSearch,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EncabezadoInicioReact extends StatelessWidget {
  const _EncabezadoInicioReact({required this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final greeting = saludoAtlassian(nombre);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 78),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: reduceMotion ? Duration.zero : MovimientoApp.entrada,
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - progress)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF579DFF), Color(0xFFA78BFA)],
                      ).createShader(bounds),
                      child: Text(
                        'tu trayectoria',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InicioReactSoloBusqueda extends StatelessWidget {
  const _InicioReactSoloBusqueda({
    required this.loaded,
    required this.hasTrajectory,
    required this.busy,
    required this.documents,
    required this.onSync,
    required this.onOpenDocument,
  });

  final bool loaded;
  final bool hasTrajectory;
  final bool busy;
  final List<DocumentoAcademicoSage> documents;
  final VoidCallback onSync;
  final ValueChanged<DocumentoAcademicoSage> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final reactTheme = context.reactTheme;
    final messageStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: reactTheme.text,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.7,
      height: 1.05,
    );
    final helperStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: reactTheme.muted(0.78),
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return Stack(
      children: [
        if (loaded && !hasTrajectory)
          Center(
            child: Transform.scale(
              scale: 0.70,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/sage_wordmark_react.png',
                    key: const ValueKey<String>('inicio-react-sync-sage-logo'),
                    width: 140,
                    height: 48,
                    fit: BoxFit.contain,
                    color: reactTheme.isDark ? null : reactTheme.wordmark,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.school_rounded, color: reactTheme.wordmark),
                  ),
                  const SizedBox(width: 14),
                  Transform.scale(
                    scale: 1.15,
                    child: SizedBox(
                      width: busy ? 176 : 128,
                      child: FilledButton(
                        key: const ValueKey<String>('inicio-react-sync-button'),
                        onPressed: busy ? null : onSync,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0C66E4),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(
                            0xFF0C66E4,
                          ).withValues(alpha: 0.34),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.58,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 13,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            busy ? 'sincronizando…' : 'sincronizar',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 138 + bottomInset),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  key: const ValueKey<String>('inicio-react-search-home-empty'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loaded && hasTrajectory && documents.isNotEmpty)
                      Column(
                        key: const ValueKey<String>(
                          'inicio-react-document-shortcuts',
                        ),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final document in documents)
                            _AccesoDocumentoInicioReact(
                              document: document,
                              busy: busy,
                              onTap: () => onOpenDocument(document),
                            ),
                        ],
                      )
                    else ...[
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: reactTheme.isDark
                              ? const [Color(0xFFFFFFFF), Color(0xFF9FADFF)]
                              : const [Color(0xFF172B4D), Color(0xFF3B5CCC)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          loaded
                              ? 'empezá buscando lo que quieras'
                              : 'cargando tu espacio de búsqueda',
                          textAlign: TextAlign.center,
                          style: messageStyle?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loaded
                            ? 'todo lo que necesitás está acá'
                            : 'en unos segundos vas a poder buscar y saltar directo',
                        textAlign: TextAlign.center,
                        style: helperStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccesoDocumentoInicioReact extends StatelessWidget {
  const _AccesoDocumentoInicioReact({
    required this.document,
    required this.busy,
    required this.onTap,
  });

  final DocumentoAcademicoSage document;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reactTheme = context.reactTheme;
    final enabled = document.disponible && !busy;
    final accent = switch (document.tipo) {
      TipoDocumentoAcademicoSage.situacionAcademica => const Color(0xFF0C66E4),
      TipoDocumentoAcademicoSage.analitico => const Color(0xFF6554C0),
      TipoDocumentoAcademicoSage.libreta => const Color(0xFF00875A),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Abrir ${document.tipo.etiqueta}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('inicio-react-document-${document.tipo.clave}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _iconForDocument(document.tipo),
                    color: enabled ? accent : reactTheme.muted(0.42),
                    size: 25,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      document.tipo.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: enabled
                            ? reactTheme.text
                            : reactTheme.muted(0.42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BusquedaLiquidGlassReact extends StatelessWidget {
  const _BusquedaLiquidGlassReact({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BarraBusquedaApp(
    key: const ValueKey<String>('inicio-react-liquid-search'),
    onTap: onTap,
  );
}

class _HeroPerfilReact extends StatelessWidget {
  const _HeroPerfilReact({
    required this.trajectory,
    required this.career,
    required this.onChooseCareer,
    required this.onOpenMaterias,
    required this.onOpenPlan,
    required this.onOpenExams,
    required this.onSync,
    required this.syncEnabled,
    required this.syncing,
  });

  final TrayectoriaSageLaboratorio trajectory;
  final CarreraTrayectoriaSageLaboratorio career;
  final VoidCallback onChooseCareer;
  final VoidCallback onOpenMaterias;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenExams;
  final VoidCallback onSync;
  final bool syncEnabled;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final name = nombrePerfilAtlassian(trajectory.perfil);
    final hasMultipleCareers = trajectory.carreras.length > 1;
    final careerTitle = _friendlyCareerTitle(career.nombre);
    final careerResolution = _careerResolutionLabel(career.nombre);
    final institution = _friendlyAcademicText(career.institucion);

    return Padding(
      key: const ValueKey<String>('inicio-react-hero'),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: hasMultipleCareers ? onChooseCareer : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                careerTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFE9F2FF),
                                      fontWeight: FontWeight.w600,
                                      height: 1.18,
                                    ),
                              ),
                            ),
                            if (hasMultipleCareers) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFFD6E4FF),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (careerResolution != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        careerResolution,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: const Color(0xFFB8C7E0),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    if (institution.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        institution,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.64),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            key: const ValueKey<String>('inicio-react-hero-actions'),
            children: [
              Expanded(
                child: _AccionHeroReact(
                  label: 'materias',
                  icon: Icons.grid_view_rounded,
                  accent: const Color(0xFF579DFF),
                  onTap: onOpenMaterias,
                ),
              ),
              Expanded(
                child: _AccionHeroReact(
                  label: 'plan',
                  icon: Icons.assignment_rounded,
                  accent: const Color(0xFFA78BFA),
                  onTap: onOpenPlan,
                ),
              ),
              Expanded(
                child: _AccionHeroReact(
                  label: 'mesas',
                  icon: Icons.event_note_rounded,
                  accent: const Color(0xFF60C6D2),
                  onTap: onOpenExams,
                ),
              ),
              Expanded(
                child: _AccionHeroReact(
                  label: syncing ? 'sincronizando' : 'sincronizar',
                  icon: syncing
                      ? Icons.hourglass_top_rounded
                      : Icons.sync_rounded,
                  accent: const Color(0xFF0C66E4),
                  onTap: syncEnabled ? onSync : null,
                  emphasized: true,
                ),
              ),
            ],
          ),
          if (trajectory.sincronizadaEn != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: Colors.white.withValues(alpha: 0.62),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'actualizado ${_formatLastSyncReact(trajectory.sincronizadaEn!)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccionHeroReact extends StatefulWidget {
  const _AccionHeroReact({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  State<_AccionHeroReact> createState() => _AccionHeroReactState();
}

class _AccionHeroReactState extends State<_AccionHeroReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onTap != null;
    final duration = reduceMotion ? Duration.zero : MovimientoApp.respuesta;
    final foreground = enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.34);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: enabled
            ? (pressed) {
                if (_pressed == pressed) return;
                setState(() => _pressed = pressed);
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              AnimatedScale(
                duration: duration,
                curve: Curves.easeOutBack,
                scale: _pressed && enabled ? 1.06 : 1,
                child: SizedBox(
                  key: ValueKey<String>('inicio-react-glass-${widget.label}'),
                  width: 52,
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedRotation(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        turns: _pressed ? 0.018 : 0,
                        child: Container(
                          key: ValueKey<String>(
                            'inicio-react-glass-back-${widget.label}',
                          ),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.accent.withValues(alpha: 0.88),
                                widget.accent.withValues(alpha: 0.34),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accent.withValues(alpha: 0.18),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedScale(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        scale: _pressed ? 0.95 : 0.92,
                        child: Container(
                          key: ValueKey<String>(
                            'inicio-react-glass-front-${widget.label}',
                          ),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(
                              alpha: widget.emphasized ? 0.18 : 0.13,
                            ),
                            border: Border.all(
                              color: widget.accent.withValues(
                                alpha: widget.emphasized ? 0.66 : 0.34,
                              ),
                            ),
                          ),
                          child: Icon(widget.icon, size: 21, color: foreground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: Center(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: enabled
                          ? Colors.white.withValues(alpha: 0.88)
                          : Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloSeccionReact extends StatelessWidget {
  const _TituloSeccionReact({required this.primary, required this.accent});

  final String primary;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1.04,
      letterSpacing: -0.9,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primary, style: style),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF579DFF), Color(0xFF9F8CFF), Color(0xFF36B37E)],
          ).createShader(bounds),
          child: Text(accent, style: style?.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

class _BentoProgresoReact extends StatelessWidget {
  const _BentoProgresoReact({required this.career});

  final CarreraTrayectoriaSageLaboratorio career;

  @override
  Widget build(BuildContext context) {
    final total = career.materias.length;
    final approved = career.aprobadas;
    final inProgress = career.cursando;
    final remaining = (total - approved - inProgress).clamp(0, total).toInt();
    final ratio = total == 0 ? 0.0 : approved / total;
    return Padding(
      key: const ValueKey<String>('inicio-react-progress'),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _CountUpReact(
                          value: (ratio * 100).round(),
                          suffix: '%',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.2,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'de la carrera',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$approved de $total materias aprobadas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  career.estadoInscripcion?.trim().isNotEmpty == true
                      ? career.estadoInscripcion!.toLowerCase()
                      : 'trayectoria',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  if (total > 0)
                    Expanded(
                      flex: approved,
                      child: Container(color: const Color(0xFF36B37E)),
                    ),
                  if (total > 0 && inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: Container(color: const Color(0xFF0C66E4)),
                    ),
                  if (total > 0 && remaining > 0)
                    Expanded(
                      flex: remaining,
                      child: Container(color: const Color(0xFF596780)),
                    ),
                  if (total == 0)
                    Expanded(child: Container(color: const Color(0xFF596780))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricaBentoReact(
                  value: approved,
                  label: 'aprobadas',
                  color: const Color(0xFF36B37E),
                ),
              ),
              Expanded(
                child: _MetricaBentoReact(
                  value: inProgress,
                  label: 'cursando',
                  color: const Color(0xFF579DFF),
                ),
              ),
              Expanded(
                child: _MetricaBentoReact(
                  value: remaining,
                  label: 'restantes',
                  color: const Color(0xFFB6C2CF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricaBentoReact extends StatelessWidget {
  const _MetricaBentoReact({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountUpReact(
          value: value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.66),
          ),
        ),
      ],
    );
  }
}

class _CountUpReact extends StatelessWidget {
  const _CountUpReact({required this.value, this.suffix = '', this.style});

  final int value;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduceMotion ? Duration.zero : MovimientoApp.entrada,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          Text('${current.round()}$suffix', style: style),
    );
  }
}

class _DocumentosReact extends StatelessWidget {
  const _DocumentosReact({
    required this.documentos,
    required this.busy,
    required this.loadingType,
    required this.onOpen,
  });

  final List<DocumentoAcademicoSage> documentos;
  final bool busy;
  final TipoDocumentoAcademicoSage? loadingType;
  final ValueChanged<DocumentoAcademicoSage> onOpen;

  @override
  Widget build(BuildContext context) {
    final ordered = <DocumentoAcademicoSage>[
      for (final type in TipoDocumentoAcademicoSage.values)
        _preferred(type) ??
            DocumentoAcademicoSage(
              tipo: type,
              gridRowId: documentos.first.gridRowId,
              careerKey: documentos.first.careerKey,
              carrera: documentos.first.carrera,
              institucion: documentos.first.institucion,
              disponible: false,
            ),
    ];
    final available = ordered.where((item) => item.disponible).length;

    return Column(
      key: const ValueKey<String>('inicio-react-docs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _TituloSeccionReact(
                primary: 'documentos',
                accent: 'académicos',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: available > 0
                          ? const Color(0xFF36B37E)
                          : const Color(0xFF8993A4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    available == 1 ? '1 disponible' : '$available disponibles',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (available == 0)
          _DocumentosBloqueadosReact()
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < ordered.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _DocumentoReactCard(
                    documento: ordered[index],
                    loading: loadingType == ordered[index].tipo,
                    busy: busy,
                    index: index,
                    onOpen: onOpen,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  DocumentoAcademicoSage? _preferred(TipoDocumentoAcademicoSage type) {
    DocumentoAcademicoSage? selected;
    for (final document in documentos) {
      if (document.tipo != type) continue;
      selected ??= document;
      if (document.disponible) return document;
    }
    return selected;
  }
}

class _DocumentoReactCard extends StatefulWidget {
  const _DocumentoReactCard({
    required this.documento,
    required this.loading,
    required this.busy,
    required this.index,
    required this.onOpen,
  });

  final DocumentoAcademicoSage documento;
  final bool loading;
  final bool busy;
  final int index;
  final ValueChanged<DocumentoAcademicoSage> onOpen;

  @override
  State<_DocumentoReactCard> createState() => _DocumentoReactCardState();
}

class _DocumentoReactCardState extends State<_DocumentoReactCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final available = widget.documento.disponible;
    final enabled = available && !widget.busy;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final accent = const [
      Color(0xFF0C66E4),
      Color(0xFF6554C0),
      Color(0xFF00875A),
    ][widget.index.clamp(0, 2).toInt()];

    return AnimatedScale(
      duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
      scale: _pressed && enabled ? 0.96 : 1,
      child: Opacity(
        opacity: available ? (widget.busy && !widget.loading ? 0.58 : 1) : 0.42,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => widget.onOpen(widget.documento) : null,
            onHighlightChanged: enabled
                ? (pressed) {
                    if (_pressed == pressed) return;
                    setState(() => _pressed = pressed);
                  }
                : null,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              height: 136,
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 48,
                    child: widget.loading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: accent,
                            ),
                          )
                        : Icon(
                            _iconForDocument(widget.documento.tipo),
                            size: 30,
                            color: available
                                ? const Color(0xFFD6E4FF)
                                : const Color(0xFF8993A4),
                          ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    widget.documento.tipo.etiqueta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentosBloqueadosReact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF161922), Color(0xFF11131A)],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_copy_outlined, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'disponibles con el perfil Estudiante de SAGE',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'situación académica · analítico · libreta',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightReact extends StatefulWidget {
  const _SpotlightReact({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SpotlightReact> createState() => _SpotlightReactState();
}

class _SpotlightReactState extends State<_SpotlightReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'próximo',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFC0B6F2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mesas y fechas publicadas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'revisá tus próximos llamados y organizá qué rendir',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
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

class _HerramientasBentoReact extends StatelessWidget {
  const _HerramientasBentoReact({
    required this.onOpenRecord,
    required this.onOpenScenarios,
    required this.onOpenHelp,
    required this.onOpenNextSteps,
    required this.onOpenProgress,
    required this.onOpenCalendar,
    required this.onOpenDesigns,
  });

  final VoidCallback onOpenRecord;
  final VoidCallback onOpenScenarios;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenNextSteps;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenDesigns;

  @override
  Widget build(BuildContext context) {
    final items = <_BentoActionData>[
      _BentoActionData(
        title: 'mi registro',
        subtitle: 'toda tu trayectoria académica',
        icon: Icons.dashboard_customize_rounded,
        wide: true,
        colors: const [Color(0xFF063970), Color(0xFF16245A)],
        onTap: onOpenRecord,
      ),
      _BentoActionData(
        title: 'calendario',
        subtitle: 'fechas y eventos',
        icon: Icons.calendar_month_rounded,
        colors: const [Color(0xFF073B4C), Color(0xFF0A2F36)],
        onTap: onOpenCalendar,
      ),
      _BentoActionData(
        title: 'próximos pasos',
        subtitle: 'prioridades académicas',
        icon: Icons.alt_route_rounded,
        colors: const [Color(0xFF402050), Color(0xFF251638)],
        onTap: onOpenNextSteps,
      ),
      _BentoActionData(
        title: 'escenarios',
        subtitle: 'probá qué se habilita cuando avanzás',
        icon: Icons.science_rounded,
        wide: true,
        colors: const [Color(0xFF1F3A2E), Color(0xFF122B25)],
        onTap: onOpenScenarios,
      ),
      _BentoActionData(
        title: 'mi avance',
        subtitle: 'progreso por año',
        icon: Icons.stacked_line_chart_rounded,
        colors: const [Color(0xFF352445), Color(0xFF1E233C)],
        onTap: onOpenProgress,
      ),
      _BentoActionData(
        title: 'diseños',
        subtitle: 'contenidos curriculares',
        icon: Icons.auto_stories_rounded,
        colors: const [Color(0xFF493119), Color(0xFF272017)],
        onTap: onOpenDesigns,
      ),
      _BentoActionData(
        title: 'ayuda',
        subtitle: 'normativa y consultas',
        icon: Icons.help_center_rounded,
        wide: true,
        colors: const [Color(0xFF162B4A), Color(0xFF171A2F)],
        onTap: onOpenHelp,
      ),
    ];

    return LayoutBuilder(
      key: const ValueKey<String>('inicio-react-tools'),
      builder: (context, constraints) {
        const gap = 10.0;
        final half = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: item.wide ? constraints.maxWidth : half,
                child: _BentoActionReact(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _BentoActionData {
  const _BentoActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool wide;
}

class _BentoActionReact extends StatefulWidget {
  const _BentoActionReact({required this.item});

  final _BentoActionData item;

  @override
  State<_BentoActionReact> createState() => _BentoActionReactState();
}

class _BentoActionReactState extends State<_BentoActionReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final item = widget.item;
    final duration = reduceMotion ? Duration.zero : MovimientoApp.respuesta;

    return AnimatedScale(
      duration: duration,
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.982 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: duration,
            height: item.wide ? 116 : 136,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent,
              border: Border.all(
                color: _pressed
                    ? Colors.white.withValues(alpha: 0.20)
                    : item.colors.first.withValues(alpha: 0.62),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    height: 1.16,
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

class _ActividadChromaReact extends StatelessWidget {
  const _ActividadChromaReact({required this.career, required this.onOpenAll});

  final CarreraTrayectoriaSageLaboratorio career;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final subjects = career.materias.reversed.take(6).toList(growable: false);
    return Column(
      key: const ValueKey<String>('inicio-react-activity'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _TituloSeccionReact(
                primary: 'últimos',
                accent: 'movimientos',
              ),
            ),
            TextButton(onPressed: onOpenAll, child: const Text('ver todas')),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: 184,
              child: _MateriaChromaReact(
                materia: subjects[index],
                onTap: onOpenAll,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MateriaChromaReact extends StatefulWidget {
  const _MateriaChromaReact({required this.materia, required this.onTap});

  final MateriaTrayectoriaSageLaboratorio materia;
  final VoidCallback onTap;

  @override
  State<_MateriaChromaReact> createState() => _MateriaChromaReactState();
}

class _MateriaChromaReactState extends State<_MateriaChromaReact> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final materia = widget.materia;
    final accent = _colorMateriaReact(materia.estado);
    final note = materia.nota?.trim() ?? '';
    final state = materia.estado.etiqueta.toLowerCase();

    return AnimatedScale(
      duration: reduceMotion ? Duration.zero : MovimientoApp.respuesta,
      scale: _pressed ? 0.982 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  const Color(0xFF11151D),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(minWidth: 38),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(13),
                          color: accent.withValues(alpha: 0.16),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.38),
                          ),
                        ),
                        child: Text(
                          _compactGrade(note),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      )
                    else
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const Spacer(),
                    if (materia.anio != null)
                      Text(
                        '${materia.anio}º',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.48),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  _friendlySubjectName(materia.nombre),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _InicioReactSinTrayectoria extends StatelessWidget {
  const _InicioReactSinTrayectoria({
    required this.loaded,
    required this.preparation,
    required this.busy,
    required this.onSync,
  });

  final bool loaded;
  final EstadoPreparacionSageLaboratorio preparation;
  final bool busy;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        (media.size.height -
                media.padding.top -
                media.padding.bottom -
                92 -
                126 -
                20)
            .clamp(320.0, 620.0)
            .toDouble();

    return SizedBox(
      key: const ValueKey<String>('inicio-react-empty-state'),
      height: availableHeight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            key: const ValueKey<String>('inicio-react-connect-card'),
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B2C5C), Color(0xFF2B1749)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loaded ? 'conectá tu trayectoria' : 'cargando tu trayectoria',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  preparation.mensaje,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: busy ? null : onSync,
                  icon: Icon(
                    busy ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                  ),
                  label: Text(busy ? 'sincronizando…' : 'sincronizar con SAGE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconForDocument(TipoDocumentoAcademicoSage type) => switch (type) {
  TipoDocumentoAcademicoSage.situacionAcademica =>
    Icons.assignment_ind_outlined,
  TipoDocumentoAcademicoSage.analitico => Icons.fact_check_outlined,
  TipoDocumentoAcademicoSage.libreta => Icons.menu_book_outlined,
};

Color _colorMateriaReact(EstadoMateriaSageLaboratorio state) => switch (state) {
  EstadoMateriaSageLaboratorio.aprobada => const Color(0xFF36B37E),
  EstadoMateriaSageLaboratorio.cursando => const Color(0xFF579DFF),
  EstadoMateriaSageLaboratorio.regular => const Color(0xFFA78BFA),
  EstadoMateriaSageLaboratorio.noRegularizada => const Color(0xFFF5CD47),
  EstadoMateriaSageLaboratorio.desconocida => const Color(0xFF8993A4),
};

String _friendlyAcademicText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final friendly = _friendlySubjectName(trimmed);
  return friendly
      .replaceAll('Educacion', 'Educación')
      .replaceAll('educacion', 'educación')
      .replaceAll('C.g.e.', 'C.G.E.')
      .replaceAll('c.g.e.', 'C.G.E.')
      .replaceAll('P.s.c.s.', 'P.S.C.S.')
      .replaceAll('p.s.c.s.', 'P.S.C.S.');
}

String _friendlyCareerTitle(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final upper = trimmed.toUpperCase();
  final professorIndex = upper.indexOf('PROF. DE ');
  final title = professorIndex >= 0
      ? trimmed.substring(professorIndex)
      : trimmed;
  return _friendlyAcademicText(title);
}

String? _careerResolutionLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final professorIndex = trimmed.toUpperCase().indexOf('PROF. DE ');
  if (professorIndex <= 0) return null;
  var prefix = trimmed.substring(0, professorIndex).trim();
  if (prefix.isEmpty) return null;
  prefix = _friendlyAcademicText(prefix);
  if (prefix.toLowerCase().startsWith('res ')) {
    prefix = 'Res. ${prefix.substring(4)}';
  }
  return prefix;
}

String _compactGrade(String raw) {
  final parsed = double.tryParse(raw.replaceAll(',', '.'));
  if (parsed == null) return raw;
  if (parsed == parsed.roundToDouble()) return parsed.round().toString();
  return parsed.toStringAsFixed(1);
}

String _friendlySubjectName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  final hasLower = trimmed.runes.any((rune) {
    final char = String.fromCharCode(rune);
    return char.toLowerCase() == char && char.toUpperCase() != char;
  });
  if (hasLower) return trimmed;
  final lower = trimmed.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

String _formatLastSyncReact(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  if (sameDay) return 'hoy $hour:$minute';
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

bool _sameProfile(
  PerfilTrayectoriaSageLaboratorio first,
  PerfilTrayectoriaSageLaboratorio second,
) {
  final firstDni = first.dni?.replaceAll(RegExp(r'\D'), '') ?? '';
  final secondDni = second.dni?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (firstDni.isNotEmpty && secondDni.isNotEmpty) return firstDni == secondDni;
  return first.nombre.trim().toLowerCase() ==
      second.nombre.trim().toLowerCase();
}
