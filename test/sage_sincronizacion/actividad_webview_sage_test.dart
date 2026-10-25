import 'dart:async';

import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/actividad_webview_sage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel(
    'ar.maillet.correlativas_historia/sage_webview_activity',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final llamadas = <MethodCall>[];

  setUp(() {
    llamadas.clear();
    messenger.setMockMethodCallHandler(canal, (call) async {
      llamadas.add(call);
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(canal, null));

  test(
    'pausa sólo la vista identificada y evita repetir el mismo estado',
    () async {
      final vista = ActividadWebViewSage(identificador: 73);
      await vista.actualizar(false);
      await vista.actualizar(false);
      expect(llamadas, hasLength(1));
      expect(llamadas.single.method, 'setActive');
      expect(llamadas.single.arguments, {'identifier': 73, 'active': false});
      await vista.actualizar(true);
      expect(llamadas.last.arguments, {'identifier': 73, 'active': true});
    },
  );

  test(
    'ordena pausa, reanudación y liberación aunque lleguen juntas',
    () async {
      final bloqueada = Completer<bool>();
      messenger.setMockMethodCallHandler(canal, (call) async {
        llamadas.add(call);
        return llamadas.length == 1 ? bloqueada.future : true;
      });
      final vista = ActividadWebViewSage(identificador: 74);
      final pausa = vista.actualizar(false);
      final reanudar = vista.actualizar(true);
      final liberar = vista.liberar();
      await Future<void>.delayed(Duration.zero);
      expect(llamadas, hasLength(1));
      bloqueada.complete(true);
      await Future.wait([pausa, reanudar, liberar]);
      expect(llamadas.map((call) => call.method), [
        'setActive',
        'setActive',
        'release',
      ]);
      await vista.liberar();
      await vista.actualizar(true);
      expect(llamadas, hasLength(3));
    },
  );

  test('una vista aún no registrada puede reintentar la pausa', () async {
    messenger.setMockMethodCallHandler(canal, (call) async {
      llamadas.add(call);
      return llamadas.length > 1;
    });
    final vista = ActividadWebViewSage(identificador: 75);
    await vista.actualizar(false);
    await vista.actualizar(false);
    await vista.actualizar(false);
    expect(llamadas, hasLength(2));
  });

  test(
    'la falta del complemento o un error nativo no interrumpen SAGE',
    () async {
      final vista = ActividadWebViewSage(identificador: 76);
      messenger.setMockMethodCallHandler(canal, null);
      await vista.actualizar(true);
      messenger.setMockMethodCallHandler(canal, (_) async {
        throw PlatformException(code: 'vista_no_disponible');
      });
      await vista.actualizar(false);
      await vista.liberar();
    },
  );
}
