import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la marca visible de la aplicación es Trayectorias', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync(encoding: utf8);
    final mainSource = File('lib/main.dart').readAsStringSync(encoding: utf8);
    final pubspec = File('pubspec.yaml').readAsStringSync(encoding: utf8);
    final reactHome = File(
      'lib/funcionalidades/laboratorio_atlassian/pantallas/'
      'pantalla_inicio_react_developer.dart',
    ).readAsStringSync(encoding: utf8);
    final reactSearch = File(
      'lib/funcionalidades/laboratorio_atlassian/busqueda/'
      'pantalla_busqueda_global_react_developer.dart',
    ).readAsStringSync(encoding: utf8);
    final barra = File(
      'lib/compartido/navegacion/barra_busqueda_app.dart',
    ).readAsStringSync(encoding: utf8);

    expect(manifest, contains('android:label="Trayectorias"'));
    expect(mainSource, contains("title: 'Trayectorias'"));
    expect(pubspec, contains('display_name: Trayectorias'));
    expect(reactHome, contains('BarraBusquedaApp('));
    expect(reactSearch, contains('BarraBusquedaApp('));
    expect(barra, contains('Buscar en Trayectorias…'));

    // Los identificadores técnicos se conservan para no romper instalaciones.
    expect(pubspec, contains('name: correlativas_historia'));
    expect(manifest, contains('package="ar.maillet.correlativas_historia"'));
  });
}
