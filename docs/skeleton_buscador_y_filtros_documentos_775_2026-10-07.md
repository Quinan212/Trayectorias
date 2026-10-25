# Skeleton del buscador y filtros de documentos — +775

El menú de búsqueda muestra su contenido como skeleton durante 2 segundos en cada apertura. La barra compartida y la flecha de volver quedan disponibles; escribir no reinicia el plazo. El efecto reutiliza skeletonizer y conserva la identidad, el scroll y las posiciones del contenido al terminar. La espera se cancela al salir. Con movimiento reducido se usan placeholders estáticos.

Los filtros de año, estado y orden de los documentos nativos comparten un único controlador de 320 ms. La selección se desliza y se estira suavemente; las etiquetas siguen el mismo avance. El listado anterior desaparece antes de reemplazarse y el nuevo aparece con un pequeño desplazamiento vertical. Siempre se dibuja un solo listado. Se conserva altura suficiente para que acortar las materias no desplace el selector por un ajuste del scroll. Las pulsaciones rápidas conservan el último filtro solicitado. Con movimiento reducido el cambio es inmediato.

Se mantienen las correcciones de navegación y de la barra de búsqueda, la caché persistente por usuario de los tres documentos, el dock inferior y la sincronización de SAGE. Versión: `1.3.071026+775`.

## Validación

- 182 pruebas aprobadas en documentos, Libreta, buscador, navegación, movimiento y sincronización SAGE.
- Se verificaron los seis recorridos entre todos, primer año y segundo año: igual avance a los mismos tiempos, opacidad sincronizada, un único listado y rectángulo del selector fijo.
- Se verificaron pulsaciones rápidas, movimiento reducido, escritura durante la entrada skeleton y salida antes de terminar la espera.
- Análisis general ejecutado sin errores. Se corrigieron las dos advertencias generadas por retirar las animaciones anteriores; el análisis final de la vista y sus pruebas conserva solo 10 avisos informativos preexistentes.

## Archivos revisados

- `lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart`
- `lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart`
- `test/laboratorio_atlassian/busqueda_global_react_developer_test.dart`
- `test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart`
- `test/laboratorio_atlassian/modo_claro_react_developer_test.dart`
- `test/documentos_pdf/vista_documento_academico_nativo_test.dart`
- Este informe.

Los archivos existentes se leyeron como UTF-8 antes de editar y se respaldaron. Se conservaron los saltos de línea LF y se revisaron los textos visibles. La auditoría está en `build/qa/775_skeleton_filtros_utf8.json`.

## Release instalado y comprobación visual

Se compiló e instaló el release en `emulator-5556` conservando los datos mediante `adb install -r`. La versión instalada sigue siendo `1.3.071026+775`, con el mismo certificado del proyecto. La actualización quedó registrada a las 05:23:51 de Argentina del 7 de octubre de 2026.

APK: `build/releases/Trayectorias-1.3.071026-775-skeleton-filtros-emulador-release.apk`.
SHA-256: `F451765D86DA64DBD951B0FCAD2FEC0EC6D3058F9E80E65D0AB296FA93964BD1`.

Se inspeccionaron las capturas del menú a los 1123 ms y 3172 ms desde el toque: el skeleton aparece, luego se muestra el menú actual, con la misma barra y geometría. Se abrió la Libreta real desde su copia local y se probaron todos → segundo → primero → todos. La opción seleccionada fue correcta y los tres botones conservaron exactamente sus límites en cada cambio. Las capturas y mediciones están en `build/qa/775_skeleton_emulador.json` y `build/qa/775_filtros_emulador.json`.

Los tres índices de documentos persistentes conservaron sus hashes después de instalar. Se guardó el estado actualizado del emulador en `default_boot` para la próxima apertura. La app queda en la Libreta con el filtro todos.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
