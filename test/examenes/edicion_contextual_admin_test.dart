import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screen = File(
    'lib/funcionalidades/laboratorio_atlassian/pantallas/'
    'pantalla_examenes_atlassian.dart',
  );
  final repository = File(
    'lib/funcionalidades/administrador/datos/'
    'repositorio_eventos_examen_administrador.dart',
  );

  test('la lista reserva la pulsación prolongada para dispositivos admin', () {
    final source = screen.readAsStringSync();

    expect(source, matches(RegExp(r'onLongPress:\s*isAdmin\s*&&')));
    expect(source, contains('_openQuickControlSheet('));
    expect(source, contains('proveedorEstadoDispositivoAdministrador'));
  });

  test('la vista pública no conserva el interruptor developer', () {
    final source = screen.readAsStringSync();

    expect(source, isNot(contains('_InterruptorModoDeveloperAtlassian')));
    expect(source, isNot(contains('_developerMode')));
    expect(source, isNot(contains('Vista developer')));
  });

  test('el detalle permite editar fecha hora y tres docentes', () {
    final source = screen.readAsStringSync();

    expect(source, contains('_openDetailEditSheet'));
    expect(source, contains("tooltip: 'Editar fecha, hora y docentes'"));
    expect(source, contains('List<TextEditingController>.generate(\n      3,'));
    expect(source, contains("labelText: 'Docente \${index + 1}'"));
  });

  test('el repositorio envía una actualización parcial compatible', () {
    final source = repository.readAsStringSync();

    expect(source, contains('updateScheduleAndTeachers'));
    expect(source, isNot(contains("eventPayload['docentes']")));
    expect(source, contains("'docentes': teachers"));
    expect(source, contains("eventPayload['fecha_reprogramada']"));
    expect(source, contains("eventPayload['fecha']"));
  });
}
