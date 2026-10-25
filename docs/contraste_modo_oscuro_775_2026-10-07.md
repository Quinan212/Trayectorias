# Contraste del modo oscuro — +775

Se corrigió el alcance de la solicitud: el modo claro volvió a sus colores originales y la mejora de contraste se aplicó al modo oscuro. El informe anterior de contraste claro registra una versión previa, ahora reemplazada por esta corrección.

Los fondos oscuros usan tonos azulados con superficies diferenciadas para los paneles y las tarjetas interiores. Los textos secundarios son más claros. La barra inferior utiliza un fondo oscuro opaco, bordes definidos y un azul claro para el icono, la etiqueta y el indicador del PDF seleccionado. Los estados académicos emplean colores claros de verde, azul, ámbar y violeta para mantener su legibilidad.

Se restauraron las constantes y transparencias originales del modo claro, incluyendo la barra y el botón PDF. La pantalla principal es idéntica al respaldo anterior a la modificación clara. No se cambió la navegación, la geometría de la barra de documentos, el controlador de las animaciones, el skeleton ni la lógica de SAGE. La versión continúa siendo `1.3.071026+775`.

## Validación

- 191 pruebas aprobadas en documentos, Libreta, buscador, navegación, movimiento, sincronización y temas.
- Contraste mínimo de 4,5:1 comprobado en las acciones activas de la barra oscura, el icono PDF y los nombres y estados de las tarjetas verificadas: aprobada, cursando, regular, pendiente y otro estado.
- Pruebas de regresión para los colores originales de la paleta clara, sus superficies y el PDF activo y deshabilitado. Se comprobaron también los fondos oscuros opacos y la legibilidad del texto secundario.
- Se mantuvo la altura de 66 px y las pruebas de simetría de la barra. Las pruebas anteriores de filtros y navegación continúan pasando.
- `flutter analyze`: cero errores, 40 advertencias y 479 avisos informativos preexistentes. La comparación de diagnósticos con la validación anterior no encontró incorporaciones.
- Compilación release Android x64 correcta, destinada al emulador.

Se revisaron visualmente el inicio oscuro, la Situación académica real y el panel de materias pendientes de cuarto año. Se verificaron los textos con tildes, la eñe y el símbolo de año. También se comprobó en pantalla la restauración del modo claro. Las capturas están en `build/qa/775_oscuro_*` y `build/qa/775_claro_restaurado.png`.

## Release instalado

Se instaló mediante `adb install -r` en `emulator-5556` conservando los datos. Android confirma `versionCode=775`, `versionName=1.3.071026` y la instalación del 7 de octubre de 2026 a las 05:58:58 de Argentina (08:58:58 GMT del dispositivo).

APK: `build/releases/Trayectorias-1.3.071026-775-contraste-oscuro-emulador-release.apk`.
Tamaño: 36.562.464 bytes.
SHA-256: `0296C17D831B88F676804FDF9FCC29E9FA75357788503F5BC8C0FA67E207ACCB`.
Certificado SHA-256: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`, el mismo del proyecto.

Los tres índices persistentes de documentos conservaron sus hashes después de instalar. La Situación académica se abrió desde su copia local. Se guardó `default_boot` con el release actualizado. El emulador quedó en modo oscuro mostrando el panel de pendientes.

## Archivos revisados

- `lib/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart`
- `lib/funcionalidades/laboratorio_atlassian/tema/tema_react_developer.dart`
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart`
- `lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart`
- `test/laboratorio_atlassian/modo_claro_react_developer_test.dart`
- `test/documentos_pdf/vista_documento_academico_nativo_test.dart`
- Este informe.

Los seis archivos existentes se leyeron como UTF-8 antes de editar y se respaldaron; no presentaban corrupción preexistente. Se conservaron los saltos de línea LF. La auditoría está en `build/qa/775_contraste_oscuro_utf8.json`; los logs de pruebas, análisis y compilación están en `build/qa/775_contraste_oscuro_*`.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
