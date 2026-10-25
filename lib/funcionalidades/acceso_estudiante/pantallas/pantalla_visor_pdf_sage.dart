import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../laboratorio_atlassian/componentes/componentes_atlassian.dart';
import '../../laboratorio_atlassian/tema/tema_atlassian.dart';
import '../../laboratorio_atlassian/tema/tema_react_developer.dart';
import '../../trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart';
import '../../trayectoria_sage_laboratorio/documentos_pdf/extractor_documento_academico_pdf.dart';
import '../../trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart';
import '../../trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart';
import '../../trayectoria_sage_laboratorio/sage/estilo_visual_sage.dart';

class PantallaVisorPdfSage extends StatefulWidget {
  const PantallaVisorPdfSage({
    super.key,
    required this.rutaArchivo,
    required this.nombreArchivo,
    this.copiaLocal,
    this.onActualizar,
  });

  final String? rutaArchivo;
  final CopiaDocumentoAcademicoSage? copiaLocal;
  final Future<CopiaDocumentoAcademicoSage?> Function()? onActualizar;
  final String nombreArchivo;

  @override
  State<PantallaVisorPdfSage> createState() => _PantallaVisorPdfSageState();
}

class _PantallaVisorPdfSageState extends State<PantallaVisorPdfSage> {
  static const _maxNativeExtractionBytes = 2 * 1024 * 1024;

  late Future<DocumentoAcademicoPdf?> _documentoNativoFuture;
  PdfControllerPinch? _pdfController;
  bool _mostrarPdfOriginal = false;
  double _topBlurProgress = 0;
  CopiaDocumentoAcademicoSage? _copia;
  bool _actualizando = false;
  String? get _rutaArchivo =>
      _copia?.archivo?.path ?? (_copia == null ? widget.rutaArchivo : null);

  @override
  void initState() {
    super.initState();
    _copia = widget.copiaLocal;
    _documentoNativoFuture = _cargarDocumentoNativo();
  }

  Future<File> _archivoValidado() async {
    final ruta = _rutaArchivo;
    if (ruta == null) {
      throw const FormatException('No hay una copia PDF disponible.');
    }
    final file = File(ruta);
    if (!await file.exists()) {
      throw const FormatException('Archivo no disponible.');
    }
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size <= 0 ||
        !file.path.toLowerCase().endsWith('.pdf') ||
        !await _isControlledPath(file)) {
      throw const FormatException('Documento no válido.');
    }

