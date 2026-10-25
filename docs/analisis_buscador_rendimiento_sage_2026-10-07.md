# Buscador, movimiento y sincronización con SAGE

Revisión del 7 de octubre de 2026. Versión preparada: **1.3.071026+1791257543**.

Los problemas informados tenían causas concretas en el recorrido público. El acceso de Inicio y el campo de búsqueda tenían superficies diferentes y se animaban junto con la página. Los efectos de desenfoque y el movimiento continuo del Plan agregaban trabajo. En SAGE coexistían sondeos, respuestas tardías y una confirmación demasiado rápida de errores de acceso.

## Buscador

Inicio y la búsqueda comparten `BarraBusquedaApp`. El botón asciende mediante un único Hero y se convierte en el campo superior. El vuelo usa una superficie sin campo editable, de modo que el teclado no compite con el movimiento. La ruta de búsqueda mantiene fija la página y evita sumar un desplazamiento de pantalla al de la barra.

Las secciones conservadas desactivan sus Heroes mientras están ocultas. Esto evita duplicados al pasar entre Inicio, Exámenes, Plan, Materias y Datos. Se conserva la preparación del destino detrás de la búsqueda antes de cerrarla; los recorridos hacia Exámenes, Plan, Calendario y Ayuda no vuelven a mostrar Inicio durante la salida.

El Plan y ambos buscadores comparten la lectura de los assets de carreras. Una carga fallida sale de la caché para permitir reintentar. Los datos públicos de exámenes y la trayectoria siguen actualizándose mediante sus proveedores y notificaciones.

## Rendimiento y movimiento

- Rutas: 280 ms de entrada y 220 ms de salida. Contenido: 240 ms, con demoras pequeñas por tarjeta.
- Las secciones conservan un fondo opaco y un desplazamiento corto; se eliminó la escala de toda la página.
- Los gradientes reemplazan los desenfoques y las máscaras del recorrido principal.
- El desplazamiento vertical actualiza únicamente la capa superior mediante un notificador; evita reconstruir todos los navegadores.
- Las filas del Plan conservan el desplazamiento manual y sus indicadores laterales. Se retiró el movimiento automático permanente.
- La extracción de notas del PDF pasa a un isolate para liberar el hilo de interfaz.

Estas correcciones reducen trabajo identificado en el código. No se midieron FPS, memoria o temperatura en el Samsung A35 físico; no se afirma una mejora numérica de fluidez. El APK ARM64 permite comprobar el comportamiento en el dispositivo real.

## SAGE

El envío de credenciales espera que el formulario exista y esté listo. El estado de envío se activa antes de esa espera para impedir envíos simultáneos. Si faltan controles durante la carga, se vuelve a comprobar el formulario y la sesión antes de emitir un error. Un formulario enviado correctamente no se vuelve a enviar en el mismo intento.

Un rechazo de credenciales requiere varias observaciones, un error persistente, documento listo y al menos cinco segundos desde el envío. La detección de una sesión aceptada tiene prioridad. Un callback tardío del login anterior no devuelve la sincronización al paso inicial. La contraseña del campo se conserva ante una falla temporal y se limpia tras aceptar el acceso.

Después de autenticarse, el vigilante detecta **cinco segundos sin avance real**. Recupera el recorrido internamente con un GET en la misma WebView y conserva sus cookies. Los bytes de una descarga en curso cuentan como avance y evitan reiniciar una transferencia sana. Mientras se retoma el recorrido, la pantalla conserva el progreso alcanzado.

La recuperación invalida los sondeos y acciones del intento anterior, cancela la descarga HTTP anterior y reconstruye los controles pendientes. Las consultas JavaScript tienen un límite de espera. Los sondeos de navegación e historial se realizan en serie. Se limita la recuperación a dos intentos por paso y cuatro en el recorrido; si SAGE sigue sin responder, aparece un error recuperable. La vigilancia se pausa al salir, pasar a segundo plano o esperar que el usuario elija un legajo.

La recuperación usa una sesión vigente. Si el servidor vence la sesión, corresponde volver a autenticar. No se agregó almacenamiento de contraseñas en texto plano.

