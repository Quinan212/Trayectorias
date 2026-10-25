import 'package:correlativas_historia/datos/cargador_fuente_html.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(limpiarCachePlanesParaPruebas);

  test(
    'dos pantallas comparten la misma lectura y conservan los acentos',
    () async {
      final primera = cargarPlanDesdeHtml('assets/data/educacion_fisica.json');
      final segunda = cargarPlanDesdeHtml('assets/data/educacion_fisica.json');
      expect(identical(primera, segunda), isTrue);
      final plan = await primera;
      expect(identical(plan, await segunda), isTrue);
      expect(plan.materias.length, 38);
      expect(plan.materias.any((m) => m.nombre.contains('Filosofía')), isTrue);
    },
  );

  test('una lectura fallida no deja la carrera bloqueada en caché', () async {
    const asset = 'assets/data/plan_inexistente_prueba.json';
    final primera = cargarPlanDesdeHtml(asset);
    await expectLater(primera, throwsA(isA<FlutterError>()));
    final segunda = cargarPlanDesdeHtml(asset);
    expect(identical(primera, segunda), isFalse);
    await expectLater(segunda, throwsA(isA<FlutterError>()));
  });
}
