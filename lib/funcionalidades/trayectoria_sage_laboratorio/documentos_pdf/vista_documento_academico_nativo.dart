import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../laboratorio_atlassian/tema/tema_atlassian.dart';
import '../../laboratorio_atlassian/tema/tema_react_developer.dart';
import 'modelos_documento_academico_pdf.dart';

enum _FiltroEstadoDocumento { todas, aprobadas, cursando, pendientes, otros }

enum _OrdenAnaliticoDocumento { anio, fecha, nota }

// Un solo reloj gobierna selección, etiquetas y recambio del contenido.
const _duracionFiltroDocumento = Duration(milliseconds: 320);
const _momentoRecambioFiltro = 0.35;
typedef _FiltroDocumento = ({
  int? anio,
  _FiltroEstadoDocumento estado,
  _OrdenAnaliticoDocumento orden,
});
const _filtroInicialDocumento = (
  anio: null,
  estado: _FiltroEstadoDocumento.todas,
  orden: _OrdenAnaliticoDocumento.anio,
);

class VistaDocumentoAcademicoNativo extends StatefulWidget {
  const VistaDocumentoAcademicoNativo({
    super.key,
    required this.documento,
    this.topPadding = 18,
  });

  final DocumentoAcademicoPdf documento;
  final double topPadding;

  @override
  State<VistaDocumentoAcademicoNativo> createState() =>
      _VistaDocumentoAcademicoNativoState();
}

class _VistaDocumentoAcademicoNativoState
    extends State<VistaDocumentoAcademicoNativo>
    with SingleTickerProviderStateMixin {
  _FiltroDocumento _filtroVisible = _filtroInicialDocumento;
  _FiltroDocumento _filtroOrigen = _filtroInicialDocumento;
  _FiltroDocumento _filtroDestino = _filtroInicialDocumento;
  _FiltroDocumento _filtroSolicitado = _filtroInicialDocumento;
  bool _contenidoCambiado = true;
  late final AnimationController _movimientoFiltro =
      AnimationController(vsync: this, duration: _duracionFiltroDocumento)
        ..addListener(_avanzarFiltro)
        ..addStatusListener(_terminarFiltro);

  @override
  void initState() {
    super.initState();
    _movimientoFiltro.value = 1;
  }

  void _cambiarFiltro(_FiltroDocumento filtro) {
    if (filtro == _filtroSolicitado) return;
    _filtroSolicitado = filtro;
    if (MediaQuery.disableAnimationsOf(context)) {
      _movimientoFiltro.stop();
      setState(() {
        _filtroOrigen = filtro;
        _filtroDestino = filtro;
        _filtroVisible = filtro;
        _contenidoCambiado = true;
      });
      _movimientoFiltro.value = 1;
    } else if (!_movimientoFiltro.isAnimating) {
      _iniciarFiltro(filtro);
    }
  }

  void _iniciarFiltro(_FiltroDocumento filtro) {
    setState(() {
      _filtroOrigen = _filtroVisible;
      _filtroDestino = filtro;
      _contenidoCambiado = false;
    });
    _movimientoFiltro.forward(from: 0);
  }

  void _avanzarFiltro() {
    if (_contenidoCambiado ||
        _movimientoFiltro.value < _momentoRecambioFiltro) {
      return;
    }
    // Reemplazamos un único listado mientras su opacidad llega a cero.
    setState(() {
      _filtroVisible = _filtroDestino;
      _contenidoCambiado = true;
    });
  }

  void _terminarFiltro(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _filtroSolicitado != _filtroVisible) {
      // Los toques rápidos conservan el último pedido sin reiniciar un fade.
      _iniciarFiltro(_filtroSolicitado);
    }
  }

  @override
  void didUpdateWidget(covariant VistaDocumentoAcademicoNativo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documento != widget.documento) {
      _movimientoFiltro.stop();
      _filtroOrigen = _filtroInicialDocumento;
      _filtroDestino = _filtroInicialDocumento;
      _filtroVisible = _filtroInicialDocumento;
      _filtroSolicitado = _filtroInicialDocumento;
      _contenidoCambiado = true;
      _movimientoFiltro.value = 1;
    }
  }

  @override
  void dispose() {
    _movimientoFiltro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final materias = _materiasVisibles();
    final contentKey = <Object?>[
      widget.documento.tipo,
      _filtroVisible.anio,
      _filtroVisible.estado,
      _filtroVisible.orden,
      materias.length,
    ].join('-');

    return LayoutBuilder(
      builder: (context, viewport) => ListView(
        key: ValueKey<String>('native-document-${widget.documento.tipo.name}'),
        padding: EdgeInsets.fromLTRB(20, widget.topPadding, 20, 132),
        children: [
          _CabeceraReactDocumento(
            documento: widget.documento,
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 26),
          _ResumenReactDocumento(
            documento: widget.documento,
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 26),
          _ControlesReactDocumento(
            documento: widget.documento,
            anioSeleccionado: _filtroDestino.anio,
            anioAnterior: _filtroOrigen.anio,
            filtroEstado: _filtroDestino.estado,
            estadoAnterior: _filtroOrigen.estado,
            ordenAnalitico: _filtroDestino.orden,
            ordenAnterior: _filtroOrigen.orden,
            movimiento: _movimientoFiltro,
            onAnioChanged: (value) => _cambiarFiltro((
              anio: value,
              estado: _filtroSolicitado.estado,
              orden: _filtroSolicitado.orden,
            )),
            onEstadoChanged: (value) => _cambiarFiltro((
              anio: _filtroSolicitado.anio,
              estado: value,
              orden: _filtroSolicitado.orden,
            )),
            onOrdenChanged: (value) => _cambiarFiltro((
              anio: _filtroSolicitado.anio,
              estado: _filtroSolicitado.estado,
              orden: value,
            )),
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            // Al acortar el listado, el viewport conserva la posición del filtro.
            constraints: BoxConstraints(
              minHeight: math.max(0, viewport.maxHeight - 132),
            ),
            child: AnimatedBuilder(
              animation: _movimientoFiltro,
              builder: (context, child) {
                final time = _movimientoFiltro.value;
                final opacity = reduceMotion
                    ? 1.0
                    : time < _momentoRecambioFiltro
                    ? 1 -
                          Curves.easeInCubic.transform(
                            time / _momentoRecambioFiltro,
                          )
                    : Curves.easeOutCubic.transform(
                        (time - _momentoRecambioFiltro) /
                            (1 - _momentoRecambioFiltro),
                      );
                return IgnorePointer(
                  ignoring: _movimientoFiltro.isAnimating,
                  child: Opacity(
                    key: const Key('document-filter-content-opacity'),
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - opacity)),
                      child: child,
                    ),
                  ),
                );
              },
              child: RepaintBoundary(
                key: ValueKey<String>('document-content-$contentKey'),
                child: _ContenidoFiltroSinEntradasEscalonadas(
                  child: _ContenidoReactDocumento(
                    documento: widget.documento,
                    materias: materias,
                    ordenAnalitico: _filtroVisible.orden,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
            ),
          ),
          if (widget.documento.tipo ==
                  TipoDocumentoAcademicoPdf.situacionAcademica &&
              widget.documento.sinEstado > 0) ...[
            const SizedBox(height: 22),
            _NotaPendientesReact(cantidad: widget.documento.sinEstado),
          ],
        ],
      ),
    );
  }

  List<MateriaDocumentoAcademicoPdf> _materiasVisibles() {
    final result = widget.documento.materias
        .where((materia) {
          if (_filtroVisible.anio != null &&
              materia.anio != _filtroVisible.anio) {
            return false;
          }
          return _coincideFiltro(materia);
        })
        .toList(growable: true);

    if (widget.documento.tipo == TipoDocumentoAcademicoPdf.analitico) {
      switch (_filtroVisible.orden) {
        case _OrdenAnaliticoDocumento.anio:
          result.sort((a, b) {
            final byYear = a.anio.compareTo(b.anio);
            if (byYear != 0) return byYear;
            return a.nombre.compareTo(b.nombre);
          });
          break;
        case _OrdenAnaliticoDocumento.fecha:
          result.sort((a, b) {
            final first = a.fechaMovimientoDateTime;
            final second = b.fechaMovimientoDateTime;
            if (first == null && second == null) {
              return a.nombre.compareTo(b.nombre);
            }
            if (first == null) return 1;
            if (second == null) return -1;
            final byDate = second.compareTo(first);
            return byDate != 0 ? byDate : a.nombre.compareTo(b.nombre);
          });
          break;
        case _OrdenAnaliticoDocumento.nota:
          result.sort((a, b) {
            final first = a.notaNumerica;
            final second = b.notaNumerica;
            if (first == null && second == null) {
              return a.nombre.compareTo(b.nombre);
            }
            if (first == null) return 1;
            if (second == null) return -1;
            final byGrade = second.compareTo(first);
            return byGrade != 0 ? byGrade : a.nombre.compareTo(b.nombre);
          });
          break;
      }
    }
    return List<MateriaDocumentoAcademicoPdf>.unmodifiable(result);
  }

  bool _coincideFiltro(MateriaDocumentoAcademicoPdf materia) {
    return switch (_filtroVisible.estado) {
      _FiltroEstadoDocumento.todas => true,
      _FiltroEstadoDocumento.aprobadas =>
        materia.categoriaEstado == CategoriaEstadoDocumentoPdf.aprobada,
      _FiltroEstadoDocumento.cursando =>
        materia.categoriaEstado == CategoriaEstadoDocumentoPdf.cursando,
      _FiltroEstadoDocumento.pendientes =>
        materia.categoriaEstado == CategoriaEstadoDocumentoPdf.sinEstado,
      _FiltroEstadoDocumento.otros =>
        materia.categoriaEstado == CategoriaEstadoDocumentoPdf.regular ||
            materia.categoriaEstado == CategoriaEstadoDocumentoPdf.otra,
    };
  }
}

