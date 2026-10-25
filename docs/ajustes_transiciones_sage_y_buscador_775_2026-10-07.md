# Ajustes de transiciones de SAGE y retorno del buscador — 07/10/2026

Versión solicitada: `1.3.071026+775`. El APK instalado informa `versionName=1.3.071026` y `versionCode=775`, sin el desplazamiento de códigos de los APK divididos por ABI.

## Cambios

- La pantalla nativa de SAGE mantiene un único contenido durante el cambio de mensajes. Sale el mensaje anterior, se aplica el estado más reciente y entra el nuevo. Las actualizaciones intermedias no se acumulan ni se superponen.
- El texto, el riel de cuatro pasos, los metadatos y la barra de progreso reciben el mismo estado visible. El área de texto conserva su posición y tamaño; actualizar solamente el porcentaje no reinicia la transición.
- El formulario y el progreso también cambian sin montar dos paneles a la vez. Se conserva la contraseña hasta la aceptación de la sesión y se respeta el movimiento reducido.
- Al terminar la salida del buscador se renuevan sus Hero retenidos, incluyendo los de secciones que quedaron fuera de pantalla. Esto restablece la barra al regresar desde el resultado a Inicio. La restauración ocurre después de completar el vuelo.

## Validación

Las pruebas reprodujeron ambos fallos antes de las correcciones: varios mensajes montados simultáneamente en SAGE y ninguna superficie Material visible de la barra tras búsqueda → Calendario → Inicio.

Pasaron 90 pruebas de `sage_sincronizacion`, `laboratorio_atlassian` y `movimiento`. Cubren cambios rápidos de mensajes y formulario, avance numérico, movimiento reducido, conservación de contraseña, reutilización de sesión, skeletons y ocho recorridos de búsqueda React/Atlassian hacia Exámenes, Plan, Calendario y Ayuda. Los recorridos comprueban la barra al regresar y permiten abrir y cerrar nuevamente el buscador.

También pasaron las diez pruebas del stepper con la captura visual. Se revisó `build/qa/sage_775_paso_en_transicion.png`, con tildes e iconos correctos y un solo mensaje del paso activo.

`flutter analyze --no-pub`: 0 errores, 40 advertencias preexistentes y 478 observaciones. No se añadieron errores ni advertencias. La verificación automatizada de SAGE utiliza una WebView simulada; no se utilizó una credencial real para ejecutar el recorrido completo en esta revisión.

## Instalación local

APK: `build/releases/Trayectorias-1.3.071026-775-emulador-release.apk`. Tamaño: 36.562.592 bytes. Motor Flutter compilado para x86_64; esta entrega está destinada al emulador.

Firma verificada con el certificado del proyecto. Instalado y abierto en `Recorridos_API_36`, `emulator-5556`, conservando los datos mediante una actualización con la misma firma. Como el código solicitado 775 es inferior al código de la instalación anterior, se permitió la instalación de esa versión en el emulador de pruebas. Respaldo anterior disponible en el snapshot `antes_release_775_20261007`.

Se verificó en Android la versión 775, la arquitectura x86_64 y la ausencia de la marca DEBUGGABLE. El inicio terminó correctamente, sin errores registrados por AndroidRuntime o Flutter. Captura: `build/qa/emulador_release_775.png`.

No se subieron archivos a Drive ni a Google Play.

## Archivos revisados como UTF-8

1. `lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sincronizacion_sage_automatica.dart`
2. `lib/compartido/navegacion/barra_busqueda_app.dart`
3. `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart`
4. `test/sage_sincronizacion/stepper_sincronizacion_sage_test.dart`
5. `test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart`
6. `pubspec.yaml`
7. Este documento.

Los seis archivos existentes tenían UTF-8 válido sin BOM, saltos LF y ninguna secuencia sospechosa antes del cambio. Hay respaldos exactos en `build/qa/respaldo_transiciones_sage_20261007`. Se conservaron la codificación y los saltos de línea. Todos los archivos modificados se reabrieron como UTF-8 estricto y se buscaron las secuencias sospechosas exigidas por AGENTS.md.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
