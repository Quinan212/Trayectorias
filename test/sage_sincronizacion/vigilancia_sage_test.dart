import 'dart:async';

import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/sage/vigilancia_sage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'recupera a los cinco segundos sin avance y conserva el recorrido',
    (tester) async {
      var reinicios = 0;
      var errores = 0;
      final guardia = VigilanciaSage(
        recuperar: () async {
          reinicios++;
        },
        alAgotar: () => errores++,
      );
      addTearDown(guardia.cancel);
      guardia.observar(paso: 3, progreso: 0.5);
      await tester.pump(const Duration(seconds: 4));
      // La misma lectura repetida no posterga la recuperación.
      guardia.observar(paso: 3, progreso: 0.5);
      await tester.pump(const Duration(seconds: 1));
      expect(reinicios, 1);
      expect(errores, 0);
      guardia.observar(paso: 4, progreso: 0.7);
      await tester.pump(const Duration(seconds: 4));
      expect(reinicios, 1);
      guardia.cancel();
    },
  );

  testWidgets('avance real y bytes recibidos evitan reiniciar una carga sana', (
    tester,
  ) async {
    var reinicios = 0;
    final guardia = VigilanciaSage(
      recuperar: () async {
        reinicios++;
      },
      alAgotar: () {},
    );
    addTearDown(guardia.cancel);
    guardia.observar(paso: 6, progreso: 0.94, unidades: 0);
    for (var i = 1; i < 6; i++) {
      await tester.pump(const Duration(seconds: 4));
      guardia.observar(paso: 6, progreso: 0.94, unidades: i * 1024);
    }
    expect(reinicios, 0);
    guardia.cancel();
  });

  testWidgets('no reinicia en paralelo ni perpetúa un bucle', (tester) async {
    final pendiente = Completer<void>();
    var reinicios = 0;
    var errores = 0;
    final guardia = VigilanciaSage(
      recuperar: () {
        reinicios++;
        return reinicios == 1 ? pendiente.future : Future<void>.value();
      },
      alAgotar: () => errores++,
    );
    addTearDown(guardia.cancel);
    guardia.observar(paso: 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 20));
    expect(reinicios, 1);
    pendiente.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(reinicios, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(reinicios, 2);
    expect(errores, 1);
  });

  testWidgets('salir o pausar invalida una recuperación que llega tarde', (
    tester,
  ) async {
    final pendiente = Completer<void>();
    var reinicios = 0;
    final guardia = VigilanciaSage(
      recuperar: () {
        reinicios++;
        return pendiente.future;
      },
      alAgotar: () {},
    );
    guardia.observar(paso: 2);
    await tester.pump(const Duration(seconds: 5));
    guardia.cancel();
    pendiente.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(reinicios, 1);
  });

  test(
    'el rechazo requiere estabilidad, gracia y ausencia de sesión activa',
    () {
      bool rechazo({
        bool autenticado = false,
        bool navegando = false,
        bool listo = true,
        int segundos = 5,
      }) => rechazoCredencialesConfirmadoSage(
        autenticado: autenticado,
        formularioVisible: true,
        documentoListo: listo,
        navegando: navegando,
        observaciones: 4,
        desdeEnvio: Duration(seconds: segundos),
        errorPersistente: const Duration(seconds: 2),
      );
      expect(rechazo(segundos: 1), isFalse);
      expect(rechazo(navegando: true), isFalse);
      expect(rechazo(listo: false), isFalse);
      expect(rechazo(autenticado: true), isFalse);
      expect(rechazo(), isTrue);
    },
  );
}
