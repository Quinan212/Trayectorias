# Contraste del modo claro — +775

Se mejoró el contraste del modo claro en la barra inferior, los fondos generales, los paneles y las tarjetas. Los textos secundarios y los bordes tienen mayor definición; las superficies claras separan los controles del contenido que queda detrás. El botón PDF utiliza un azul más oscuro sobre un fondo claro. Los estados académicos conservan sus categorías y tienen colores legibles sobre las tarjetas.

La paleta del modo oscuro se conserva. No se modificaron los recorridos del buscador, las animaciones sincronizadas, la entrada skeleton ni la lógica de sincronización y almacenamiento de SAGE. La versión continúa en `1.3.071026+775`.

## Validación

- 191 pruebas aprobadas: documentos académicos, Libreta, buscador, navegación, movimiento, sincronización SAGE y temas.
- Se comprobó contraste mínimo de 4,5:1 en las etiquetas e iconos activos de la barra inferior y los textos académicos de las tarjetas verificadas. Se comprobaron los colores originales del botón PDF en modo oscuro, incluyendo el indicador deshabilitado.
- Se conservó la altura de 66 px de la barra. Las pruebas anteriores de geometría, filtros, pulsaciones rápidas, movimiento reducido y navegación siguen pasando.
- El test del cambio de tema del drawer ahora espera a que termine la interpolación del tema antes de comprobar el color final. Es un ajuste del test; no cambia el comportamiento del producto.
- `flutter analyze` general: cero errores, 40 advertencias y 479 avisos informativos preexistentes. No se incorporaron diagnósticos nuevos respecto de la validación anterior.
- Compilación release correcta para el emulador Android x64.

Se revisaron en pantalla el inicio y la Situación académica real, incluyendo las tarjetas pendientes de cuarto año y la barra inferior. Se observaron correctamente los textos con tildes y el símbolo de año. La app quedó en modo claro mostrando el documento para que pueda revisarse.

## Release instalado

Se instaló con `adb install -r` en `emulator-5556`, conservando los datos. Android confirma `versionCode=775` y `versionName=1.3.071026`. La instalación se registró el 7 de octubre de 2026 a las 05:35:21 de Argentina (08:35:21 GMT en el dispositivo).

APK: `build/releases/Trayectorias-1.3.071026-775-contraste-claro-emulador-release.apk`.
Tamaño: 36.562.464 bytes.
SHA-256: `978D40F55C550630FCAFECA6DAAC781A84AA5D1708541C0E5D173263A2AC15AD`.
Certificado SHA-256: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b` (el mismo del proyecto).

Los tres índices persistentes de documentos conservaron sus hashes después de instalar. La Situación académica se abrió desde su copia guardada. Se guardó el estado del emulador en `default_boot` con el release actualizado y el modo claro. Este APK es la compilación destinada al emulador.

## Archivos revisados

- `lib/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart`
- `lib/funcionalidades/laboratorio_atlassian/tema/tema_react_developer.dart`
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart`
- `lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart`
- `test/laboratorio_atlassian/modo_claro_react_developer_test.dart`
- `test/documentos_pdf/vista_documento_academico_nativo_test.dart`
- `test/tema/drawer_movil_tema_test.dart`
- Este informe.

Se leyeron los archivos existentes como UTF-8 antes de editar, se registró la ausencia de corrupción y se hicieron respaldos. Se conservaron sus saltos de línea LF. La auditoría final está en `build/qa/775_contraste_claro_utf8.json`; los logs de análisis, pruebas y compilación y las capturas están en `build/qa/775_contraste_claro_*` y `build/qa/775_claro_*`.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
