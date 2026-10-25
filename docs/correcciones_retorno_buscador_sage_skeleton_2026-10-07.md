# Correcciones del retorno, la sesión de SAGE y los skeletons

Revisión del 7 de octubre de 2026, posterior al primer APK entregado por Drive.

## Buscador

Se conserva la entrada desde Inicio: la barra sigue subiendo mediante el mismo Hero y la página conserva su transición. La corrección del regreso mantiene fijo el origen, conserva la altura y el espacio de los iconos, y cambia la consulta a la etiqueta durante el vuelo.

La reproducción mostró que, con un teclado de 300 píxeles y un margen inferior de 24, la barra de Inicio pasaba de `top=884` a `top=608`, además de desplazarse horizontalmente por la animación de la página anterior. Inicio ya no reduce su superficie por el teclado de la búsqueda. Los dos accesos conservan el margen inferior del dispositivo al cerrar el teclado, y la ruta de búsqueda no desplaza la página anterior.

Las pruebas recorren el regreso cuadro por cuadro desde Inicio y Exámenes. Comprueban un único vuelo, altura constante de 60, descenso continuo, posición final idéntica al origen y cierre del campo editable. Los recorridos hacia Exámenes, Plan, Calendario y Ayuda siguen preparando el destino antes de cerrar la búsqueda y no muestran Inicio durante esa salida.

## SAGE

Una señal aislada de login ya no devuelve la sincronización al formulario nativo. Se comprueban la URL actual, el formulario visible, el documento terminado y la ausencia de una sesión aceptada. Las lecturas se invalidan si cambian la página o el recorrido mientras esperan una respuesta.

Un formulario inicial requiere varias observaciones y estabilidad. Cuando hubo una sesión aceptada en esta pantalla, o existe una sesión confirmada previamente, se esperan cinco segundos de login estable antes de pedir volver a ingresar. El estado guardado da margen a una redirección; el acceso real continúa comprobándose en SAGE.

Mientras se confirma una pérdida de sesión, se conserva el progreso. La comprobación tiene un límite de treinta segundos y pausa el vigilante de recuperación para que ambos mecanismos no recarguen el portal al mismo tiempo. Una sesión vencida confirmada sí vuelve a permitir el ingreso. La vigilancia de bloqueos se reanuda cuando la sesión vuelve a estar activa.

La contraseña del formulario se conserva hasta aceptar el acceso. Antes se limpiaba al terminar el envío, aunque SAGE todavía estuviera autenticando. Las señales de envío antiguas no reinician la comprobación de un acceso que ya fue aceptado.

La comprobación se aplica también al acceso al portal y a Situación académica, Analítico y Libreta. Las pruebas de los tres documentos verifican la reutilización de sesión sin otro envío de credenciales ni borrado de cookies. La sincronización completa sigue disponible para actualizar las notas y la trayectoria.

## Skeletons

Los efectos existentes de calendario y exámenes se conservan. El problema estaba en la condición de carga: una actualización conservaba los datos anteriores y, por ello, omitía el skeleton. Ahora se muestra durante la consulta inicial y durante una actualización real, hasta que termina la nueva petición.

Se reutilizan las superficies existentes de `Skeletonizer`. La caché continúa permitiendo volver a una pantalla que ya tiene datos sin forzar una consulta adicional. Las pruebas comprueban carga, actualización con datos anteriores y desaparición del skeleton al completar la respuesta.

## Validación

- 116 pruebas del tramo afectado aprobadas, incluyendo navegación, SAGE, documentos, skeletons y actualización compartida de mesas.
- 46 pruebas de cierre aprobadas después del último refuerzo, incluyendo la recuperación a los cinco segundos tras un login transitorio.
- Dos comprobaciones adicionales del regreso verifican en cada cuadro una única superficie visible y la posición fija del acceso de Inicio o Exámenes durante la animación y el cierre del teclado.
- `flutter analyze`: 0 errores, 40 advertencias y 479 avisos informativos, igual que la referencia anterior. El detalle está en `build/qa/retorno_validacion_analyze_cierre.log`.
- Se inspeccionaron capturas renderizadas del regreso del buscador y de los skeletons de Exámenes y Calendario, sin abrir ventanas.
- Los logs están en `build/qa/retorno_sage_buscador_skeleton_validacion.log` y `build/qa/retorno_cierre_pruebas.log`.
- La verificación utiliza WebView y servidor simulados. La sesión real y la fluidez en el A35 quedan para comprobar en el teléfono.

## Archivos revisados

Fuentes: `barra_busqueda_app.dart`, `pantalla_inicio_react_developer.dart`, `pantalla_laboratorio_atlassian.dart`, `pantalla_calendario_atlassian.dart`, `pantalla_examenes_atlassian.dart`, `pantalla_sage_laboratorio.dart` y `pantalla_sincronizacion_sage_automatica.dart`.

Pruebas: `trayectoria_compartida_y_recorridos_test.dart`, `recuperacion_webview_sage_test.dart` y `stepper_sincronizacion_sage_test.dart`. También se incrementó el código de compilación en `pubspec.yaml`.

Los archivos existentes se respaldaron y se comprobaron antes de editar. La revisión final de UTF-8 y secuencias sospechosas se registra en `build/qa/retorno_validacion_utf8_final.json`.

## APK actualizado

Se compiló el APK release ARM64 para el A35 y se verificó su firma. Coincide con el certificado público de la llave del proyecto. Conserva el paquete `ar.maillet.correlativas_historia`, usa SDK mínimo 24 y objetivo 36 y no declara la aplicación depurable.

Versión visible: `1.3.071026`. Código base: `1791257544`. Código real de la variante ARM64: `1791259544`, superior al APK anterior. Tamaño: 34.701.662 bytes, 33,1 MiB.

SHA-256: `94BA864B59CFE1D1961639CC6F571716ED943618D9C7395A9821FCE41E16AD50`.

Se entregó como [Trayectorias-1.3.071026-A35-correccion-2-release.apk](https://drive.google.com/file/d/1h5Eq71IvVzH-UTEP79lQh_C59o3UoNku/view?usp=drivesdk). Una lectura posterior de Drive confirmó nombre y tamaño completo de 34.701.662 bytes en la misma carpeta de las entregas anteriores. No se cambió la configuración de acceso de Drive.

La copia local está en `build/releases/Trayectorias-1.3.071026-A35-correccion-2-release.apk`. Los registros de compilación, firma y entrega están en `build/qa/retorno_sage_buscador_apk_release.log`, `build/qa/retorno_apk_firma.log`, `build/qa/retorno_apk_verificacion.json` y `build/qa/retorno_drive_subida.json`.

Estas correcciones están en el APK entregado. Esta revisión no incluyó una nueva publicación en Google Play ni la inspección de la versión instalada en el teléfono.
