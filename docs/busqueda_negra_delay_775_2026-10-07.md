# Buscador negro y espera progresiva — +775

El menú de búsqueda recibía el fondo azul del tema exterior porque consultaba el contexto antes de aplicar su tema propio. Se corrigió únicamente el fondo del Scaffold de esta pantalla: en oscuro usa el negro definido en el tema del laboratorio; en claro conserva su color anterior. Se compararon los respaldos de sus tarjetas y secciones y se conservaron sus degradados, textos, accesos, instituciones y sugerencias.

Restaurar los archivos del tema general no había sido suficiente para este recorrido: el contexto exterior seguía aportando el azul. Este cambio local completa esa corrección. Los archivos generales de tema y la pantalla principal siguen idénticos, byte por byte, a los respaldos anteriores a los cambios de contraste. Los ajustes oscuros de los tres documentos académicos se conservan.

La espera artificial del skeleton disminuye 500 ms, el 25 % de los dos segundos iniciales, en cada apertura: **2000 → 1500 → 1000 → 500 → 0 ms**. Después permanece en cero. El contador se comparte entre las rutas durante la ejecución de la app y se reinicia al comenzar una nueva ejecución; no se guarda en preferencias. A partir de la quinta apertura el skeleton está desactivado desde la primera imagen, sin crear un temporizador ni producir un parpadeo. Salir antes de terminar la espera cancela el temporizador y esa visita cuenta igualmente.

Se conserva la identidad y posición del contenido al retirar el skeleton. La barra de búsqueda compartida, el regreso desde los accesos y las correcciones de SAGE no se modificaron. Versión: `1.3.071026+775`.

## Validación

- 193 pruebas aprobadas: documentos, caché persistente, Libreta, buscador, recorridos de regreso, animaciones, sincronización SAGE y temas.
- Dos nuevas pruebas comprueban el fondo negro bajo un tema exterior azul y los límites exactos de las seis primeras aperturas: 2000, 1500, 1000, 500, 0 y 0 ms.
- `flutter analyze`: cero errores, 40 advertencias y 479 avisos informativos preexistentes; cero diagnósticos nuevos al comparar con el análisis previo.
- Compilaciones release correctas para el emulador x64 y el teléfono ARM64. El APK móvil contiene `libapp.so` y `libflutter.so` para ARM64.
- Se revisaron en el emulador el buscador en claro, el fondo negro en oscuro, los accesos y la zona de herramientas, SAGE, instituciones y sugerencias. Los píxeles del fondo oscuro se confirmaron como `(0, 0, 0)`. Se revisaron las tildes, la eñe y los símbolos de año visibles.
- Los hashes de los tres índices persistentes de documentos son iguales antes y después de instalar y recorrer el buscador.

Capturas: `build/qa/775_busqueda_negra_arriba_oscuro.png`, `build/qa/775_busqueda_negra_abajo_oscuro.png`, `build/qa/775_busqueda_negra_arriba.png` y `build/qa/775_busqueda_negra_abajo.png`.
Logs: `build/qa/775_busqueda_negra_delay_tests.log`, `build/qa/775_busqueda_negra_delay_analyze.log`, `build/qa/775_busqueda_negra_delay_build.log` y `build/qa/775_busqueda_negra_delay_arm64_build.log`.

## Entrega

APK del emulador: `build/releases/Trayectorias-1.3.071026-775-busqueda-negra-delay-emulador-release.apk`.
Tamaño: 36.562.464 bytes.
SHA-256: `75885072956FBBD50167BBC5A1C1F431C486B9E41871D5DC10FF14C72849B685`.
Instalado con `adb install -r` en `emulator-5556`, conservando sus datos. Android confirma `versionCode=775`, `versionName=1.3.071026` y `lastUpdateTime=2026-10-07 09:19:00` GMT (06:19:00 de Argentina).

APK del teléfono: `build/releases/Trayectorias-1.3.071026-775-release-arm64.apk`.
Tamaño: 34.871.382 bytes.
SHA-256: `F5DB2845FC0FCBD5EB37B800BF4C023CA7C3C21E633F64948BD7BB627FFFBBE9`.
MD5 local: `E1767A6F9124AB75584950E6BA3C31CF`.
Ambos APK usan el certificado del proyecto, SHA-256 `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`.

A pedido del usuario, se subió el APK móvil a Mi unidad mediante el plugin de Google Drive. La lectura posterior de metadatos confirmó el nombre, el tipo APK y los 34.871.382 bytes. No se cambiaron los permisos del archivo.
[APK en Drive](https://drive.google.com/file/d/1g-TH2FGfQ_cWRjgkZ4Z-pT_DpHNAMk3E/view?usp=drivesdk).

También se adjuntó ese mismo APK como documento en el chat personal `@maillet.alan (Tú)` de WhatsApp Web, autorizado expresamente por el usuario. El mensaje incluye el enlace de Drive y la explicación de la espera. Se verificó la tarjeta de 33 MB con estado **Leído** a las 06:24 de Argentina. Captura del envío: `build/qa/775_whatsapp_enviado.png`.

## Archivos modificados y UTF-8

- `lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart`.
- `test/laboratorio_atlassian/busqueda_global_react_developer_test.dart`.
- Este informe.

Los dos archivos existentes se leyeron como UTF-8 estricto antes de editar, no tenían secuencias sospechosas y se respaldaron en `build/qa/respaldo_busqueda_negra_delay_775_20261007`. Se aplicaron cambios localizados y se conservaron sus saltos LF. Este informe se creó como UTF-8 sin BOM. Auditoría final: `build/qa/775_busqueda_negra_delay_utf8.json`.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
