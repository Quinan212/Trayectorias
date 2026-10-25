import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart';
import 'package:correlativas_historia/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'la barra oscura distingue sus acciones incluso sobre el contenido',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Builder(
            builder: (context) => Theme(
              data: temaLaboratorioAtlassian(context),
              child: Scaffold(
                bottomNavigationBar: DockDocumentoAcademicoNativo(
                  onActualizar: () {},
                  onCompartir: () {},
                  onVerPdfOriginal: () {},
                  onAbrirExternamente: () {},
                  reduceMotion: true,
                ),
              ),
            ),
          ),
        ),
      );
      final dock = tester.widget<Container>(
        find.byKey(const Key('document-dock-surface')),
      );
      final backgrounds =
          (dock.decoration! as BoxDecoration).gradient! as LinearGradient;
      const backdrops = [Colors.black, Colors.white, Color(0xFF0C66E4)];
      for (final background in backgrounds.colors) {
        expect(background.a, inInclusiveRange(0.90, 0.97));
        for (final backdrop in backdrops) {
          final visible = Color.alphaBlend(background, backdrop);
          for (final label in ['Actualizar', 'compartir', 'pdf', 'abrir']) {
            final foreground = tester
                .widget<Text>(find.text(label))
                .style!
                .color!;
            expect(_contraste(foreground, visible), greaterThanOrEqualTo(4.5));
          }
        }
      }
      final pdfCircle = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('document-action-icon-pdf')),
      );
      final pdfBackgrounds =
          (pdfCircle.decoration! as BoxDecoration).gradient! as LinearGradient;
      final pdfForeground = tester.widget<Text>(find.text('pdf')).style!.color!;
      for (final background in pdfBackgrounds.colors) {
        for (final dockColor in backgrounds.colors) {
          for (final backdrop in backdrops) {
            final dockBackground = Color.alphaBlend(dockColor, backdrop);
            final visible = Color.alphaBlend(background, dockBackground);
            expect(
              _contraste(pdfForeground, visible),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
      }
      expect(
        tester.getSize(find.byKey(const Key('document-dock-surface'))).height,
        66,
      );
    },
  );

  testWidgets(
    'los estados y nombres mantienen contraste sobre las tarjetas oscuras',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Builder(
            builder: (context) => Theme(
              data: temaLaboratorioAtlassian(context),
              child: Scaffold(
                body: VistaDocumentoAcademicoNativo(
                  documento: DocumentoAcademicoPdf(
                    tipo: TipoDocumentoAcademicoPdf.situacionAcademica,
                    materias: [
                      ..._situacionAcademica().materias,
                      const MateriaDocumentoAcademicoPdf(
                        nombre: 'MATERIA REGULAR',
                        anio: 2,
                        estado: 'Regular',
                      ),
                      const MateriaDocumentoAcademicoPdf(
                        nombre: 'MATERIA CON OTRO ESTADO',
                        anio: 2,
                        estado: 'En revisión',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final entry in [
        ('Materia Aprobada', 'aprobada'),
        ('Materia en Curso', 'cursando'),
        ('Materia Pendiente', 'pendiente'),
        ('Materia Regular', 'regular'),
        ('Materia Con Otro Estado', 'en revisión'),
      ]) {
        final title = find.text(entry.$1);
        await tester.ensureVisible(title);
        await tester.pumpAndSettle();
        final card = find
            .ancestor(of: title, matching: find.byType(Container))
            .first;
        final decoration =
            tester.widget<Container>(card).decoration! as BoxDecoration;
        final background = decoration.color!;
        expect(
          background.a,
          0,
          reason: 'La materia comparte el fondo del panel.',
        );
        final panel = tester
            .widgetList<Container>(
              find.ancestor(of: card, matching: find.byType(Container)),
            )
            .map((widget) => widget.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((box) => box.gradient is LinearGradient);
        final gradient = panel.gradient! as LinearGradient;
        final status = find.descendant(of: card, matching: find.text(entry.$2));
        final statusColor = tester.widget<Text>(status).style!.color!;
        final titleColor = tester.widget<Text>(title).style!.color!;
        for (final panelColor in gradient.colors) {
          final visible = Color.alphaBlend(
            background,
            Color.alphaBlend(panelColor, PaletaAtlassian.canvasDark),
          );
          expect(_contraste(statusColor, visible), greaterThanOrEqualTo(4.5));
          expect(_contraste(titleColor, visible), greaterThanOrEqualTo(4.5));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el PDF claro conserva sus colores y el oscuro distingue la selección',
    (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final available in [true, false]) {
          late Color primary;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness, useMaterial3: true),
              home: Builder(
                builder: (context) {
                  final theme = temaLaboratorioAtlassian(context);
                  primary = theme.colorScheme.primary;
                  return Theme(
                    data: theme,
                    child: Scaffold(
                      bottomNavigationBar: DockDocumentoAcademicoNativo(
                        onActualizar: () {},
                        onCompartir: () {},
                        onVerPdfOriginal: () {},
                        onAbrirExternamente: () {},
                        pdfDisponible: available,
                        reduceMotion: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          final expected = brightness == Brightness.dark
              ? const Color(0xFF9CC7FF)
              : primary;
          final indicator = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('document-action-indicator-pdf')),
          );
          expect((indicator.decoration! as BoxDecoration).color, expected);
          if (available) {
            expect(
              tester.widget<Text>(find.text('pdf')).style!.color,
              expected,
            );
          }
          if (brightness == Brightness.light) {
            final dock = tester.widget<Container>(
              find.byKey(const Key('document-dock-surface')),
            );
            expect(
              ((dock.decoration! as BoxDecoration).gradient! as LinearGradient)
                  .colors,
              const [
                Color(0xDFFFFFFF),
                Color(0x96FFFFFF),
                Color(0x72FFFFFF),
                Color(0xB8FFFFFF),
              ],
            );
            final pdfCircle = tester.widget<AnimatedContainer>(
              find.byKey(const ValueKey('document-action-icon-pdf')),
            );
            expect(
              ((pdfCircle.decoration! as BoxDecoration).gradient!
                      as LinearGradient)
                  .colors,
              [
                primary.withValues(alpha: 0.34),
                primary.withValues(alpha: 0.14),
              ],
            );
          }
        }
      }
    },
  );

  for (final transition in [
    ('all', '1'),
    ('all', '2'),
    ('1', 'all'),
    ('1', '2'),
    ('2', 'all'),
    ('2', '1'),
  ]) {
    testWidgets(
      'filtro ${transition.$1} → ${transition.$2}: mismo ritmo y barra fija',
      (tester) async {
        await _montarLibreta(tester);
        final selector = find.byKey(const Key('document-gooey-year-selector'));
        await Scrollable.ensureVisible(
          tester.element(selector),
          alignment: 0.2,
        );
        await tester.pumpAndSettle();
        final origin = find.byKey(Key('document-filter-year-${transition.$1}'));
        final destination = find.byKey(
          Key('document-filter-year-${transition.$2}'),
        );
        await tester.tap(origin);
        await tester.pumpAndSettle();
        final selectorRect = tester.getRect(selector);
        final indicator = find.descendant(
          of: selector,
          matching: find.byKey(const Key('document-selector-indicator')),
        );
        final startX = tester.getCenter(indicator).dx;
        final targetX = tester.getCenter(destination).dx;
        final content = find.byKey(
          const Key('document-filter-content-opacity'),
        );
        await tester.tap(destination);
        await tester.pump();
        expect(tester.widget<Opacity>(content).opacity, 1);
        await tester.pump(const Duration(milliseconds: 80));
        final progress =
            (tester.getCenter(indicator).dx - startX) / (targetX - startX);
        expect(progress, closeTo(Curves.easeInOutCubic.transform(0.25), 0.001));
        expect(tester.widget<Opacity>(content).opacity, lessThan(1));
        expect(tester.getRect(selector), selectorRect);
        await tester.pump(const Duration(milliseconds: 32));
        expect(tester.widget<Opacity>(content).opacity, closeTo(0, 0.0001));
        expect(
          find.byKey(const Key('document-filter-content-opacity')),
          findsOneWidget,
        );
        expect(tester.getRect(selector), selectorRect);
        await tester.pump(const Duration(milliseconds: 48));
        expect(
          (tester.getCenter(indicator).dx - startX) / (targetX - startX),
          closeTo(Curves.easeInOutCubic.transform(0.5), 0.001),
        );
        expect(tester.widget<Opacity>(content).opacity, greaterThan(0));
        expect(tester.getRect(selector), selectorRect);
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.getCenter(indicator).dx, closeTo(targetX, 0.1));
        expect(tester.widget<Opacity>(content).opacity, 1);
        expect(tester.getRect(selector), selectorRect);
        final firstYear = find.byKey(
          const Key('document-subject-1-MATERIA PRIMER AÑO 0'),
        );
        final secondYear = find.byKey(
          const Key('document-subject-2-MATERIA SEGUNDO AÑO'),
        );
        expect(firstYear, transition.$2 == '2' ? findsNothing : findsOneWidget);
        expect(
          secondYear,
          transition.$2 == '1' ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'los toques rápidos conservan el último filtro sin mezclar listados',
    (tester) async {
      await _montarLibreta(tester);
      final selector = find.byKey(const Key('document-gooey-year-selector'));
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('document-filter-year-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final content = find.byKey(const Key('document-filter-content-opacity'));
      final previousOpacity = tester.widget<Opacity>(content).opacity;
      await tester.tap(find.byKey(const Key('document-filter-year-1')));
      await tester.pump();
      expect(tester.widget<Opacity>(content).opacity, previousOpacity);
      await tester.tap(find.byKey(const Key('document-filter-year-all')));
      await tester.pump();
      expect(tester.widget<Opacity>(content).opacity, previousOpacity);
      await tester.pumpAndSettle();
      final indicator = find.descendant(
        of: selector,
        matching: find.byKey(const Key('document-selector-indicator')),
      );
      expect(
        tester.getCenter(indicator).dx,
        closeTo(
          tester
              .getCenter(find.byKey(const Key('document-filter-year-all')))
              .dx,
          0.1,
        ),
      );
      expect(
        find.byKey(const Key('document-subject-1-MATERIA PRIMER AÑO 0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('document-subject-2-MATERIA SEGUNDO AÑO')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('document-filter-content-opacity')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('movimiento reducido aplica el filtro de inmediato', (
    tester,
  ) async {
    await _montarLibreta(tester, reducedMotion: true);
    await tester.ensureVisible(
      find.byKey(const Key('document-gooey-year-selector')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('document-filter-year-2')));
    await tester.pump();
    expect(
      find.byKey(const Key('document-subject-1-MATERIA PRIMER AÑO 0')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('document-subject-2-MATERIA SEGUNDO AÑO')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const Key('document-filter-content-opacity')),
          )
          .opacity,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtra pendientes y conserva el dock del PDF', (tester) async {
    var originalPdfCalls = 0;
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Theme(
            data: temaLaboratorioAtlassian(context),
            child: Scaffold(
              body: VistaDocumentoAcademicoNativo(
                documento: _situacionAcademica(),
              ),
              bottomNavigationBar: DockDocumentoAcademicoNativo(
                onCompartir: () {},
                onVerPdfOriginal: () => originalPdfCalls++,
                onAbrirExternamente: () {},
                reduceMotion: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('situación'), findsOneWidget);
    expect(find.text('académica'), findsOneWidget);
    expect(find.text('documento sage'), findsNothing);
    expect(
      find.text('vista reconstruida desde el PDF oficial de SAGE'),
      findsNothing,
    );
    expect(find.text('aprobadas'), findsWidgets);
    expect(find.text('cursando'), findsWidgets);
    expect(find.text('pendientes'), findsWidgets);
    expect(
      find.byKey(const Key('document-situation-scroll-stack')),
      findsOneWidget,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);

    final dockSurface = find.byKey(const Key('document-dock-surface'));
    expect(dockSurface, findsOneWidget);
    expect(tester.getSize(dockSurface).height, 66);
    expect(tester.getSize(dockSurface).width, lessThanOrEqualTo(316));
    expect(find.byKey(const Key('document-dock-ambient-glow')), findsOneWidget);

    final pdfIndicator = find.byKey(
      const ValueKey('document-action-indicator-pdf'),
    );
    expect(pdfIndicator, findsOneWidget);
    expect(tester.getSize(pdfIndicator).width, 20);

    final pdfIcon = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('document-action-icon-pdf')),
    );
    final pdfDecoration = pdfIcon.decoration! as BoxDecoration;
    expect(pdfDecoration.shape, BoxShape.circle);
    expect(pdfDecoration.gradient, isNotNull);

    final pdfAction = find.byKey(const Key('document-action-original-pdf'));
    await tester.tap(pdfAction);
    expect(originalPdfCalls, 1);

    final pendingFilter = find.byKey(
      const Key('document-filter-status-pending'),
    );
    await tester.ensureVisible(pendingFilter);
    await tester.tap(pendingFilter);
    await tester.pumpAndSettle();

    expect(find.text('Materia Aprobada'), findsNothing);
    expect(find.text('Materia Pendiente'), findsOneWidget);
    expect(find.text('pendiente'), findsWidgets);
  });

  for (final ancho in [320.0, 430.0, 700.0]) {
    testWidgets(
      'las cuatro acciones quedan centradas y simétricas a $ancho px',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(ancho, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DockDocumentoAcademicoNativo(
                onActualizar: () {},
                onCompartir: () {},
                onVerPdfOriginal: () {},
                onAbrirExternamente: () {},
                reduceMotion: true,
              ),
            ),
          ),
        );
        final superficie = tester.getRect(
          find.byKey(const Key('document-dock-surface')),
        );
        expect(superficie.center.dx, closeTo(ancho / 2, 0.1));
        final iconos = ['Actualizar', 'compartir', 'pdf', 'abrir']
            .map(
              (label) => tester.getRect(
                find.byKey(ValueKey('document-action-icon-$label')),
              ),
            )
            .toList();
        final etiquetas = [
          'Actualizar',
          'compartir',
          'pdf',
          'abrir',
        ].map((label) => tester.getRect(find.text(label))).toList();
        final distancia = iconos[1].center.dx - iconos[0].center.dx;
        for (var i = 0; i < iconos.length; i++) {
          expect(iconos[i].center.dy, closeTo(iconos.first.center.dy, 0.1));
          expect(
            etiquetas[i].center.dy,
            closeTo(etiquetas.first.center.dy, 0.1),
          );
          expect(etiquetas[i].center.dx, closeTo(iconos[i].center.dx, 0.1));
          if (i > 0) {
            expect(
              iconos[i].center.dx - iconos[i - 1].center.dx,
              closeTo(distancia, 0.1),
            );
          }
        }
        expect(
          (iconos.first.center.dx + iconos.last.center.dx) / 2,
          closeTo(superficie.center.dx, 0.1),
        );
        final indicador = tester.getRect(
          find.byKey(const ValueKey('document-action-indicator-pdf')),
        );
        expect(
          (iconos.first.top + indicador.bottom) / 2,
          closeTo(superficie.center.dy, 0.1),
        );
        final areaTactil = tester.getRect(
          find.byKey(const Key('document-action-update')),
        );
        expect(areaTactil.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ordena el analítico por nota y sale del carrusel por año', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Theme(
            data: temaLaboratorioAtlassian(context),
            child: Scaffold(
              body: VistaDocumentoAcademicoNativo(documento: _analitico()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('document-analytic-year-carousel')),
      findsOneWidget,
    );
    expect(find.text('primer registro'), findsOneWidget);
    expect(find.text('primera aprobación'), findsNothing);

    final gradeSort = find.byKey(const Key('document-sort-grade'));
    await tester.ensureVisible(gradeSort);
    await tester.tap(gradeSort);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('document-analytic-year-carousel')),
      findsNothing,
    );
    expect(find.byIcon(Icons.north_east_rounded), findsNothing);

    final high = find.text('Materia Nota Diez');
    final low = find.text('Materia Nota Siete');
    expect(high, findsOneWidget);
    expect(low, findsOneWidget);
    final highOffset = tester.getTopLeft(high);
    final lowOffset = tester.getTopLeft(low);
    final highComesFirst =
        highOffset.dy < lowOffset.dy ||
        ((highOffset.dy - lowOffset.dy).abs() < 1 &&
            highOffset.dx < lowOffset.dx);
    expect(highComesFirst, isTrue);
  });

  testWidgets('respeta el margen superior para el botón flotante', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VistaDocumentoAcademicoNativo(
            documento: _analitico(),
            topPadding: 120,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('certificado');
    expect(title, findsOneWidget);
    expect(tester.getTopLeft(title).dy, greaterThanOrEqualTo(120));
  });

  testWidgets('situación académica no desborda en un teléfono angosto', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.15)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Theme(
            data: temaLaboratorioAtlassian(context),
            child: Scaffold(
              body: VistaDocumentoAcademicoNativo(
                documento: _situacionAcademica(),
              ),
              bottomNavigationBar: DockDocumentoAcademicoNativo(
                onCompartir: () {},
                onVerPdfOriginal: () {},
                onAbrirExternamente: () {},
                reduceMotion: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

DocumentoAcademicoPdf _situacionAcademica() {
  return const DocumentoAcademicoPdf(
    tipo: TipoDocumentoAcademicoPdf.situacionAcademica,
    alumno: 'PERSONA DE PRUEBA',
    documento: '00000000',
    establecimiento: 'INSTITUTO DE PRUEBA',
    carrera: 'PROFESORADO DE PRUEBA',
    fechaEmision: '21/8/2026',
    condicionAlumno: 'REGULAR',
    materias: <MateriaDocumentoAcademicoPdf>[
      MateriaDocumentoAcademicoPdf(
        nombre: 'MATERIA APROBADA',
        anio: 1,
        estado: 'Aprobada',
        fechaMovimiento: '17/11/2025',
        nota: '8.00',
      ),
      MateriaDocumentoAcademicoPdf(
        nombre: 'MATERIA EN CURSO',
        anio: 3,
        estado: 'Cursando',
        fechaMovimiento: '17/03/2026',
      ),
      MateriaDocumentoAcademicoPdf(nombre: 'MATERIA PENDIENTE', anio: 4),
    ],
  );
}

DocumentoAcademicoPdf _analitico() {
  return const DocumentoAcademicoPdf(
    tipo: TipoDocumentoAcademicoPdf.analitico,
    alumno: 'PERSONA DE PRUEBA',
    documento: '00000000',
    establecimiento: 'INSTITUTO DE PRUEBA',
    carrera: 'PROFESORADO DE PRUEBA',
    fechaEmision: '21/8/2026',
    condicionAlumno: 'REGULAR',
    promedioOficial: '8.50',
    materias: <MateriaDocumentoAcademicoPdf>[
      MateriaDocumentoAcademicoPdf(
        nombre: 'MATERIA NOTA SIETE',
        anio: 1,
        estado: 'Aprobada',
        fechaMovimiento: '17/11/2025',
        nota: '7.00',
      ),
      MateriaDocumentoAcademicoPdf(
        nombre: 'MATERIA NOTA DIEZ',
        anio: 2,
        estado: 'Aprobada',
        fechaMovimiento: '18/12/2025',
        nota: '10.00',
      ),
    ],
  );
}

Future<void> _montarLibreta(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 920));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  final document = DocumentoAcademicoPdf(
    tipo: TipoDocumentoAcademicoPdf.libreta,
    alumno: 'PERSONA DE PRUEBA',
    carrera: 'PROFESORADO DE PRUEBA',
    materias: [
      for (var i = 0; i < 12; i++)
        MateriaDocumentoAcademicoPdf(
          nombre: 'MATERIA PRIMER AÑO $i',
          anio: 1,
          estado: 'Aprobada',
          nota: '8.00',
        ),
      const MateriaDocumentoAcademicoPdf(
        nombre: 'MATERIA SEGUNDO AÑO',
        anio: 2,
        estado: 'Aprobada',
        nota: '10.00',
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(body: VistaDocumentoAcademicoNativo(documento: document)),
    ),
  );
  await tester.pumpAndSettle();
}

double _contraste(Color foreground, Color background) {
  final visible = Color.alphaBlend(foreground, background);
  final first = visible.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
