import 'dart:async';
import 'dart:convert';

import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/modelos/modelos_trayectoria_sage_laboratorio.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/modelos_sincronizacion_sage_automatica.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sincronizacion_sage_automatica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

const _login = 'https://sage.entrerios.gov.ar/login/';
const _privada = 'https://sage.entrerios.gov.ar/pregase/index.php';

class _Delegado extends PlatformNavigationDelegate {
  _Delegado(super.params) : super.implementation();
  PageEventCallback? inicio;
  PageEventCallback? fin;
  ProgressCallback? progreso;
  WebResourceErrorCallback? error;
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async =>
      inicio = callback;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async =>
      fin = callback;
  @override
  Future<void> setOnProgress(ProgressCallback callback) async =>
      progreso = callback;
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async =>
      error = callback;
  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback callback,
  ) async {}
  @override
  Future<void> setOnUrlChange(UrlChangeCallback callback) async {}
}

class _Cookies extends PlatformWebViewCookieManager {
  _Cookies(super.params) : super.implementation();
  int borrados = 0;
  @override
  Future<bool> clearCookies() async {
    borrados++;
    return true;
  }
}

class _Controlador extends PlatformWebViewController {
  _Controlador(super.params) : super.implementation();
  final cargas = <LoadRequestParams>[];
  _Delegado? delegado;
  String url = _login;
  bool formularioListo = false;
  bool autenticado = false;
  bool avisoViejo = false;
  bool bloquearSondeos = false;
  int envios = 0;
  int sondeos = 0;
  int instalacionesObservador = 0;
  final canales = <String, JavaScriptChannelParams>{};
  Map<String, Object>? capturaNavegacion;
  Completer<Object>? lecturaLoginPendiente;
  final pendiente = Completer<Object>();

  void navegar(String destino) {
    url = destino;
    delegado!.inicio!(destino);
    delegado!.progreso!(100);
    delegado!.fin!(destino);
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate value,
  ) async => delegado = value as _Delegado;
  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    cargas.add(params);
    navegar(
      autenticado && params.uri.toString() == _login
          ? _privada
          : params.uri.toString(),
    );
  }

  @override
  Future<String?> currentUrl() async => url;
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    canales[params.name] = params;
  }

  @override
  Future<void> runJavaScript(String code) async {}
  @override
  Future<Object> runJavaScriptReturningResult(String code) async {
    if (code.contains('const observer = new MutationObserver(notify)')) {
      instalacionesObservador++;
      return true;
    }
    if (code.contains('password_missing')) {
      if (!formularioListo) {
        return jsonEncode({'found': false, 'submitted': false});
      }
      envios++;
      return jsonEncode({'found': true, 'submitted': true});
    }
    if (code.contains('authenticatedScore') &&
        code.contains('loginFormVisible')) {
      if (lecturaLoginPendiente != null) return lecturaLoginPendiente!.future;
      return jsonEncode({
        'authenticated': autenticado,
        'privateShell': autenticado,
        'loginFormVisible': !autenticado && formularioListo,
        'loginForm': !autenticado,
        'loginError': avisoViejo,
        'readyState': formularioListo ? 'complete' : 'loading',
        'pathname': Uri.parse(url).path,
      });
    }
    if (code.contains("const output = {host:''")) {
      sondeos++;
      if (bloquearSondeos) return pendiente.future;
      if (capturaNavegacion != null) return jsonEncode(capturaNavegacion);
      return jsonEncode({
        'host': 'sage.entrerios.gov.ar',
        'pathname': Uri.parse(url).path,
        'headings': autenticado ? [] : ['Ingresar'],
        'links': [],
        'documents': [],
      });
    }
    return '{}';
  }
}

