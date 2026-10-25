import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'modelos_sincronizacion_sage_automatica.dart';

class PantallaSincronizacionSageAutomatica extends StatefulWidget {
  const PantallaSincronizacionSageAutomatica({
    super.key,
    required this.estado,
    required this.loginDisponible,
    required this.procesandoCredenciales,
    required this.onIngresar,
    required this.onReintentar,
    required this.onCancelar,
  });

  final EstadoSincronizacionSageAutomatica estado;
  final bool loginDisponible;
  final bool procesandoCredenciales;
  final Future<void> Function(String usuario, String password) onIngresar;
  final VoidCallback? onReintentar;
  final VoidCallback onCancelar;

  @override
  State<PantallaSincronizacionSageAutomatica> createState() =>
      _PantallaSincronizacionSageAutomaticaState();
}

class _PantallaSincronizacionSageAutomaticaState
    extends State<PantallaSincronizacionSageAutomatica> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _ocultarPassword = true;

  @override
  void didUpdateWidget(PantallaSincronizacionSageAutomatica oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = widget.estado;
    final sesionAceptada =
        !state.esError &&
        !state.solicitaCredenciales &&
        (state.etapa == EtapaSincronizacionSageAutomatica.reanudandoSesion ||
            state.etapa == EtapaSincronizacionSageAutomatica.detectandoPerfil ||
            (state.paso?.index ?? 0) >
                PasoSincronizacionSageAutomatica.sesion.index);
    if (sesionAceptada) _passwordController.clear();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _puedeEnviarCredenciales =>
      !widget.procesandoCredenciales &&
      (widget.loginDisponible || widget.estado.solicitaCredenciales);

  Future<void> _submit() async {
    if (!_puedeEnviarCredenciales) return;
    if (_formKey.currentState?.validate() != true) return;
    TextInput.finishAutofillContext();
    final usuario = _usuarioController.text.trim();
    final password = _passwordController.text;
    await widget.onIngresar(usuario, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.estado;
    final showLogin =
        state.solicitaCredenciales || (state.esError && widget.loginDisponible);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  _TransicionSage<(EstadoSincronizacionSageAutomatica, bool)>(
                    value: (state, showLogin),
                    identity: showLogin,
                    duration: duration,
                    builder: (context, visible, opacity) => FadeTransition(
                      opacity: opacity,
                      child: visible.$2
                          ? Center(
                              key: const ValueKey<String>(
                                'sage-auto-layout-login',
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  28,
                                  24,
                                  36,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: _buildLogin(context, visible.$1),
                                ),
                              ),
                            )
                          : Center(
                              key: const ValueKey<String>(
                                'sage-auto-layout-progress',
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 36,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: _buildProgress(context, visible.$1),
                                ),
                              ),
                            ),
                    ),
                  ),
            ),
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: widget.onCancelar,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogin(
    BuildContext context,
    EstadoSincronizacionSageAutomatica state,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AutofillGroup(
      key: const ValueKey('sage-auto-login'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  state.codigoError ==
                          CodigoErrorSincronizacionSage.sesionVencida
                      ? 'Volver a conectar '
                      : 'Conectar con ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Image.asset(
                    'assets/sage_banner.png',
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Text(
                      'SAGE',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            if (state.detalle?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _MensajeErrorSage(
                mensaje: state.detalle!,
                codigo: state.codigoVisible,
              ),
            ],
            const SizedBox(height: 22),
            TextFormField(
              controller: _usuarioController,
              enabled: !widget.procesandoCredenciales,
              autofocus: true,
              autofillHints: const [AutofillHints.username],
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'DNI o usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresá tu usuario.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !widget.procesandoCredenciales,
              obscureText: _ocultarPassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _ocultarPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: widget.procesandoCredenciales
                      ? null
                      : () => setState(
                          () => _ocultarPassword = !_ocultarPassword,
                        ),
                  icon: Icon(
                    _ocultarPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresá tu contraseña.'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _puedeEnviarCredenciales ? _submit : null,
              icon: widget.procesandoCredenciales
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                widget.procesandoCredenciales
                    ? 'Iniciando sesión…'
                    : 'Iniciar y sincronizar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(
    BuildContext context,
    EstadoSincronizacionSageAutomatica state,
  ) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return _TransicionSage<EstadoSincronizacionSageAutomatica>(
      key: const ValueKey<String>('sage-auto-progress'),
      value: state,
      identity: _StepperSincronizacionSage.identidad(state),
      duration: duration,
      builder: (context, visible, opacity) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sincronización con SAGE',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 26),
          _StepperSincronizacionSage(
            estado: visible,
            duration: duration,
            opacity: opacity,
          ),
          if (!visible.completada && !visible.esError) ...[
            const SizedBox(height: 18),
            _BarraProgresoSage(value: visible.progreso, duration: duration),
          ],
          if (visible.esError && visible.permiteReintentar) ...[
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: widget.onReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar este paso'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mantiene un único contenido. Durante la salida conserva el actual y,
/// al quedar transparente, toma la actualización más reciente sin encolarlas.
class _TransicionSage<T> extends StatefulWidget {
  const _TransicionSage({
    super.key,
    required this.value,
    required this.identity,
    required this.duration,
    required this.builder,
  });

  final T value;
  final Object identity;
  final Duration duration;
  final Widget Function(BuildContext, T, Animation<double>) builder;

  @override
  State<_TransicionSage<T>> createState() => _TransicionSageState<T>();
}

class _TransicionSageState<T> extends State<_TransicionSage<T>>
    with SingleTickerProviderStateMixin {
  late T _visible;
  late Object _identity;
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _visible = widget.value;
    _identity = widget.identity;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ~/ 2,
      value: 1,
    )..addStatusListener(_onStatus);
    _opacity = _controller.drive(CurveTween(curve: Curves.easeInOutCubic));
  }

  @override
  void didUpdateWidget(covariant _TransicionSage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration ~/ 2;
    if (widget.duration == Duration.zero) {
      _visible = widget.value;
      _identity = widget.identity;
      _controller.value = 1;
    } else if (widget.identity == _identity) {
      // El avance numérico no reinicia la transición de los mensajes.
      _visible = widget.value;
      if (_controller.status == AnimationStatus.reverse) {
        _controller.forward();
      }
    } else if (!_controller.isAnimating) {
      _controller.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _visible = widget.value;
        _identity = widget.identity;
      });
      _controller.forward();
    } else if (status == AnimationStatus.completed &&
        widget.identity != _identity) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _visible, _opacity);
}

class _BarraProgresoSage extends StatelessWidget {
  const _BarraProgresoSage({required this.value, required this.duration});

  final double? value;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final progress = value?.clamp(0, 1).toDouble();
    if (progress == null) {
      return LinearProgressIndicator(
        minHeight: 5,
        borderRadius: BorderRadius.circular(99),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, animatedValue, _) {
        return LinearProgressIndicator(
          value: animatedValue,
          minHeight: 5,
          borderRadius: BorderRadius.circular(99),
        );
      },
    );
  }
}

enum _EstadoEtapaStepperSage { completada, activa, pendiente, error }

class _StepperSincronizacionSage extends StatelessWidget {
  const _StepperSincronizacionSage({
    required this.estado,
    required this.duration,
    required this.opacity,
  });

  static const _etiquetas = <String>[
    'Acceso a SAGE',
    'Perfil y legajo',
    'Trayectoria académica',
    'Documentos y guardado',
  ];

  final EstadoSincronizacionSageAutomatica estado;
  final Duration duration;
  final Animation<double> opacity;

  static Object identidad(EstadoSincronizacionSageAutomatica estado) => (
    _indiceEtapa(estado.paso),
    estado.completada,
    estado.esError,
    estado.completada ? estado.titulo : null,
    estado.detalle?.trim().isNotEmpty == true
        ? estado.detalle!.trim()
        : estado.titulo.trim(),
    estado.sesionReutilizada,
    estado.intentoActual,
    estado.intentosMaximos,
    estado.codigoVisible,
    estado.permiteReintentar,
  );

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indiceEtapa(estado.paso);
    final currentLabel = _etiquetas[currentIndex];
    final detail = _supportingText();
    final eyebrow = estado.completada
        ? 'Finalizado'
        : estado.esError
        ? 'Atención requerida'
        : 'Paso ${currentIndex + 1} de ${_etiquetas.length}';
    final title = estado.completada ? estado.titulo : currentLabel;
    final description = estado.completada
        ? (estado.detalle?.trim() ?? '')
        : detail;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Progreso de sincronización',
      child: KeyedSubtree(
        key: const ValueKey<String>('sage-sync-stepper'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              key: const ValueKey<String>('sage-sync-stepper-rail'),
              children: [
                for (var index = 0; index < _etiquetas.length; index++) ...[
                  _MarcadorEtapaSage(
                    index: index,
                    label: _etiquetas[index],
                    status: _statusFor(index, currentIndex),
                    duration: duration,
                  ),
                  if (index < _etiquetas.length - 1)
                    Expanded(
                      child: _ConectorEtapaSage(
                        active: estado.completada || index < currentIndex,
                        duration: duration,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              key: const ValueKey<String>('sage-sync-step-content'),
              height: 144,
              child: ClipRect(
                child: _ContenidoEtapaSage(
                  eyebrow: eyebrow,
                  title: title,
                  detail: description,
                  metadata: _metadata(),
                  isError: estado.esError,
                  opacity: opacity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _supportingText() {
    final detail = estado.detalle?.trim() ?? '';
    return detail.isNotEmpty ? detail : estado.titulo.trim();
  }

  List<_MetadataEtapaSage> _metadata() {
    final items = <_MetadataEtapaSage>[];
    if (estado.sesionReutilizada) {
      items.add(
        const _MetadataEtapaSage(
          icon: Icons.lock_open_rounded,
          label: 'Sesión reutilizada',
        ),
      );
    }
    if (estado.intentoActual > 0) {
      items.add(
        _MetadataEtapaSage(
          icon: Icons.replay_rounded,
          label: 'Reintento ${estado.intentoActual}/${estado.intentosMaximos}',
        ),
      );
    }
    if (estado.codigoVisible != null) {
      items.add(
        _MetadataEtapaSage(
          icon: Icons.tag_rounded,
          label: estado.codigoVisible!,
        ),
      );
    }
    return items;
  }

  _EstadoEtapaStepperSage _statusFor(int index, int currentIndex) {
    if (estado.completada || index < currentIndex) {
      return _EstadoEtapaStepperSage.completada;
    }
    if (index > currentIndex) return _EstadoEtapaStepperSage.pendiente;
    if (estado.esError) return _EstadoEtapaStepperSage.error;
    return _EstadoEtapaStepperSage.activa;
  }

  static int _indiceEtapa(PasoSincronizacionSageAutomatica? paso) =>
      switch (paso) {
        PasoSincronizacionSageAutomatica.sesion => 0,
        PasoSincronizacionSageAutomatica.perfil ||
        PasoSincronizacionSageAutomatica.legajo => 1,
        PasoSincronizacionSageAutomatica.escolares ||
        PasoSincronizacionSageAutomatica.historial ||
        PasoSincronizacionSageAutomatica.carreras => 2,
        PasoSincronizacionSageAutomatica.documentos ||
        PasoSincronizacionSageAutomatica.guardado => 3,
        null => 0,
      };
}

class _MarcadorEtapaSage extends StatelessWidget {
  const _MarcadorEtapaSage({
    required this.index,
    required this.label,
    required this.status,
    required this.duration,
  });

  final int index;
  final String label;
  final _EstadoEtapaStepperSage status;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusText = switch (status) {
      _EstadoEtapaStepperSage.completada => 'completado',
      _EstadoEtapaStepperSage.activa => 'en curso',
      _EstadoEtapaStepperSage.pendiente => 'pendiente',
      _EstadoEtapaStepperSage.error => 'requiere atención',
    };
    final marker = switch (status) {
      _EstadoEtapaStepperSage.completada => Container(
        key: const ValueKey<String>('complete'),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
      ),
      _EstadoEtapaStepperSage.activa =>
        duration == Duration.zero
            ? Container(
                key: const ValueKey<String>('active-static'),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : SizedBox.square(
                key: const ValueKey<String>('active-loading'),
                dimension: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      key: ValueKey<String>('sage-sync-step-loading-$index'),
                      strokeWidth: 2.4,
                      color: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: 0.16),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
      _EstadoEtapaStepperSage.pendiente => Container(
        key: const ValueKey<String>('pending'),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _EstadoEtapaStepperSage.error => Container(
        key: const ValueKey<String>('error'),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.error, width: 2),
        ),
        child: Icon(Icons.priority_high_rounded, size: 18, color: scheme.error),
      ),
    };

    return Semantics(
      label: '$label: $statusText',
      selected:
          status == _EstadoEtapaStepperSage.activa ||
          status == _EstadoEtapaStepperSage.error,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                key: ValueKey<String>('sage-sync-step-$index-${status.name}'),
                dimension: 32,
              ),
              AnimatedScale(
                duration: duration,
                curve: Curves.easeOutCubic,
                scale: status == _EstadoEtapaStepperSage.activa ? 1 : 0.94,
                child: marker,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConectorEtapaSage extends StatelessWidget {
  const _ConectorEtapaSage({required this.active, required this.duration});

  final bool active;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: scheme.outlineVariant),
              AnimatedFractionallySizedBox(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: active ? 1 : 0,
                child: ColoredBox(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContenidoEtapaSage extends StatelessWidget {
  const _ContenidoEtapaSage({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.metadata,
    required this.isError,
    required this.opacity,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final List<_MetadataEtapaSage> metadata;
  final bool isError;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isError ? scheme.error : scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isError ? scheme.error : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 42,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (metadata.isNotEmpty)
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final item in metadata)
                _MetadataEtapaSageVisual(
                  key: ValueKey(item.label),
                  item: item,
                  isError: isError,
                ),
            ],
          ),
      ],
    );
  }
}

class _MetadataEtapaSage {
  const _MetadataEtapaSage({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _MetadataEtapaSageVisual extends StatelessWidget {
  const _MetadataEtapaSageVisual({
    super.key,
    required this.item,
    required this.isError,
  });

  final _MetadataEtapaSage item;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          item.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MensajeErrorSage extends StatelessWidget {
  const _MensajeErrorSage({required this.mensaje, this.codigo});

  final String mensaje;
  final String? codigo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                if (codigo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    codigo!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