    final handle = await file.open();
    try {
      final header = await handle.read(5);
      if (header.length != 5 || latin1.decode(header) != '%PDF-') {
        throw const FormatException('El archivo no es un PDF válido.');
      }
    } finally {
      await handle.close();
    }
    return file;
  }

  Future<DocumentoAcademicoPdf?> _cargarDocumentoNativo() async {
    if (_copia?.nativo != null) return _copia!.nativo;
    final file = await _archivoValidado();
    final length = await file.length();
    // ponytail: los reportes SAGE son pequeños; un PDF general grande conserva
    // el visor existente para evitar cargarlo completo en memoria.
    if (length > _maxNativeExtractionBytes) return null;
    try {
      return const ExtractorDocumentoAcademicoPdf().extraer(
        await file.readAsBytes(),
      );
    } on FormatException {
      return null;
    }
  }

  Future<PdfDocument> _abrirDocumentoValidado() async {
    final file = await _archivoValidado();
    return PdfDocument.openFile(file.path);
  }

  PdfControllerPinch _asegurarPdfController() {
    return _pdfController ??= PdfControllerPinch(
      document: _abrirDocumentoValidado(),
    );
  }

  Future<bool> _isControlledPath(File file) async {
    final resolvedFile = await file.resolveSymbolicLinks();
    final allowedDirectories = <Directory>[];
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (external != null) allowedDirectories.addAll(external);
    }
    allowedDirectories.add(await getApplicationDocumentsDirectory());
    final filePath = _normalisePath(resolvedFile);
    for (final directory in allowedDirectories) {
      if (!await directory.exists()) continue;
      final resolvedDirectory = await directory.resolveSymbolicLinks();
      final directoryPath = _normalisePath(resolvedDirectory);
      if (filePath == directoryPath || filePath.startsWith('$directoryPath/')) {
        return true;
      }
    }
    return false;
  }

  String _normalisePath(String value) {
    var result = value.replaceAll(String.fromCharCode(92), '/').toLowerCase();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  Future<void> _share() async {
    final ruta = _rutaArchivo;
    if (ruta == null) return;
    final file = File(ruta);
    if (!await file.exists() || !mounted) return;
    try {
      await SharePlus.instance.share(
        ShareParams(title: widget.nombreArchivo, files: [XFile(file.path)]),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo compartir el PDF.')),
        );
      }
    }
  }

  Future<void> _openExternally() async {
    final ruta = _rutaArchivo;
    if (ruta == null) return;
    final result = await OpenFilex.open(ruta);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un visor de PDF disponible.')),
      );
    }
  }

  Future<void> _actualizar() async {
    final actualizar = widget.onActualizar;
    if (actualizar == null || _actualizando) return;
    setState(() => _actualizando = true);
    try {
      final nueva = await actualizar();
      if (!mounted) return;
      if (nueva == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Actualización cancelada. La copia guardada sigue disponible.',
            ),
          ),
        );
        return;
      }
      _pdfController?.dispose();
      _pdfController = null;
      setState(() {
        _copia = nueva;
        _documentoNativoFuture = _cargarDocumentoNativo();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo actualizar. La copia guardada sigue disponible.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  Future<void> _retryDocument() async {
    await _asegurarPdfController().loadDocument(_abrirDocumentoValidado());
  }

  void _retryPreparation() {
    setState(() {
      _mostrarPdfOriginal = false;
      _documentoNativoFuture = _cargarDocumentoNativo();
    });
  }

  void _showOriginalPdf() {
    setState(() {
      _mostrarPdfOriginal = true;
      _topBlurProgress = 0;
    });
  }

  void _showNativeDocument() {
    setState(() {
      _mostrarPdfOriginal = false;
      _topBlurProgress = 0;
    });
  }

  bool _handleNativeScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final progress = (notification.metrics.pixels / 48.0).clamp(0.0, 1.0);
    if ((progress - _topBlurProgress).abs() <= 0.02) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (progress - _topBlurProgress).abs() <= 0.02) return;
      setState(() => _topBlurProgress = progress);
    });
    return false;
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = temaLaboratorioAtlassian(context);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => FutureBuilder<DocumentoAcademicoPdf?>(
          future: _documentoNativoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PantallaPreparandoDocumento(title: 'SAGE');
            }
            if (snapshot.hasError) {
              return _PantallaErrorDocumento(
                title: 'SAGE',
                onRetry: _retryPreparation,
                onOpenExternally: _openExternally,
              );
            }

            final document = snapshot.data;
            if (document != null && !_mostrarPdfOriginal) {
              return _buildNativeScreen(context, document);
            }
            return _buildOriginalPdfScreen(context, document);
          },
        ),
      ),
    );
  }

  Widget _buildNativeScreen(
    BuildContext context,
    DocumentoAcademicoPdf document,
  ) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final theme = Theme.of(context);
    final reactTheme = TemaReactDeveloper.of(context);
    final topContentPadding = MediaQuery.paddingOf(context).top + 88;

    return Scaffold(
      backgroundColor: reactTheme.canvas,
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleNativeScroll,
            child: VistaDocumentoAcademicoNativo(
              documento: document,
              topPadding: topContentPadding,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _topBlurProgress <= 0.01
                ? const SizedBox.shrink()
                : IgnorePointer(
                    child: Opacity(
                      opacity: _topBlurProgress,
                      child: ClipRect(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black,
                                Colors.black,
                                Colors.black87,
                                Colors.black45,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.35, 0.60, 0.82, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              height: MediaQuery.paddingOf(context).top + 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    reactTheme.canvas.withValues(alpha: 0.98),
                                    reactTheme.canvas.withValues(alpha: 0.80),
                                    reactTheme.canvas.withValues(alpha: 0.40),
                                    reactTheme.canvas.withValues(alpha: 0),
                                  ],
                                  stops: const [0.0, 0.35, 0.70, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(RadioAtlassian.pill),
                  child: Container(
                    key: const Key('document-native-floating-back'),
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
                      Icons.arrow_back_rounded,
                      size: 26,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              reactTheme.canvas.withValues(alpha: 0),
              reactTheme.canvas.withValues(alpha: 0.86),
              reactTheme.canvas,
            ],
            stops: const [0, 0.40, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: DockDocumentoAcademicoNativo(
            onCompartir: () => unawaited(_share()),
            onVerPdfOriginal: _showOriginalPdf,
            onAbrirExternamente: () => unawaited(_openExternally()),
            reduceMotion: reduceMotion,
            onActualizar: widget.onActualizar == null
                ? null
                : () => unawaited(_actualizar()),
            actualizando: _actualizando,
            pdfDisponible: _rutaArchivo != null,
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalPdfScreen(
    BuildContext context,
    DocumentoAcademicoPdf? document,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: construirAppBarSage(
        context,
        title: 'SAGE',
        centerTitle: true,
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Compartir PDF',
            onPressed: () => unawaited(_share()),
            icon: const Icon(Icons.share_rounded),
          ),
          PopupMenuButton<_AccionDocumentoPdf>(
            tooltip: 'Más opciones',
            onSelected: _handleAction,
            itemBuilder: (context) => [
              if (document != null)
                const PopupMenuItem(
                  value: _AccionDocumentoPdf.nativeView,
                  child: _OpcionMenuDocumento(
                    icon: Icons.view_agenda_outlined,
                    label: 'Volver a la vista nativa',
                  ),
                ),
              const PopupMenuItem(
                value: _AccionDocumentoPdf.externalApp,
                child: _OpcionMenuDocumento(
                  icon: Icons.open_in_new_rounded,
                  label: 'Abrir con otra aplicación',
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: widget.onActualizar == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: FilledButton.icon(
                onPressed: _actualizando
                    ? null
                    : () => unawaited(_actualizar()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_actualizando ? 'Actualizando…' : 'Actualizar'),
              ),
            ),
      body: PdfViewPinch(
        controller: _asegurarPdfController(),
        backgroundDecoration: BoxDecoration(color: scheme.surface),
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error) => _PdfErrorView(
            onRetry: _retryDocument,
            onOpenExternally: _openExternally,
          ),
        ),
      ),
    );
  }

  void _handleAction(_AccionDocumentoPdf action) {
    switch (action) {
      case _AccionDocumentoPdf.nativeView:
        _showNativeDocument();
        break;
      case _AccionDocumentoPdf.externalApp:
        unawaited(_openExternally());
        break;
    }
  }
}

enum _AccionDocumentoPdf { nativeView, externalApp }

class _OpcionMenuDocumento extends StatelessWidget {
  const _OpcionMenuDocumento({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}

class _PantallaPreparandoDocumento extends StatelessWidget {
  const _PantallaPreparandoDocumento({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: construirAppBarSage(
        context,
        title: title,
        centerTitle: true,
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando vista del documento…'),
          ],
        ),
      ),
    );
  }
}

class _PantallaErrorDocumento extends StatelessWidget {
  const _PantallaErrorDocumento({
    required this.title,
    required this.onRetry,
    required this.onOpenExternally,
  });

  final String title;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: construirAppBarSage(
        context,
        title: title,
        centerTitle: true,
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: EstadoVacioAtlassian(
        icon: Icons.description_outlined,
        title: 'No se pudo abrir el documento',
        message:
            'El archivo no está disponible o no pertenece a una ubicación segura de la aplicación.',
        action: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            OutlinedButton(
              onPressed: onOpenExternally,
              child: const Text('Abrir con otra aplicación'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfErrorView extends StatelessWidget {
  const _PdfErrorView({required this.onRetry, required this.onOpenExternally});

  final VoidCallback onRetry;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return EstadoVacioAtlassian(
      icon: Icons.picture_as_pdf_outlined,
      title: 'No se pudo mostrar el PDF',
      message: 'El archivo original continúa guardado en el dispositivo.',
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          OutlinedButton(
            onPressed: onOpenExternally,
            child: const Text('Abrir con otra aplicación'),
          ),
        ],
      ),
    );
  }
}
