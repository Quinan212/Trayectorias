import 'dart:async';

/// Vigila avance real; mensajes repetidos no prolongan una etapa bloqueada.
class VigilanciaSage {
  VigilanciaSage({
    required this.recuperar,
    required this.alAgotar,
    this.limite = const Duration(seconds: 5),
    this.maximoPorPaso = 2,
    this.maximoTotal = 4,
  });

  final Future<void> Function() recuperar;
  final void Function() alAgotar;
  final Duration limite;
  final int maximoPorPaso;
  final int maximoTotal;
  Timer? _timer;
  final Map<int, int> _intentos = {};
  int _total = 0;
  int _revision = 0;
  int _paso = -1;
  int _pasoMasAvanzado = -1;
  double _progreso = -1;
  int _unidades = -1;
  bool _activa = false;
  bool _recuperando = false;

  void observar({required int paso, double? progreso, int? unidades}) {
    final avance =
        paso > _pasoMasAvanzado ||
        (paso == _pasoMasAvanzado && (progreso ?? -1) > _progreso) ||
        (unidades != null && unidades > _unidades);
    _paso = paso;
    if (avance) {
      _pasoMasAvanzado = paso;
      _progreso = progreso ?? -1;
      if (unidades != null) _unidades = unidades;
    }
    _activa = true;
    if (_recuperando) return;
    if (avance || _timer == null) _armar();
  }

  void _armar() {
    _timer?.cancel();
    final revision = _revision;
    _timer = Timer(limite, () async {
      _timer = null;
      if (!_activa || _recuperando || revision != _revision) return;
      final intentos = _intentos[_paso] ?? 0;
      if (intentos >= maximoPorPaso || _total >= maximoTotal) {
        cancel();
        alAgotar();
        return;
      }
      _intentos[_paso] = intentos + 1;
      _total++;
      _recuperando = true;
      // El recorrido puede empezar desde una página anterior al recuperarse.
      _pasoMasAvanzado = -1;
      _progreso = -1;
      _unidades = -1;
      try {
        await recuperar();
      } catch (_) {
        // Una recuperación fallida vuelve a intentarse dentro del límite.
      } finally {
        if (revision == _revision) {
          _recuperando = false;
          if (_activa) _armar();
        }
      }
    });
  }

  /// Pausa al salir, pasar a segundo plano o esperar una decisión del usuario.
  void cancel() {
    _revision++;
    _activa = false;
    _recuperando = false;
    _timer?.cancel();
    _timer = null;
  }

  void reiniciar() {
    cancel();
    _intentos.clear();
    _total = 0;
    _pasoMasAvanzado = -1;
    _progreso = -1;
    _unidades = -1;
  }
}

/// Un aviso viejo del DOM o un formulario todavía cargando no rechazan acceso.
bool rechazoCredencialesConfirmadoSage({
  required bool autenticado,
  required bool formularioVisible,
  required bool documentoListo,
  required bool navegando,
  required int observaciones,
  required Duration desdeEnvio,
  required Duration errorPersistente,
}) =>
    !autenticado &&
    formularioVisible &&
    documentoListo &&
    !navegando &&
    observaciones >= 3 &&
    desdeEnvio >= const Duration(seconds: 5) &&
    errorPersistente >= const Duration(seconds: 2);