class _Vista extends PlatformWebViewWidget {
  _Vista(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _Plataforma extends WebViewPlatform {
  _Plataforma({this.sesionActiva = false});
  final bool sesionActiva;
  late _Controlador controlador;
  late _Delegado delegado;
  late _Cookies cookies;
  int controladores = 0;
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    controladores++;
    return controlador = _Controlador(params)..autenticado = sesionActiva;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegado = _Delegado(params);
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _Vista(params);
  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) => cookies = _Cookies(params);
}

PantallaSincronizacionSageAutomatica _pantalla(WidgetTester tester) =>
    tester.widget(find.byType(PantallaSincronizacionSageAutomatica));

Future<_Plataforma> _montar(
  WidgetTester tester, {
  ModoPantallaSageLaboratorio modo =
      ModoPantallaSageLaboratorio.sincronizacionAutomatica,
  DocumentoAcademicoSage? documento,
  bool sesionActiva = false,
  bool sesionGuardada = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (sesionGuardada)
      'estado_sincronizacion_sage_v2': jsonEncode({'sesion_confirmada': true}),
  });
  final plataforma = _Plataforma(sesionActiva: sesionActiva);
  WebViewPlatform.instance = plataforma;
  addTearDown(() => _cerrar(tester, plataforma));
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaSageLaboratorio(
        modo: modo,
        documentoSolicitado: documento,
        cerrarAlCompletar: false,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return plataforma;
}

Future<void> _cerrar(WidgetTester tester, _Plataforma plataforma) async {
  await tester.pumpWidget(const SizedBox.shrink());
  if (!plataforma.controlador.pendiente.isCompleted) {
    plataforma.controlador.pendiente.complete('{}');
  }
  await tester.pump(const Duration(seconds: 8));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'una pantalla nativa quieta baja el sondeo; los avisos siguen respondiendo enseguida',
    (tester) async {
      final p = await _montar(tester, modo: ModoPantallaSageLaboratorio.manual);
      p.controlador.capturaNavegacion = {
        'host': 'sage.entrerios.gov.ar',
        'pathname': '/pregase/index.php',
        'headings': ['Módulos'],
        'links': [
          {
            'text': 'Legajo Único Alumno',
            'pathname': '/pregase/menuprincipal_nuevo.php',
            'hrefValid': true,
          },
        ],
        'documents': <Object>[],
      };
      p.controlador.navegar(_privada);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      final anteriores = p.controlador.sondeos;
      await tester.pump(const Duration(seconds: 14));
      expect(p.controlador.sondeos, anteriores);
      await tester.pump(const Duration(seconds: 1));
      expect(p.controlador.sondeos, anteriores + 1);
      p.controlador.canales['SageNavigationBridge']!.onMessageReceived(
        const JavaScriptMessage(message: 'changed'),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.sondeos, anteriores + 2);
      await _cerrar(tester, p);
    },
  );

