# Optimización de la WebView de SAGE — +775

Fecha: 7 de octubre de 2026. Versión: `1.3.071026+775`, código Android `775`.

## Cambios localizados

- `lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart`: diagnósticos y canal de diagnóstico exclusivos del modo debug; consultas de navegación e historial serializadas; ráfagas de eventos agrupadas con separación mínima de 500 ms; instalación de observadores reutilizada por revisión de página y revalidada ante cambios de iframes; sondeo de respaldo cada 15 segundos en pantallas nativas quietas y cada 2 segundos durante el trabajo; suspensión de los sondeos y comprobaciones de acceso cuando la ruta queda tapada o la app pasa al fondo. Se conserva la vigilancia de cinco segundos durante la sincronización activa.
- `lib/funcionalidades/trayectoria_sage_laboratorio/sage/actividad_webview_sage.dart`: pausa/reanudación dirigida a la vista de SAGE y serializada; liberación única al cerrar; respuestas nativas fallidas o tardías no rompen el recorrido.
- `android/app/src/main/kotlin/ar/maillet/correlativas_historia/MainActivity.kt`: canal dirigido al identificador público de la WebView. Al cerrar detiene la carga y descarga el DOM mediante `about:blank`, conservando las cookies. Flutter sigue a cargo de disponer la vista.
- `test/sage_sincronizacion/recuperacion_webview_sage_test.dart`: prueba de ráfagas de eventos durante lecturas bloqueadas, observadores reutilizados y actualizados, sondeo de 15 segundos con respuesta rápida a cambios, suspensión al tapar la ruta o pasar al fondo, y reanudación de la vigilancia sin perder cookies.
- `test/sage_sincronizacion/actividad_webview_sage_test.dart`: identificador correcto, deduplicación, orden de pausa/reanudación/liberación, reintento ante vista todavía no registrada y tolerancia a complemento ausente o error nativo.

Los archivos del buscador, fondos, transiciones y almacenamiento de los documentos no se modificaron en este trabajo. Respaldo exacto anterior en `build/qa/respaldo_rendimiento_webview_775_20261007`.

## Validación

Suite amplia: **203 pruebas aprobadas** en documentos PDF y su persistencia, Libreta, buscador y recorridos, movimiento, sincronización y temas. Tras el último ajuste que evita pausar la vista durante una lectura activa: **38 pruebas de SAGE aprobadas**. Registros: `build/qa/775_webview_regresion_tests.log` y `build/qa/775_webview_sage_final_tests.log`.

`flutter analyze --no-pub`: **0 errores, 40 advertencias y 479 recomendaciones preexistentes; 0 diagnósticos nuevos** frente a `775_busqueda_negra_delay_analyze.log`. Registro final: `build/qa/775_webview_analyze_final.log`.

Compilaciones release separadas para x86_64 y ARM64, sin incrementar el código Android por ABI. Verificación del APK: el marcador del código que instalaba los temporizadores de diagnóstico (`__sageReportDiagnosticsV1`) está ausente, y siguen presentes los puentes de captura de documentos y navegación.

Firma SHA-256 del certificado: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`.

## Comprobación en el emulador

Emulador: `emulator-5556`, Recorridos_API_36. Instalación con conservación de datos.

1. Wi-Fi y datos móviles desactivados: Situación académica, Analítico y Libreta abrieron desde las copias guardadas, sin pantalla de acceso o sincronización. En este recorrido `dumpsys meminfo` informó **0 WebViews**.
2. Reinicio completo del proceso sin conexión: Libreta siguió disponible.
3. Actualización con sesión vencida e intento de acceso fallido: al cancelar volvió a la copia anterior. Los tres índices persistentes mantuvieron sus hashes anteriores.
4. Ingreso correcto: SAGE pasó al perfil y legajo y descargó una nueva Libreta. Se conservan las tres copias y cambió solamente el índice correspondiente.
5. Nueva apertura de SAGE para actualizar Analítico: se mostró **«Sesión reutilizada»**, se completó la actualización sin reingresar las credenciales y cambió el segundo índice correspondiente. Las versiones anteriores siguen disponibles en el repositorio.
6. Se restauraron Wi-Fi y datos móviles y se dejó el emulador en Inicio. Instantánea `default_boot` guardada.

Las credenciales de prueba se habían interpretado inicialmente en orden inverso. La página oficial de SAGE confirmó que el usuario es el DNI; la prueba final usó el orden correcto. No se modificaron las credenciales ni el mecanismo de autenticación para resolver esa confusión.

Evidencia local: XML y capturas con prefijo `775_webview_` en `build/qa`; contiene datos de la cuenta de prueba y no forma parte del APK.

## Entrega

APK ARM64: `build/releases/Trayectorias-1.3.071026-775-webview-optimizada-arm64-release.apk`, **34.936.918 bytes**. SHA-256: `b08b2c4db5c528e0a7decc43cc8fe59e54c35374b0f6b85f511934c0efea3a85`.

APK del emulador: `build/releases/Trayectorias-1.3.071026-775-webview-optimizada-emulador-release.apk`, **36.562.464 bytes**. SHA-256: `d8b0ec0de465a8f88c9d7863159a1a5465edf23eefa55db752b9d38b5dcba65d`.

[APK verificado en Google Drive](https://drive.google.com/file/d/1WWdZxKFVjJ0YSU5DwctuHb-d6RBN4QUD/view?usp=drivesdk): nombre, tipo y tamaño leídos después de la subida. Enviado como documento al chat personal **@maillet.alan (Tú)** de WhatsApp y confirmado **Leído**, 07:06 de Argentina. Comprobante: `build/qa/775_webview_whatsapp_enviado.png`.

## Alcance de la mejora

La eliminación del trabajo de diagnóstico, la menor frecuencia de sondeo y el agrupamiento de eventos están comprobados. No se midió todavía una diferencia de FPS, consumo o fluidez en el Samsung A35 físico. La pausa Android `onPause()` reduce procesamiento de la vista pero **no detiene todo JavaScript**. Se evita `pauseTimers()` porque afecta globalmente a otras WebViews y puede interferir con SAGE. Al cerrar la pantalla se descarga su DOM para detener sus tareas sin borrar la sesión.

## Unicode

Los cinco archivos de código/pruebas y este informe fueron leídos nuevamente como UTF-8 estricto, sin BOM, conservando LF. Se buscaron todas las secuencias sospechosas exigidas por AGENTS.md y se revisaron manualmente los textos afectados. Las pantallas nativas conservaron «Situación académica», «Analítico», «Sesión reutilizada» y los ordinales.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
