import 'package:correlativas_historia/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart';
import 'package:correlativas_historia/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el Drawer móvil sigue el tema claro y oscuro', (tester) async {
    await tester.pumpWidget(_app(TemaApp.light()));

    final drawerClaro = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawerClaro.backgroundColor, TemaApp.light().colorScheme.surface);

    await tester.pumpWidget(_app(TemaApp.dark()));
    // MaterialApp interpola el tema: verificamos el color final.
    await tester.pumpAndSettle();

    final drawerOscuro = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawerOscuro.backgroundColor, TemaApp.dark().colorScheme.surface);
  });
}

Widget _app(ThemeData theme) {
  return MaterialApp(
    theme: theme,
    home: DrawerMovilAtlassian(
      selectedIndex: 3,
      onSelected: (_) {},
      onSearch: () {},
    ),
  );
}
