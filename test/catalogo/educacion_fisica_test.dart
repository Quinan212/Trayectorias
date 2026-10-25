import 'package:correlativas_historia/compartido/proveedores/estado_app.dart';
import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    container.read(proveedorIdCarreraSeleccionada.notifier).state = 'fisica';
  });

  tearDown(() => container.dispose());

  test('Educación Física aparece con su institución y conserva su ID', () {
    final career = container.read(proveedorCarreraSeleccionadaONula);
    final institution = container.read(proveedorInstitucionSeleccionada);

    expect(career?.id, 'fisica');
    expect(career?.nombre, 'Profesorado en Educación Física');
    expect(institution?.id, 'fisica_iseef');
    expect(institution?.careerId, career?.id);
    expect(
      institution?.nombre,
      'Instituto Superior de las Especialidades de la Educación Física',
    );
    expect(
      container.read(proveedorUrlDescargaCarrera),
      startsWith('https://iseef-ers.infd.edu.ar/'),
    );

    final visibleIds = container.read(proveedorCarreras).map((item) => item.id);
    expect(visibleIds, contains('fisica'));
    expect(
      visibleIds,
      isNot(
        anyElement(
          isIn([
            'lengua_literatura',
            'biologia',
            'filosofia',
            'psicologia',
            'contador',
          ]),
        ),
      ),
    );
  });

  test(
    'el plan carga los cuatro años sin referencias a materias inexistentes',
    () async {
      final plan = await container.read(proveedorPlan.future);
      final ids = plan.materias.map((item) => item.id).toSet();

      expect(plan.materias, hasLength(38));
      expect(ids, hasLength(plan.materias.length));
      expect(plan.materias.map((item) => item.anio).toSet(), {1, 2, 3, 4});
      expect(
        plan.materias.firstWhere((item) => item.id == 'didactica-ef-1').nombre,
        'Didáctica de la Educación Física I',
      );
      expect(
        plan.materias.firstWhere((item) => item.id == 'filosofia').anio,
        2,
      );
      expect(plan.materias.where((item) => item.anio == 1), hasLength(10));
      expect(plan.materias.where((item) => item.anio == 2), hasLength(10));
      expect(plan.pdfUrl?.host, 'iseef-ers.infd.edu.ar');

      for (final subject in plan.materias) {
        for (final id in subject.correlativas) {
          expect(ids, contains(id), reason: '${subject.id}: $id');
        }
        for (final requirement in subject.correlativasDetalladas) {
          if (requirement.isSpecial) continue;
          expect(ids, contains(requirement.id), reason: subject.id);
        }
      }
    },
  );

  test(
    'Residencia mantiene los requisitos propios de Educación Física',
    () async {
      final plan = await container.read(proveedorPlan.future);
      final residence = plan.materias.firstWhere(
        (item) => item.id == 'residencia',
      );
      final requirements = residence.correlativasDetalladas;

      expect(
        requirements.singleWhere((item) => item.isSpecial).nombre,
        'Todas las UC de 1° y 2° Año',
      );
      expect(residence.correlativas, contains('didactica-ef-2'));
      expect(
        requirements.singleWhere((item) => item.id == 'didactica-ef-2').type,
        'A',
      );
      expect(
        requirements.singleWhere((item) => item.id == 'sociologia').type,
        'R',
      );
      expect(requirements, hasLength(8));
    },
  );
  testWidgets('el detalle muestra Filosofía en segundo año con tildes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plan = await tester.runAsync(
      () => container.read(proveedorPlan.future),
    );
    final philosophy = plan!.materias.firstWhere(
      (item) => item.id == 'filosofia',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaDetallePlanAtlassian(
          subject: philosophy,
          allSubjects: plan.materias,
          careerName: 'Profesorado en Educación Física',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Filosofía'), findsOneWidget);
    expect(find.text('2° AÑO'), findsOneWidget);
    expect(find.text('1° AÑO'), findsNothing);
    expect(find.text('Profesorado en Educación Física'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