  testWidgets(
    'agrupar avisos no inicia lecturas simultáneas ni pierde el último cambio',
    (tester) async {
      final p = await _montar(tester, modo: ModoPantallaSageLaboratorio.manual);
      await tester.pump(const Duration(seconds: 1));
      p.controlador.bloquearSondeos = true;
      final canal = p.controlador.canales['SageNavigationBridge']!;
      final anteriores = p.controlador.sondeos;
      for (var i = 0; i < 100; i++) {
        canal.onMessageReceived(const JavaScriptMessage(message: 'changed'));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.sondeos, anteriores + 1);
      for (var i = 0; i < 100; i++) {
        canal.onMessageReceived(const JavaScriptMessage(message: 'changed'));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.sondeos, anteriores + 1);
      p.controlador.bloquearSondeos = false;
      p.controlador.pendiente.complete('{}');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.sondeos, anteriores + 2);
      await _cerrar(tester, p);
    },
  );

  testWidgets(
    'una página estable reutiliza observadores y un cambio de iframe los revisa',
    (tester) async {
      final p = await _montar(tester, modo: ModoPantallaSageLaboratorio.manual);
      final instalaciones = p.controlador.instalacionesObservador;
      expect(instalaciones, greaterThan(0));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(p.controlador.instalacionesObservador, instalaciones);
      p.controlador.canales['SageNavigationBridge']!.onMessageReceived(
        const JavaScriptMessage(message: 'changed'),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.instalacionesObservador, instalaciones + 1);
      await _cerrar(tester, p);
    },
  );

  testWidgets(
    'una ruta tapada detiene sondeos y avisos; al volver retoma la misma vista',
    (tester) async {
      final p = await _montar(tester, modo: ModoPantallaSageLaboratorio.manual);
      final navigator = Navigator.of(
        tester.element(find.byType(PantallaSageLaboratorio)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Documento local')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final anteriores = p.controlador.sondeos;
      p.controlador.canales['SageNavigationBridge']!.onMessageReceived(
        const JavaScriptMessage(message: 'changed'),
      );
      await tester.pump(const Duration(seconds: 16));
      expect(p.controlador.sondeos, anteriores);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.controlador.sondeos, greaterThan(anteriores));
      expect(p.controladores, 1);
      expect(p.cookies.borrados, 0);
      await _cerrar(tester, p);
    },
  );

  testWidgets('en segundo plano no sondea y al reanudar conserva la sesión', (
    tester,
  ) async {
    final p = await _montar(tester, modo: ModoPantallaSageLaboratorio.manual);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final anteriores = p.controlador.sondeos;
    await tester.pump(const Duration(seconds: 16));
    expect(p.controlador.sondeos, anteriores);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(p.controlador.sondeos, greaterThan(anteriores));
    expect(p.controladores, 1);
    expect(p.cookies.borrados, 0);
    await _cerrar(tester, p);
  });

  testWidgets(
    'la vigilancia no recupera una sincronización mientras otra ruta está encima',
    (tester) async {
      final p = await _montar(tester);
      p.controlador.autenticado = true;
      p.controlador.bloquearSondeos = true;
      p.controlador.navegar(_privada);
      await tester.pump();
      final navigator = Navigator.of(
        tester.element(find.byType(PantallaSageLaboratorio)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final cargas = p.controlador.cargas.length;
      await tester.pump(const Duration(seconds: 6));
      expect(p.controlador.cargas.length, cargas);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(p.controlador.cargas.length, cargas + 1);
      expect(p.controladores, 1);
      expect(p.cookies.borrados, 0);
      await _cerrar(tester, p);
    },
  );

  for (final tipo in TipoDocumentoAcademicoSage.values) {
    testWidgets('reutiliza la sesión al abrir ${tipo.etiqueta}', (
      tester,
    ) async {
      final p = await _montar(
        tester,
        modo: ModoPantallaSageLaboratorio.descargaDocumento,
        sesionActiva: true,
        documento: DocumentoAcademicoSage(
          tipo: tipo,
          gridRowId: 'hist-1',
          careerKey: 'historia',
          carrera: 'Profesorado de Historia',
          institucion: 'Instituto',
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      }
      expect(_pantalla(tester).estado.sesionReutilizada, isTrue);
      expect(p.controlador.envios, 0);
      expect(p.cookies.borrados, 0);
    });
  }

  testWidgets('una sesión guardada espera la redirección sin mostrar login', (
    tester,
  ) async {
    final p = await _montar(tester, sesionGuardada: true);
    p.controlador.formularioListo = true;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    }
    p.controlador.autenticado = true;
    p.controlador.navegar(_privada);
    await tester.pump();
    expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    expect(_pantalla(tester).estado.sesionReutilizada, isTrue);
  });

  testWidgets(
    'descarta una lectura de login que termina después de cambiar de página',
    (tester) async {
      final p = await _montar(tester);
      p.controlador.autenticado = true;
      p.controlador.navegar(_privada);
      await tester.pump();
      final progreso = _pantalla(tester).estado.progreso;
      final pendiente = Completer<Object>();
      p.controlador.lecturaLoginPendiente = pendiente;
      p.controlador.autenticado = false;
      p.controlador.formularioListo = true;
      p.controlador.navegar(_login);
      await tester.pump();
      p.controlador.lecturaLoginPendiente = null;
      p.controlador.autenticado = true;
      p.controlador.navegar(_privada);
      pendiente.complete(
        jsonEncode({
          'authenticated': false,
          'privateShell': false,
          'loginFormVisible': true,
          'readyState': 'complete',
          'pathname': '/login/',
        }),
      );
      await tester.pump();
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      expect(
        _pantalla(tester).estado.progreso,
        greaterThanOrEqualTo(progreso!),
      );
    },
  );

  testWidgets('verifica el formulario antes de mostrar el login nativo', (
    tester,
  ) async {
    final p = await _montar(tester);
    expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    p.controlador.formularioListo = true;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(_pantalla(tester).estado.solicitaCredenciales, isTrue);
    expect(p.controlador.envios, 0);
    await _cerrar(tester, p);
  });

  testWidgets('un callback de login viejo no baja del paso de perfil', (
    tester,
  ) async {
    final p = await _montar(tester);
    p.controlador.autenticado = true;
    p.controlador.navegar(_privada);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final progreso = _pantalla(tester).estado.progreso;
    p.delegado.inicio!(_login);
    p.delegado.fin!(_login);
    await tester.pump();
    expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    expect(_pantalla(tester).estado.progreso, greaterThanOrEqualTo(progreso!));
    expect(p.controlador.envios, 0);
    await _cerrar(tester, p);
  });

  testWidgets('un login transitorio mantiene el progreso y retoma la sesión', (
    tester,
  ) async {
    final p = await _montar(tester);
    p.controlador.autenticado = true;
    p.controlador.navegar(_privada);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final progreso = _pantalla(tester).estado.progreso;
    p.controlador.autenticado = false;
    p.controlador.formularioListo = true;
    p.controlador.navegar(_login);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      expect(
        _pantalla(tester).estado.progreso,
        greaterThanOrEqualTo(progreso!),
      );
    }
    p.controlador.autenticado = true;
    p.controlador.navegar(_privada);
    await tester.pump();
    expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    expect(p.cookies.borrados, 0);
    p.controlador.bloquearSondeos = true;
    final cargas = p.controlador.cargas.length;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(
      p.controlador.cargas.length,
      cargas + 1,
      reason: 'La vigilancia vuelve a funcionar después del login transitorio.',
    );
    await _cerrar(tester, p);
  });

  testWidgets('una sesión vencida confirmada sí permite volver a ingresar', (
    tester,
  ) async {
    final p = await _montar(tester);
    p.controlador.autenticado = true;
    p.controlador.navegar(_privada);
    await tester.pump();
    p.controlador.autenticado = false;
    p.controlador.formularioListo = true;
    p.controlador.navegar(_login);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(_pantalla(tester).estado.solicitaCredenciales, isTrue);
    expect(
      _pantalla(tester).estado.codigoError,
      CodigoErrorSincronizacionSage.sesionVencida,
    );
    expect(p.cookies.borrados, 0);
    await _cerrar(tester, p);
  });

  testWidgets(
    'espera el formulario, envía una vez y prioriza la sesión aceptada',
    (tester) async {
      final p = await _montar(tester);
      final ingreso = _pantalla(
        tester,
      ).onIngresar('usuario-prueba', 'clave-prueba');
      await tester.pump(const Duration(seconds: 1));
      expect(_pantalla(tester).estado.esError, isFalse);
      expect(p.controlador.envios, 0);
      p.controlador.formularioListo = true;
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await ingreso;
      expect(p.controlador.envios, 1);
      p.controlador.avisoViejo = true;
      await tester.pump(const Duration(seconds: 1));
      expect(_pantalla(tester).estado.esError, isFalse);
      p.controlador.autenticado = true;
      p.controlador.bloquearSondeos = true;
      p.controlador.navegar(_privada);
      await tester.pump();
      expect(_pantalla(tester).estado.esError, isFalse);
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      // Un onPageFinished del login anterior no reinicia una sesión aceptada.
      p.delegado.fin!(_login);
      await tester.pump();
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      await _cerrar(tester, p);
    },
  );

  testWidgets(
    'recupera un DOM bloqueado a los cinco segundos conservando WebView y cookies',
    (tester) async {
      final p = await _montar(tester);
      p.controlador.autenticado = true;
      p.controlador.bloquearSondeos = true;
      p.controlador.navegar(_privada);
      await tester.pump();
      final progreso = _pantalla(tester).estado.progreso;
      final cargas = p.controlador.cargas.length;
      await tester.pump(const Duration(seconds: 4));
      expect(p.controlador.cargas.length, cargas);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(p.controlador.cargas.length, cargas + 1);
      expect(p.controlador.cargas.last.uri.toString(), _privada);
      expect(p.controlador.cargas.last.method, LoadRequestMethod.get);
      expect(p.controladores, 1);
      expect(p.cookies.borrados, 0);
      expect(
        _pantalla(tester).estado.progreso,
        greaterThanOrEqualTo(progreso!),
      );
      expect(_pantalla(tester).estado.solicitaCredenciales, isFalse);
      await _cerrar(tester, p);
    },
  );
}