class _CabeceraReactDocumento extends StatelessWidget {
  const _CabeceraReactDocumento({
    required this.documento,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _tituloEditorial(documento.tipo);
    final alumno = _textoValido(documento.alumno);
    final career = _textoValido(documento.carrera);
    final institution = _textoValido(documento.establecimiento);
    final issueDate = _textoValido(documento.fechaEmision);
    final documentNumber = _textoValido(documento.documento);

    return Semantics(
      container: true,
      label: '${documento.tipo.titulo}. ${alumno ?? 'Documento académico'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SplitTitleLine(
            text: title.$1,
            reduceMotion: reduceMotion,
            gradient: false,
          ),
          _SplitTitleLine(
            text: title.$2,
            reduceMotion: reduceMotion,
            gradient: true,
            startIndex: title.$1.split(' ').length,
          ),
          if (alumno != null) ...[
            const SizedBox(height: 18),
            _EntradaReactDocumento(
              index: 3,
              reduceMotion: reduceMotion,
              child: Text(
                _nombrePersonaVisible(alumno),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (career != null) ...[
            const SizedBox(height: 4),
            _EntradaReactDocumento(
              index: 4,
              reduceMotion: reduceMotion,
              child: Text(
                _descripcionCarreraVisible(career),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.32,
                ),
              ),
            ),
          ],
          if (institution != null ||
              issueDate != null ||
              documentNumber != null) ...[
            const SizedBox(height: 14),
            _EntradaReactDocumento(
              index: 5,
              reduceMotion: reduceMotion,
              child: Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  if (institution != null)
                    _MetaSuaveDocumento(
                      icon: Icons.account_balance_outlined,
                      text: _fraseSuave(institution),
                    ),
                  if (issueDate != null)
                    _MetaSuaveDocumento(
                      icon: Icons.event_available_outlined,
                      text: 'emitido $issueDate',
                    ),
                  if (documentNumber != null)
                    _MetaSuaveDocumento(
                      icon: Icons.badge_outlined,
                      text: 'doc. $documentNumber',
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitTitleLine extends StatelessWidget {
  const _SplitTitleLine({
    required this.text,
    required this.reduceMotion,
    required this.gradient,
    this.startIndex = 0,
  });

  final String text;
  final bool reduceMotion;
  final bool gradient;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
      fontSize: 39,
      height: 0.98,
      letterSpacing: -1.7,
      fontWeight: FontWeight.w800,
    );

    return Wrap(
      spacing: 9,
      runSpacing: 0,
      children: [
        for (var index = 0; index < words.length; index++)
          _EntradaPalabraTitulo(
            index: startIndex + index,
            reduceMotion: reduceMotion,
            child: gradient
                ? _PalabraGradiente(text: words[index], style: style)
                : Text(words[index], style: style),
          ),
      ],
    );
  }
}

class _EntradaPalabraTitulo extends StatelessWidget {
  const _EntradaPalabraTitulo({
    required this.index,
    required this.reduceMotion,
    required this.child,
  });

  final int index;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 390 + index.clamp(0, 5).toInt() * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _PalabraGradiente extends StatelessWidget {
  const _PalabraGradiente({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: scheme.brightness == Brightness.dark
            ? const [Color(0xFF9CC7FF), Color(0xFFCBB8FF), Color(0xFFADC4FF)]
            : [scheme.primary, scheme.tertiary, const Color(0xFF8C9EFF)],
      ).createShader(bounds),
      child: Text(text, style: style?.copyWith(color: Colors.white)),
    );
  }
}

class _MetaSuaveDocumento extends StatelessWidget {
  const _MetaSuaveDocumento({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ResumenReactDocumento extends StatelessWidget {
  const _ResumenReactDocumento({
    required this.documento,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return switch (documento.tipo) {
      TipoDocumentoAcademicoPdf.libreta => _BentoLibreta(
        documento: documento,
        reduceMotion: reduceMotion,
      ),
      TipoDocumentoAcademicoPdf.analitico => _BentoAnalitico(
        documento: documento,
        reduceMotion: reduceMotion,
      ),
      TipoDocumentoAcademicoPdf.situacionAcademica => _BentoSituacion(
        documento: documento,
        reduceMotion: reduceMotion,
      ),
    };
  }
}

class _BentoLibreta extends StatelessWidget {
  const _BentoLibreta({required this.documento, required this.reduceMotion});

  final DocumentoAcademicoPdf documento;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lastDate =
        _formatearFechaCorta(documento.ultimaFechaMovimiento) ?? 'sin fecha';
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 430;
        final main = _BentoHeroMetric(
          value: documento.aprobadas.toDouble(),
          decimals: 0,
          label: 'materias aprobadas',
          icon: Icons.auto_awesome_rounded,
          accent: scheme.primary,
          reduceMotion: reduceMotion,
        );
        final years = _BentoSmallMetric(
          value: '${documento.anios.length}',
          label: 'años con calificaciones',
          icon: Icons.layers_rounded,
          accent: scheme.tertiary,
        );
        final last = _BentoSmallMetric(
          value: lastDate,
          label: 'último movimiento',
          icon: Icons.history_rounded,
          accent: PaletaAtlassian.success,
        );
        if (stacked) {
          return Column(
            children: [
              main,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: years),
                  const SizedBox(width: 10),
                  Expanded(child: last),
                ],
              ),
            ],
          );
        }
        return SizedBox(
          height: 182,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: main),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(child: years),
                    const SizedBox(height: 10),
                    Expanded(child: last),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoAnalitico extends StatelessWidget {
  const _BentoAnalitico({required this.documento, required this.reduceMotion});

  final DocumentoAcademicoPdf documento;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final average = documento.promedioOficialNumerico;
    final condition =
        _textoValido(documento.condicionAlumno)?.toLowerCase() ??
        'sin informar';
    final firstDate =
        _formatearFechaCorta(documento.primeraFechaMovimiento) ?? 'sin fecha';
    return LayoutBuilder(
      builder: (context, constraints) {
        final main = _BentoHeroMetric(
          value: average ?? 0.0,
          decimals: average == null ? 0 : 2,
          label: average == null ? 'promedio sin informar' : 'promedio oficial',
          icon: Icons.stars_rounded,
          accent: scheme.tertiary,
          reduceMotion: reduceMotion,
          fallbackValue: average == null ? '—' : null,
        );
        final approved = _BentoSmallMetric(
          value: '${documento.aprobadas}',
          label: 'aprobadas',
          icon: Icons.check_rounded,
          accent: PaletaAtlassian.success,
        );
        final state = _BentoSmallMetric(
          value: condition,
          label: 'condición académica',
          icon: Icons.verified_user_outlined,
          accent: scheme.primary,
        );
        final first = _BentoSmallMetric(
          value: firstDate,
          label: 'primer registro',
          icon: Icons.event_available_outlined,
          accent: scheme.onSurfaceVariant,
        );
        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              main,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: approved),
                  const SizedBox(width: 10),
                  Expanded(child: state),
                ],
              ),
              const SizedBox(height: 10),
              first,
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 178,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: main),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(child: approved),
                        const SizedBox(height: 10),
                        Expanded(child: state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            first,
          ],
        );
      },
    );
  }
}

class _BentoSituacion extends StatelessWidget {
  const _BentoSituacion({required this.documento, required this.reduceMotion});

  final DocumentoAcademicoPdf documento;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    final total = documento.totalMaterias == 0 ? 1 : documento.totalMaterias;
    final approvedFlex = documento.aprobadas;
    final studyingFlex = documento.cursando;
    final pendingFlex =
        documento.sinEstado + documento.regulares + documento.otrosEstados;
    final condition = _textoValido(documento.condicionAlumno)?.toLowerCase();

    return _EntradaReactDocumento(
      index: 1,
      reduceMotion: reduceMotion,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: reactTheme.cardGradient([
              scheme.primary.withValues(alpha: 0.22),
              scheme.tertiary.withValues(alpha: 0.11),
              scheme.surface.withValues(alpha: 0.92),
            ]),
          ),
          border: Border.all(
            color: scheme.primary.withValues(
              alpha: reactTheme.isDark ? 0.24 : 0.52,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(
                alpha: reactTheme.isDark ? 0.08 : 0.10,
              ),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NumeroAnimado(
                  value: documento.totalMaterias.toDouble(),
                  decimals: 0,
                  reduceMotion: reduceMotion,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 48,
                    height: 0.92,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'materias en tu trayectoria',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (condition != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: reactTheme.isDark
                          ? scheme.surface.withValues(alpha: 0.68)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Text(
                      condition,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 11,
                child: Row(
                  children: [
                    if (approvedFlex > 0)
                      Expanded(
                        flex: approvedFlex,
                        child: Container(color: PaletaAtlassian.success),
                      ),
                    if (studyingFlex > 0)
                      Expanded(
                        flex: studyingFlex,
                        child: Container(color: scheme.primary),
                      ),
                    if (pendingFlex > 0)
                      Expanded(
                        flex: pendingFlex,
                        child: Container(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.32,
                          ),
                        ),
                      ),
                    if (approvedFlex + studyingFlex + pendingFlex == 0)
                      Expanded(
                        flex: total,
                        child: Container(color: scheme.outlineVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DatoTrayectoria(
                    value: documento.aprobadas,
                    label: 'aprobadas',
                    color: reactTheme.isDark
                        ? const Color(0xFF66D5A1)
                        : PaletaAtlassian.success,
                    reduceMotion: reduceMotion,
                  ),
                ),
                Expanded(
                  child: _DatoTrayectoria(
                    value: documento.cursando,
                    label: 'cursando',
                    color: reactTheme.isDark
                        ? const Color(0xFF9CC7FF)
                        : scheme.primary,
                    reduceMotion: reduceMotion,
                  ),
                ),
                Expanded(
                  child: _DatoTrayectoria(
                    value: documento.sinEstado,
                    label: 'pendientes',
                    color: scheme.onSurfaceVariant,
                    reduceMotion: reduceMotion,
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

class _BentoHeroMetric extends StatelessWidget {
  const _BentoHeroMetric({
    required this.value,
    required this.decimals,
    required this.label,
    required this.icon,
    required this.accent,
    required this.reduceMotion,
    this.fallbackValue,
  });

  final double value;
  final int decimals;
  final String label;
  final IconData icon;
  final Color accent;
  final bool reduceMotion;
  final String? fallbackValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    return _EntradaReactDocumento(
      index: 1,
      reduceMotion: reduceMotion,
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: reactTheme.cardGradient([
              accent.withValues(alpha: 0.28),
              accent.withValues(alpha: 0.09),
              scheme.surface.withValues(alpha: 0.96),
            ]),
          ),
          border: Border.all(
            color: accent.withValues(alpha: reactTheme.isDark ? 0.26 : 0.56),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.48),
                        blurRadius: 9,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (fallbackValue != null)
              Text(
                fallbackValue!,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 48,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              )
            else
              _NumeroAnimado(
                value: value,
                decimals: decimals,
                reduceMotion: reduceMotion,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 48,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoSmallMetric extends StatelessWidget {
  const _BentoSmallMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: reactTheme.cardGradient([
            accent.withValues(alpha: 0.14),
            scheme.surface.withValues(alpha: 0.94),
          ]),
        ),
        border: Border.all(
          color: accent.withValues(alpha: reactTheme.isDark ? 0.18 : 0.48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: reactTheme.isDark
                  ? accent.withValues(alpha: 0.13)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(
                  alpha: reactTheme.isDark ? 0.20 : 0.52,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _DatoTrayectoria extends StatelessWidget {
  const _DatoTrayectoria({
    required this.value,
    required this.label,
    required this.color,
    required this.reduceMotion,
  });

  final int value;
  final String label;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumeroAnimado(
          value: value.toDouble(),
          decimals: 0,
          reduceMotion: reduceMotion,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NumeroAnimado extends StatelessWidget {
  const _NumeroAnimado({
    required this.value,
    required this.decimals,
    required this.reduceMotion,
    required this.style,
  });

  final double value;
  final int decimals;
  final bool reduceMotion;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? value : 0, end: value),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          Text(current.toStringAsFixed(decimals), style: style),
    );
  }
}

class _ControlesReactDocumento extends StatelessWidget {
  const _ControlesReactDocumento({
    required this.documento,
    required this.anioSeleccionado,
    required this.anioAnterior,
    required this.filtroEstado,
    required this.estadoAnterior,
    required this.ordenAnalitico,
    required this.ordenAnterior,
    required this.movimiento,
    required this.onAnioChanged,
    required this.onEstadoChanged,
    required this.onOrdenChanged,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final int? anioSeleccionado;
  final int? anioAnterior;
  final _FiltroEstadoDocumento filtroEstado;
  final _FiltroEstadoDocumento estadoAnterior;
  final _OrdenAnaliticoDocumento ordenAnalitico;
  final _OrdenAnaliticoDocumento ordenAnterior;
  final Animation<double> movimiento;
  final ValueChanged<int?> onAnioChanged;
  final ValueChanged<_FiltroEstadoDocumento> onEstadoChanged;
  final ValueChanged<_OrdenAnaliticoDocumento> onOrdenChanged;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final showYear =
        documento.tipo != TipoDocumentoAcademicoPdf.analitico &&
        documento.anios.length > 1;
    final showStatus =
        documento.tipo == TipoDocumentoAcademicoPdf.situacionAcademica;
    final showSort = documento.tipo == TipoDocumentoAcademicoPdf.analitico;
    if (!showYear && !showStatus && !showSort) return const SizedBox.shrink();

    return Column(
      children: [
        if (showYear)
          _GooeySelector<int?>(
            key: const Key('document-gooey-year-selector'),
            value: anioSeleccionado,
            previousValue: anioAnterior,
            animation: movimiento,
            reduceMotion: reduceMotion,
            options: [
              _OpcionGooey<int?>(
                key: const Key('document-filter-year-all'),
                value: null,
                label: 'todos',
              ),
              for (final year in documento.anios)
                _OpcionGooey<int?>(
                  key: Key('document-filter-year-$year'),
                  value: year,
                  label: '$yearº',
                ),
            ],
            onChanged: onAnioChanged,
          ),
        if (showStatus) ...[
          if (showYear) const SizedBox(height: 10),
          _GooeySelector<_FiltroEstadoDocumento>(
            key: const Key('document-gooey-status-selector'),
            value: filtroEstado,
            previousValue: estadoAnterior,
            animation: movimiento,
            reduceMotion: reduceMotion,
            options: [
              const _OpcionGooey(
                key: Key('document-filter-status-all'),
                value: _FiltroEstadoDocumento.todas,
                label: 'todas',
              ),
              if (documento.aprobadas > 0)
                const _OpcionGooey(
                  key: Key('document-filter-status-approved'),
                  value: _FiltroEstadoDocumento.aprobadas,
                  label: 'aprobadas',
                ),
              if (documento.cursando > 0)
                const _OpcionGooey(
                  key: Key('document-filter-status-studying'),
                  value: _FiltroEstadoDocumento.cursando,
                  label: 'cursando',
                ),
              if (documento.sinEstado > 0)
                const _OpcionGooey(
                  key: Key('document-filter-status-pending'),
                  value: _FiltroEstadoDocumento.pendientes,
                  label: 'pendientes',
                ),
              if (documento.regulares + documento.otrosEstados > 0)
                const _OpcionGooey(
                  key: Key('document-filter-status-other'),
                  value: _FiltroEstadoDocumento.otros,
                  label: 'otros',
                ),
            ],
            onChanged: onEstadoChanged,
          ),
        ],
        if (showSort)
          _GooeySelector<_OrdenAnaliticoDocumento>(
            key: const Key('document-gooey-sort-selector'),
            value: ordenAnalitico,
            previousValue: ordenAnterior,
            animation: movimiento,
            reduceMotion: reduceMotion,
            options: const [
              _OpcionGooey(
                key: Key('document-sort-year'),
                value: _OrdenAnaliticoDocumento.anio,
                label: 'año',
              ),
              _OpcionGooey(
                key: Key('document-sort-date'),
                value: _OrdenAnaliticoDocumento.fecha,
                label: 'fecha',
              ),
              _OpcionGooey(
                key: Key('document-sort-grade'),
                value: _OrdenAnaliticoDocumento.nota,
                label: 'nota',
              ),
            ],
            onChanged: onOrdenChanged,
          ),
      ],
    );
  }
}

class _OpcionGooey<T> {
  const _OpcionGooey({
    required this.key,
    required this.value,
    required this.label,
  });

  final Key key;
  final T value;
  final String label;
}

class _GooeySelector<T> extends StatelessWidget {
  const _GooeySelector({
    super.key,
    required this.options,
    required this.value,
    required this.previousValue,
    required this.animation,
    required this.onChanged,
    required this.reduceMotion,
  });

  final List<_OpcionGooey<T>> options;
  final T value;
  final T previousValue;
  final Animation<double> animation;
  final ValueChanged<T> onChanged;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    final selectedIndex = math.max(
      0,
      options.indexWhere((option) => option.value == value),
    );
    final previousIndex = math.max(
      0,
      options.indexWhere((option) => option.value == previousValue),
    );
    return Semantics(
      container: true,
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: reactTheme.isDark
              ? scheme.surfaceContainerLow.withValues(alpha: 0.78)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: reactTheme.border),
        ),
        child: LayoutBuilder(
          builder: (context, track) => AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final time = reduceMotion ? 1.0 : animation.value;
              final progress = Curves.easeInOutCubic.transform(time);
              final position = ui.lerpDouble(
                previousIndex.toDouble(),
                selectedIndex.toDouble(),
                progress,
              )!;
              final cellWidth = track.maxWidth / options.length;
              final stretch = previousIndex == selectedIndex || reduceMotion
                  ? 1.0
                  : 1 + 0.08 * math.sin(math.pi * time);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: position * cellWidth,
                    top: 0,
                    bottom: 0,
                    width: cellWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(scaleX: stretch, child: child),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < options.length; index++)
                        Expanded(
                          child: Semantics(
                            selected: index == selectedIndex,
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: options[index].key,
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => onChanged(options[index].value),
                                child: Center(
                                  child: Text(
                                    options[index].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: Color.lerp(
                                            index == previousIndex
                                                ? Colors.white
                                                : reactTheme.foreground(0.72),
                                            index == selectedIndex
                                                ? Colors.white
                                                : reactTheme.foreground(0.72),
                                            progress,
                                          ),
                                          fontWeight: FontWeight.lerp(
                                            index == previousIndex
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            index == selectedIndex
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            progress,
                                          ),
                                          fontSize: options.length >= 5
                                              ? 11.5
                                              : 12.5,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
            child: DecoratedBox(
              key: const Key('document-selector-indicator'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C66E4), Color(0xFF7C66E8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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

class _ContenidoReactDocumento extends StatelessWidget {
  const _ContenidoReactDocumento({
    required this.documento,
    required this.materias,
    required this.ordenAnalitico,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final _OrdenAnaliticoDocumento ordenAnalitico;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (materias.isEmpty) {
      return const _EstadoVacioDocumento();
    }

    return switch (documento.tipo) {
      TipoDocumentoAcademicoPdf.libreta => _SeccionesChromaPorAnio(
        documento: documento,
        materias: materias,
        reduceMotion: reduceMotion,
      ),
      TipoDocumentoAcademicoPdf.analitico =>
        ordenAnalitico == _OrdenAnaliticoDocumento.anio
            ? _CarruselAnaliticoPorAnio(
                documento: documento,
                materias: materias,
                reduceMotion: reduceMotion,
              )
            : _MasonryMateriasDocumento(
                documento: documento,
                materias: materias,
                reduceMotion: reduceMotion,
                mostrarAnio: true,
              ),
      TipoDocumentoAcademicoPdf.situacionAcademica => _ScrollStackSituacion(
        documento: documento,
        materias: materias,
        reduceMotion: reduceMotion,
      ),
    };
  }
}

class _EstadoVacioDocumento extends StatelessWidget {
  const _EstadoVacioDocumento();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          Icon(
            Icons.blur_on_rounded,
            size: 42,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'sin materias para este filtro',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SeccionesChromaPorAnio extends StatelessWidget {
  const _SeccionesChromaPorAnio({
    required this.documento,
    required this.materias,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final groups = <int, List<MateriaDocumentoAcademicoPdf>>{};
    for (final materia in materias) {
      groups.putIfAbsent(materia.anio, () => <MateriaDocumentoAcademicoPdf>[])
        ..add(materia);
    }
    final years = groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < years.length; index++) ...[
          _CabeceraAnioAbierta(
            anio: years[index],
            cantidad: groups[years[index]]!.length,
            index: index,
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 12),
          _MasonryMateriasDocumento(
            documento: documento,
            materias: groups[years[index]]!,
            reduceMotion: reduceMotion,
          ),
          if (index != years.length - 1) const SizedBox(height: 30),
        ],
      ],
    );
  }
}

class _CabeceraAnioAbierta extends StatelessWidget {
  const _CabeceraAnioAbierta({
    required this.anio,
    required this.cantidad,
    required this.index,
    required this.reduceMotion,
  });

  final int anio;
  final int cantidad;
  final int index;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _EntradaReactDocumento(
      index: index,
      reduceMotion: reduceMotion,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$anioº',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(width: 9),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$cantidad materia${cantidad == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const Spacer(),
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasonryMateriasDocumento extends StatelessWidget {
  const _MasonryMateriasDocumento({
    super.key,
    required this.documento,
    required this.materias,
    required this.reduceMotion,
    this.mostrarAnio = false,
  });

  final DocumentoAcademicoPdf documento;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final bool reduceMotion;
  final bool mostrarAnio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        final buckets = List<List<int>>.generate(columns, (_) => <int>[]);
        final weights = List<int>.filled(columns, 0);
        for (var index = 0; index < materias.length; index++) {
          var target = 0;
          for (var column = 1; column < columns; column++) {
            if (weights[column] < weights[target]) target = column;
          }
          buckets[target].add(index);
          final nameWeight = (materias[index].nombre.length / 28)
              .ceil()
              .clamp(1, 4)
              .toInt();
          weights[target] += 5 + nameWeight;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    for (
                      var item = 0;
                      item < buckets[column].length;
                      item++
                    ) ...[
                      _EntradaReactDocumento(
                        index: buckets[column][item],
                        reduceMotion: reduceMotion,
                        child: _TarjetaChromaMateria(
                          key: ValueKey<String>(
                            'document-subject-${materias[buckets[column][item]].anio}-${materias[buckets[column][item]].nombre}',
                          ),
                          documento: documento,
                          materia: materias[buckets[column][item]],
                          mostrarAnio: mostrarAnio,
                        ),
                      ),
                      if (item != buckets[column].length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaChromaMateria extends StatelessWidget {
  const _TarjetaChromaMateria({
    super.key,
    required this.documento,
    required this.materia,
    required this.mostrarAnio,
  });

  final DocumentoAcademicoPdf documento;
  final MateriaDocumentoAcademicoPdf materia;
  final bool mostrarAnio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _acentoMateria(context, materia);
    final reactTheme = context.reactTheme;
    final note = _textoValido(materia.nota);
    final date = _textoValido(materia.fechaMovimiento);
    final showStatus =
        documento.tipo == TipoDocumentoAcademicoPdf.situacionAcademica;
    final state = _estadoVisible(documento.tipo, materia).toLowerCase();
    final visibleName = _nombreMateriaVisible(materia.nombre);
    final semanticParts = <String>[
      materia.nombre,
      '$state, ${materia.anio}.º año',
      if (date != null) 'fecha $date',
      if (note != null) 'nota $note',
    ];

    return Semantics(
      container: true,
      label: semanticParts.join('. '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: reactTheme.cardGradient([
                accent.withValues(alpha: 0.17),
                scheme.surface.withValues(alpha: 0.96),
              ]),
            ),
            border: Border.all(
              color: accent.withValues(alpha: reactTheme.isDark ? 0.28 : 0.46),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _normalizarNotaVisible(note),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: accent,
                            fontSize: 31,
                            height: 0.96,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.1,
                          ),
                    ),
                    if (mostrarAnio) ...[
                      const Spacer(),
                      Text(
                        '${materia.anio}º',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.36),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${materia.anio}º',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              const SizedBox(height: 13),
              Text(
                visibleName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (showStatus)
                    Text(
                      state,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (showStatus && date != null)
                    Text('·', style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (date != null)
                    Text(
                      _fechaSuave(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarruselAnaliticoPorAnio extends StatefulWidget {
  const _CarruselAnaliticoPorAnio({
    required this.documento,
    required this.materias,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final bool reduceMotion;

  @override
  State<_CarruselAnaliticoPorAnio> createState() =>
      _CarruselAnaliticoPorAnioState();
}

class _CarruselAnaliticoPorAnioState extends State<_CarruselAnaliticoPorAnio> {
  late final PageController _controller;
  int _activeIndex = 0;

  List<int> get _years {
    final result = widget.materias.map((item) => item.anio).toSet().toList()
      ..sort();
    return result;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.82);
  }

  @override
  void didUpdateWidget(covariant _CarruselAnaliticoPorAnio oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldYears =
        oldWidget.materias.map((item) => item.anio).toSet().toList()..sort();
    final newYears = _years;
    if (oldYears.join(',') != newYears.join(',') &&
        _activeIndex >= newYears.length) {
      _activeIndex = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;
    if (years.isEmpty) return const _EstadoVacioDocumento();
    final activeIndex = _activeIndex.clamp(0, years.length - 1).toInt();
    final activeYear = years[activeIndex];
    final activeSubjects = widget.materias
        .where((item) => item.anio == activeYear)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 164,
          child: PageView.builder(
            key: const Key('document-analytic-year-carousel'),
            controller: _controller,
            itemCount: years.length,
            onPageChanged: (value) => setState(() => _activeIndex = value),
            itemBuilder: (context, index) {
              final subjects = widget.materias
                  .where((item) => item.anio == years[index])
                  .toList();
              return AnimatedBuilder(
                animation: _controller,
                child: _TarjetaAnioCarrusel(
                  anio: years[index],
                  materias: subjects,
                  active: index == activeIndex,
                ),
                builder: (context, child) {
                  if (widget.reduceMotion || !_controller.hasClients)
                    return child!;
                  final page = _controller.page ?? _activeIndex.toDouble();
                  final distance = (page - index)
                      .abs()
                      .clamp(0.0, 1.0)
                      .toDouble();
                  final scale = 1 - distance * 0.075;
                  return Transform.translate(
                    offset: Offset(0, distance * 8),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          child: _MasonryMateriasDocumento(
            key: ValueKey<int>(activeYear),
            documento: widget.documento,
            materias: activeSubjects,
            reduceMotion: widget.reduceMotion,
          ),
        ),
      ],
    );
  }
}

class _TarjetaAnioCarrusel extends StatelessWidget {
  const _TarjetaAnioCarrusel({
    required this.anio,
    required this.materias,
    required this.active,
  });

  final int anio;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    final notes = materias
        .map((item) => item.notaNumerica)
        .whereType<double>()
        .toList();
    final best = notes.isEmpty ? null : notes.reduce((a, b) => a > b ? a : b);
    DateTime? last;
    for (final subject in materias) {
      final date = subject.fechaMovimientoDateTime;
      if (date != null && (last == null || date.isAfter(last))) last = date;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: reactTheme.cardGradient([
              scheme.primary.withValues(alpha: active ? 0.28 : 0.14),
              scheme.tertiary.withValues(alpha: active ? 0.16 : 0.07),
              scheme.surface,
            ]),
          ),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(
                    alpha: reactTheme.isDark ? 0.42 : 0.56,
                  )
                : reactTheme.border,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$anioº año',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.swipe_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _DatoCarrusel(
                    label: 'materias',
                    value: '${materias.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatoCarrusel(
                    label: 'mejor nota',
                    value: best == null
                        ? '—'
                        : _normalizarNotaVisible(best.toString()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatoCarrusel(
                    label: 'último registro',
                    value: _formatearFechaCarrusel(last) ?? '—',
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

class _DatoCarrusel extends StatelessWidget {
  const _DatoCarrusel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScrollStackSituacion extends StatelessWidget {
  const _ScrollStackSituacion({
    required this.documento,
    required this.materias,
    required this.reduceMotion,
  });

  final DocumentoAcademicoPdf documento;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final groups = <int, List<MateriaDocumentoAcademicoPdf>>{};
    for (final materia in materias) {
      groups.putIfAbsent(materia.anio, () => <MateriaDocumentoAcademicoPdf>[])
        ..add(materia);
    }
    final years = groups.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640
            ? 3
            : constraints.maxWidth >= 350
            ? 2
            : 1;
        const sectionGap = 16.0;
        final heights = <double>[];
        for (final year in years) {
          final rows = (groups[year]!.length / columns).ceil();
          heights.add(124 + rows * 80.0);
        }
        var top = 0.0;
        final tops = <double>[];
        for (var index = 0; index < heights.length; index++) {
          tops.add(top);
          top +=
              heights[index] + (index == heights.length - 1 ? 0 : sectionGap);
        }

        return SizedBox(
          key: const Key('document-situation-scroll-stack'),
          height: top,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < years.length; index++)
                Positioned(
                  top: tops[index],
                  left: 0,
                  right: 0,
                  height: heights[index],
                  child: _EntradaReactDocumento(
                    index: index,
                    reduceMotion: reduceMotion,
                    child: _TarjetaAnioStack(
                      documento: documento,
                      anio: years[index],
                      materias: groups[years[index]]!,
                      columns: columns,
                      depth: index,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaAnioStack extends StatelessWidget {
  const _TarjetaAnioStack({
    required this.documento,
    required this.anio,
    required this.materias,
    required this.columns,
    required this.depth,
  });

  final DocumentoAcademicoPdf documento;
  final int anio;
  final List<MateriaDocumentoAcademicoPdf> materias;
  final int columns;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    final approved = materias
        .where((m) => m.categoriaEstado == CategoriaEstadoDocumentoPdf.aprobada)
        .length;
    final studying = materias
        .where((m) => m.categoriaEstado == CategoriaEstadoDocumentoPdf.cursando)
        .length;
    final pending = materias
        .where(
          (m) => m.categoriaEstado == CategoriaEstadoDocumentoPdf.sinEstado,
        )
        .length;
    final accent = studying > 0
        ? scheme.primary
        : pending > 0 && approved == 0
        ? scheme.onSurfaceVariant
        : PaletaAtlassian.success;
    final summary = <String>[
      if (approved > 0) '$approved aprobadas',
      if (studying > 0) '$studying cursando',
      if (pending > 0) '$pending pendientes',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: reactTheme.cardGradient([
            accent.withValues(
              alpha: 0.18 + depth.clamp(0, 3).toDouble() * 0.015,
            ),
            scheme.surface.withValues(alpha: 0.98),
          ]),
        ),
        border: Border.all(
          color: accent.withValues(alpha: reactTheme.isDark ? 0.26 : 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.26
                  : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$anioº',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 37,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'año',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    summary,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = 8.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final materia in materias)
                      SizedBox(
                        width: width,
                        height: 72,
                        child: _MateriaCompactaStack(
                          documento: documento,
                          materia: materia,
                        ),
                      ),
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

class _MateriaCompactaStack extends StatelessWidget {
  const _MateriaCompactaStack({required this.documento, required this.materia});

  final DocumentoAcademicoPdf documento;
  final MateriaDocumentoAcademicoPdf materia;

  @override
  Widget build(BuildContext context) {
    final accent = _acentoMateria(context, materia);
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    final state = _estadoVisible(documento.tipo, materia).toLowerCase();
    final note = _textoValido(materia.nota);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: reactTheme.isDark ? Colors.transparent : Colors.white,
        border: Border.all(
          color: accent.withValues(alpha: reactTheme.isDark ? 0.18 : 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _nombreMateriaVisible(materia.nombre),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  state,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: accent),
                ),
              ),
              if (note != null)
                Text(
                  _normalizarNotaVisible(note),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DockDocumentoAcademicoNativo extends StatelessWidget {
  const DockDocumentoAcademicoNativo({
    super.key,
    required this.onCompartir,
    required this.onVerPdfOriginal,
    required this.onAbrirExternamente,
    required this.reduceMotion,
    this.onActualizar,
    this.actualizando = false,
    this.pdfDisponible = true,
  });

  final VoidCallback onCompartir;
  final VoidCallback onVerPdfOriginal;
  final VoidCallback onAbrirExternamente;
  final bool reduceMotion;
  final VoidCallback? onActualizar;
  final bool actualizando;
  final bool pdfDisponible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reactTheme = context.reactTheme;

    return Align(
      alignment: Alignment.center,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: onActualizar == null ? 316 : 360),
        child: Semantics(
          container: true,
          label: 'Acciones del documento',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                key: const Key('document-dock-surface'),
                height: 66,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(33),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            scheme.surface.withValues(alpha: 0.94),
                            Color.lerp(
                              scheme.surface,
                              scheme.primary,
                              0.09,
                            )!.withValues(alpha: 0.94),
                            Color.lerp(
                              scheme.surface,
                              scheme.tertiary,
                              0.07,
                            )!.withValues(alpha: 0.94),
                          ]
                        : reactTheme.liquidGradient(scheme),
                  ),
                  border: Border.all(
                    color: dark
                        ? scheme.onSurface.withValues(alpha: 0.16)
                        : reactTheme.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.42 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: dark ? 0.16 : 0.10,
                      ),
                      blurRadius: 26,
                      spreadRadius: -5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: DecoratedBox(
                        key: const Key('document-dock-ambient-glow'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(33),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.82,
                            colors: [
                              scheme.primary.withValues(
                                alpha: dark ? 0.06 : 0.08,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.72],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (onActualizar != null)
                          Expanded(
                            child: _AccionGlassDocumento(
                              key: const Key('document-action-update'),
                              icon: Icons.refresh_rounded,
                              label: actualizando
                                  ? 'Actualizando…'
                                  : 'Actualizar',
                              onTap: actualizando ? null : onActualizar,
                              reduceMotion: reduceMotion,
                            ),
                          ),
                        Expanded(
                          child: _AccionGlassDocumento(
                            key: const Key('document-action-share'),
                            icon: Icons.ios_share_rounded,
                            label: 'compartir',
                            onTap: pdfDisponible ? onCompartir : null,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                        Expanded(
                          child: _AccionGlassDocumento(
                            key: const Key('document-action-original-pdf'),
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'pdf',
                            onTap: pdfDisponible ? onVerPdfOriginal : null,
                            reduceMotion: reduceMotion,
                            emphasized: true,
                          ),
                        ),
                        Expanded(
                          child: _AccionGlassDocumento(
                            key: const Key('document-action-external'),
                            icon: Icons.open_in_new_rounded,
                            label: 'abrir',
                            onTap: pdfDisponible ? onAbrirExternamente : null,
                            reduceMotion: reduceMotion,
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
      ),
    );
  }
}

class _AccionGlassDocumento extends StatefulWidget {
  const _AccionGlassDocumento({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.reduceMotion,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool reduceMotion;
  final bool emphasized;

  @override
  State<_AccionGlassDocumento> createState() => _AccionGlassDocumentoState();
}

class _AccionGlassDocumentoState extends State<_AccionGlassDocumento> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final pdfAccent = dark ? const Color(0xFF9CC7FF) : scheme.primary;
    final accent = widget.onTap == null
        ? scheme.onSurface.withValues(alpha: 0.38)
        : widget.emphasized
        ? pdfAccent
        : scheme.onSurface;
    final duration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 150);

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: duration,
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    key: ValueKey('document-action-icon-${widget.label}'),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.emphasized
                          ? null
                          : scheme.onSurface.withValues(
                              alpha: _pressed ? 0.13 : 0.075,
                            ),
                      gradient: widget.emphasized
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withValues(alpha: 0.34),
                                scheme.primary.withValues(alpha: 0.14),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: widget.emphasized
                            ? dark
                                  ? const Color(
                                      0xFF658DC6,
                                    ).withValues(alpha: 0.65)
                                  : scheme.primary.withValues(alpha: 0.58)
                            : scheme.onSurface.withValues(alpha: 0.10),
                      ),
                      boxShadow: widget.emphasized
                          ? [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.30),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, size: 18, color: accent),
                  ),
                  const SizedBox(height: 2),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: widget.emphasized
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    key: ValueKey('document-action-indicator-${widget.label}'),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: widget.emphasized ? 20 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: widget.emphasized ? pdfAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: widget.emphasized
                          ? [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.38),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
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

/// El filtro anima el bloque completo con un solo ritmo. Las entradas por
/// tarjeta no se reinician ni alargan el cambio según la cantidad de materias.
class _ContenidoFiltroSinEntradasEscalonadas extends InheritedWidget {
  const _ContenidoFiltroSinEntradasEscalonadas({required super.child});

  @override
  bool updateShouldNotify(_ContenidoFiltroSinEntradasEscalonadas oldWidget) =>
      false;
}

class _EntradaReactDocumento extends StatelessWidget {
  const _EntradaReactDocumento({
    required this.index,
    required this.reduceMotion,
    required this.child,
  });

  final int index;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion ||
        context
                .dependOnInheritedWidgetOfExactType<
                  _ContenidoFiltroSinEntradasEscalonadas
                >() !=
            null) {
      return child;
    }
    final milliseconds = 230 + index.clamp(0, 8).toInt() * 35;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _NotaPendientesReact extends StatelessWidget {
  const _NotaPendientesReact({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactTheme = context.reactTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: reactTheme.cardGradient([
            scheme.onSurfaceVariant.withValues(alpha: 0.08),
            scheme.surface.withValues(alpha: 0.92),
          ]),
        ),
        border: Border.all(color: reactTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El PDF oficial deja $cantidad materia${cantidad == 1 ? '' : 's'} sin estado, fecha ni nota. En esta vista se muestra${cantidad == 1 ? '' : 'n'} como pendiente${cantidad == 1 ? '' : 's'} para facilitar la lectura.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

(String, String) _tituloEditorial(TipoDocumentoAcademicoPdf type) =>
    switch (type) {
      TipoDocumentoAcademicoPdf.libreta => ('libreta', 'de calificaciones'),
      TipoDocumentoAcademicoPdf.analitico => ('certificado', 'analítico'),
      TipoDocumentoAcademicoPdf.situacionAcademica => (
        'situación',
        'académica',
      ),
    };

Color _acentoMateria(
  BuildContext context,
  MateriaDocumentoAcademicoPdf materia,
) {
  final scheme = Theme.of(context).colorScheme;
  if (scheme.brightness == Brightness.dark) {
    return switch (materia.categoriaEstado) {
      CategoriaEstadoDocumentoPdf.aprobada => const Color(0xFF66D5A1),
      CategoriaEstadoDocumentoPdf.cursando => const Color(0xFF9CC7FF),
      CategoriaEstadoDocumentoPdf.regular => const Color(0xFFFFD080),
      CategoriaEstadoDocumentoPdf.sinEstado => scheme.onSurfaceVariant,
      CategoriaEstadoDocumentoPdf.otra => const Color(0xFFCBB8FF),
    };
  }
  return switch (materia.categoriaEstado) {
    CategoriaEstadoDocumentoPdf.aprobada => PaletaAtlassian.success,
    CategoriaEstadoDocumentoPdf.cursando => scheme.primary,
    CategoriaEstadoDocumentoPdf.regular => PaletaAtlassian.warning,
    CategoriaEstadoDocumentoPdf.sinEstado => scheme.onSurfaceVariant,
    CategoriaEstadoDocumentoPdf.otra => scheme.tertiary,
  };
}

String _estadoVisible(
  TipoDocumentoAcademicoPdf type,
  MateriaDocumentoAcademicoPdf subject,
) {
  final value = _textoValido(subject.estado);
  if (value != null) return value;
  return type == TipoDocumentoAcademicoPdf.situacionAcademica
      ? 'Pendiente'
      : 'Sin estado';
}

String? _textoValido(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _formatearFechaCorta(DateTime? value) {
  if (value == null) return null;
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String? _formatearFechaCarrusel(DateTime? value) {
  if (value == null) return null;
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final year = (value.year % 100).toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} $year';
}

String _fechaSuave(String value) {
  final date = parsearFechaDocumentoAcademico(value);
  return _formatearFechaCorta(date) ?? value;
}

String _normalizarNotaVisible(String value) {
  final number = double.tryParse(value.replaceAll(',', '.'));
  if (number == null) return value;
  if (number == number.roundToDouble()) return number.toInt().toString();
  return number
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _nombrePersonaVisible(String value) {
  final trimmed = value.trim();
  if (!_pareceTodoMayusculas(trimmed)) return trimmed;
  return trimmed
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map(_capitalizarPalabra)
      .join(' ');
}

String _descripcionCarreraVisible(String value) {
  final trimmed = value.trim();
  if (!_pareceTodoMayusculas(trimmed)) return trimmed;
  final lower = trimmed.toLowerCase();
  return lower.isEmpty
      ? lower
      : '${lower[0].toUpperCase()}${lower.substring(1)}';
}

String _fraseSuave(String value) {
  final trimmed = value.trim();
  if (!_pareceTodoMayusculas(trimmed)) return trimmed;
  return trimmed.toLowerCase();
}

String _nombreMateriaVisible(String value) {
  final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (!_pareceTodoMayusculas(trimmed)) return trimmed;
  const preserved = <String, String>{
    'i': 'I',
    'ii': 'II',
    'iii': 'III',
    'iv': 'IV',
    'tic': 'TIC',
    'u.d.i.': 'U.D.I.',
  };
  const small = <String>{
    'de',
    'del',
    'la',
    'las',
    'los',
    'y',
    'e',
    'en',
    'para',
    'por',
  };
  final words = trimmed.toLowerCase().split(' ');
  return words
      .asMap()
      .entries
      .map((entry) {
        final word = entry.value;
        final clean = word.replaceAll(
          RegExp(r'^[^a-záéíóúñ]+|[^a-záéíóúñ.]+$'),
          '',
        );
        if (preserved.containsKey(clean)) {
          return word.replaceFirst(clean, preserved[clean]!);
        }
        if (entry.key > 0 && small.contains(clean)) return word;
        return _capitalizarPalabra(word);
      })
      .join(' ');
}

bool _pareceTodoMayusculas(String value) {
  final letters = value.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
  if (letters.isEmpty) return false;
  return !RegExp(r'[a-záéíóúüñ]').hasMatch(letters);
}

String _capitalizarPalabra(String value) {
  if (value.isEmpty) return value;
  final match = RegExp(r'[a-záéíóúüñ]').firstMatch(value);
  if (match == null) return value;
  final index = match.start;
  return '${value.substring(0, index)}${value[index].toUpperCase()}${value.substring(index + 1)}';
}