## Verificación

- 80 pruebas del tramo afectado aprobadas: barra compartida, temas claro y oscuro, navegación conservada, trayectoria, caché, vigilancia y WebView simulada.
- Suite completa final: **243 aprobadas y 4 fallos preexistentes**. Dos comparaciones de código del administrador, falta del archivo `test/fixtures/mesas_julio_2026.xlsx` y una comprobación de tema del Drawer antes de terminar su animación.
- `flutter analyze`: **0 errores, 40 advertencias y 479 avisos informativos**. La referencia anterior tenía 0 errores, 40 advertencias y 482 avisos informativos.
- Las pruebas de WebView verifican espera del formulario, envío único, avisos viejos del login, recuperación a los cinco segundos, conservación del controlador y ausencia de borrado de cookies.
- Se inspeccionaron capturas renderizadas sin abrir ventanas: vuelo del buscador, campo superior y Plan de Educación Física con el logo ISEEF, tildes y eñes.
- No se abrió el emulador ni se usaron el mouse o el teclado de la computadora. La sesión real de SAGE y la fluidez del A35 quedan para la comprobación en el teléfono.

Los resultados detallados se conservan en `build/qa/busqueda_sage_test_final.log`, `build/qa/busqueda_sage_suite_completa_final.log`, `build/qa/busqueda_sage_analyze_final.log` y `build/qa/busqueda_sage_apk_release.log`.

## APK entregado

El APK release para ARM64 está en `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Tamaño: **34.636.126 bytes, 33,0 MiB**. La firma se verificó y coincide con el certificado público de la llave del proyecto. La aplicación se identifica como Trayectorias, conserva su paquete, usa SDK mínimo 24 y objetivo 36, y tiene `debuggable=false`.

La versión visible es **1.3.071026**. El compilador suma 2000 al código base para la variante ARM64: el código real del APK es **1791259543**. Una publicación posterior destinada a actualizar teléfonos que instalaron este APK deberá usar un código superior a ese valor.

SHA-256 del APK: `17DE7DEFD714AE1122AE1AB6CBD73A1DCA67E092DD0F28D79EEEDF72A9E4C988`.

Se subió mediante el conector de Google Drive como [Trayectorias-1.3.071026-A35-release-2026-10-07.apk](https://drive.google.com/file/d/1ul9ev2c-PLWvBVSnpwIXjv6IGK2mpFLJ/view?usp=drivesdk). Una lectura posterior confirmó nombre, tipo de archivo y tamaño completo de 34.636.126 bytes. Se conservó la carpeta de la entrega anterior. Esta revisión no incluyó una publicación nueva en Google Play.

## Archivos del cambio

La barra compartida está en `lib/compartido/navegacion/barra_busqueda_app.dart`; el ritmo y la conservación de secciones, en `lib/compartido/movimiento/movimiento_app.dart`; la caché, en `lib/datos/cargador_fuente_html.dart`.

Se revisaron Inicio, la pantalla principal, Plan, los componentes de acceso y ambos buscadores dentro de `lib/funcionalidades/laboratorio_atlassian/`. La vigilancia, el recorrido y el formulario están en `lib/funcionalidades/trayectoria_sage_laboratorio/sage/`.

Se actualizaron las pruebas afectadas por la nueva superficie y se agregaron pruebas de caché, vigilancia y recuperación de WebView. `pubspec.yaml` incrementa la versión y declara la interfaz de WebView únicamente como dependencia de pruebas; `pubspec.lock` registra ese alcance.

La configuración Android dejaba los APK por arquitectura deshabilitados aunque Flutter recibiera esa opción. Se quitó esa anulación de `android/app/build.gradle.kts` para usar la configuración del compilador. Las compilaciones normales mantienen su comportamiento y la variante para el teléfono contiene únicamente ARM64.

Los archivos existentes se respaldaron antes de editarlos. Las fuentes, pruebas y documentación modificadas se releen como UTF-8, se revisan sus textos visibles y se buscan secuencias sospechosas. El detalle se conserva en `build/qa/busqueda_sage_utf8_final.log`.
