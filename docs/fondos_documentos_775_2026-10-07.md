# Fondos de los documentos académicos — +775

Se restauró el tema general de la aplicación al estado previo a los cambios de contraste. `tema_atlassian.dart` y `tema_react_developer.dart` son idénticos, byte por byte, a sus respaldos anteriores. Los fondos de Inicio, buscador y demás pantallas vuelven a sus colores originales, tanto en claro como en oscuro.

Los ajustes visuales quedan limitados al modo oscuro de las vistas de Situación académica, Analítico y Libreta. Se recuperaron los degradados y transparencias originales de los paneles. Las tarjetas compactas de materias comparten el fondo del panel en lugar de dibujar una segunda superficie opaca. Sus bordes son más suaves. La barra inferior usa un degradado oscuro translúcido y un brillo discreto; el icono y la etiqueta PDF conservan el azul claro que mejora su lectura. Se conservaron los colores legibles de los estados académicos.

El modo claro de los documentos conserva su paleta original. No se modificaron los recorridos, las posiciones, el ritmo de las animaciones, el skeleton ni la sincronización y la caché de SAGE. Versión: `1.3.071026+775`.

## Validación

- 191 pruebas aprobadas en documentos, Libreta, buscador, navegación, movimiento, sincronización SAGE y temas.
- Contraste de al menos 4,5:1 comprobado para los textos activos de la barra y el icono PDF, componiendo las transparencias sobre fondos negros, blancos y azules.
- Nombres y estados académicos comprobados sobre los colores reales del panel, con las materias transparentes: aprobada, cursando, regular, pendiente y otro estado.
- Se conservan las pruebas de geometría y simetría de la barra de 66 px, los filtros sincronizados, las pulsaciones rápidas y el movimiento reducido.
- `flutter analyze`: cero errores, 40 advertencias y 479 avisos informativos preexistentes. La comparación con el análisis anterior no encontró diagnósticos nuevos.
- Compilación release Android x64 correcta, destinada al emulador.

Se inspeccionaron el Inicio restaurado y los tres documentos reales en el emulador. Las capturas de Situación académica, Analítico y Libreta muestran los fondos con degradados y la barra compartida. Se revisaron en pantalla las palabras con tildes, la eñe y el símbolo de año. Evidencia: `build/qa/775_vidrio_home.png`, `build/qa/775_vidrio_pendientes.png`, `build/qa/775_vidrio_analitico.png` y `build/qa/775_vidrio_libreta.png`.

## Release instalado

APK: `build/releases/Trayectorias-1.3.071026-775-documentos-vidrio-emulador-release.apk`.
Tamaño: 36.562.464 bytes.
SHA-256: `3D564B84B59DCEA480E4C9970F2ED4F1702A2016CD2E678360798C19C54867CB`.
Certificado SHA-256: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`, el mismo del proyecto.

Se instaló con `adb install -r` en `emulator-5556` conservando los datos. Android confirma `versionCode=775`, `versionName=1.3.071026` y la instalación del 7 de octubre de 2026 a las 06:06:54 de Argentina (09:06:54 GMT del dispositivo).

Los tres documentos se abrieron desde sus copias guardadas. Sus índices persistentes conservaron los hashes después de instalar y recorrer las pantallas. El estado se guardó en `default_boot`. El emulador quedó en la Libreta, en modo oscuro, mostrando las materias y la barra inferior.

## Archivos revisados

- `lib/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart` (restaurado).
- `lib/funcionalidades/laboratorio_atlassian/tema/tema_react_developer.dart` (restaurado).
- `lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart` (ajustes limitados a los documentos).
- `test/laboratorio_atlassian/modo_claro_react_developer_test.dart` (restaurado).
- `test/documentos_pdf/vista_documento_academico_nativo_test.dart` (contraste con superficies translúcidas).
- Este informe.

Los cinco archivos existentes se leyeron como UTF-8 antes de editar y se respaldaron. No se encontró corrupción preexistente. Se conservaron los saltos de línea LF. Auditoría: `build/qa/775_fondos_vidrio_utf8.json`. Los logs de pruebas, análisis y compilación están en `build/qa/775_fondos_vidrio_*`.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
