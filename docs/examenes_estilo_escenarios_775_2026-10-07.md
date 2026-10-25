# Exámenes con el estilo de Escenarios — release +775

Se aplicó la presentación aprobada de Escenarios y la calculadora a la pantalla pública PantallaExamenesAtlassian y al detalle de cada mesa. La carga, suscripción compartida, filtros, refresco y operaciones administrativas conservan su lógica.

## Cambios

- Paleta local compartida: fondo negro en oscuro, tarjetas neutras, texto secundario más legible y bordes definidos. El tema claro usa el mismo criterio de contraste. La extracción del tema conserva los valores que ya usaban Escenarios y la calculadora; no cambia el tema global.
- Filtros Todos, Llamados y Coloquios con iconos de tamaño estable, respuesta al toque y transición breve de selección. Se distribuyen en varias filas cuando el ancho o el tamaño de texto lo necesitan.
- Entrada coordinada de los grupos de mesas y contadores que interpolan al cambiar los filtros. Se conserva un único contenido de resultados, sin superponer el listado anterior. Las animaciones respetan la opción de Android para reducir movimiento.
- Las etiquetas de estado y de instancia tienen colores con contraste probado de al menos 4,5:1. Se colocan debajo de los datos de cada mesa para dar espacio al nombre y evitar columnas demasiado estrechas con texto grande.
- Área segura inferior y espacio reservado para la barra independiente del buscador en la pantalla principal. El detalle reserva el área de navegación de Android y una separación al final del contenido.
- Encabezado adaptable al tamaño de texto. Se conserva el encabezado colapsable con el tamaño habitual; con texto grande se usa una altura suficiente para evitar recortes y desbordes.
- Selectores de carrera y año desplazables. Elegir de nuevo el mismo valor conserva el filtro actual. Las hojas de selección y edición usan la paleta local.
- Se conservaron los skeletons iniciales y de actualización, las capacidades administrativas, los enlaces de actas y la conexión a mesas compartidas.

## Verificación

48 pruebas de Exámenes y Escenarios/calculadora correctas. La regresión ampliada produjo 244 pruebas correctas y una prueba que no pudo ejecutarse por falta del archivo preexistente test/fixtures/mesas_julio_2026.xlsx. Esa prueba corresponde al importador del laboratorio Excel, que no se modificó; no se creó un libro ficticio ni se alteró la prueba para omitir el problema.

Las pruebas nuevas comprueban ambos temas a 360 × 640, texto ampliado al doble, área de navegación de 48 puntos, espacio para la búsqueda inferior, cambio de filtros sin resultados antiguos superpuestos, contraste de estados, detalle con acta, selectores desplazables, skeleton inicial y de actualización, conservación del filtro al refrescar y movimiento reducido. Las pruebas existentes comprueban actualización remota en listado, calendario, buscador y detalle, además de los recorridos de regreso al menú.

flutter analyze final: 0 errores, 40 warnings y 477 infos, sin nuevos diagnósticos frente al release anterior. La salida no cero corresponde a los avisos preexistentes.

Se compilaron los releases x64 y ARM64, versión 1.3.071026 y versionCode 775. La firma ARM64 coincide con el certificado del proyecto: 162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b. Cada APK contiene libflutter.so de su arquitectura objetivo. Hashes y tamaños registrados en build/qa/775_examenes_apk.json.

El release x64 se instaló con adb install -r en emulator-5556, conservando los datos. Se revisaron el listado y el detalle en claro y oscuro, selección de Coloquios, contadores, actas y regreso desde el detalle al listado. Los textos Exámenes, Próximos, Año, Antigüedad, institución y Docentes se ven correctamente. Se restauró el modo oscuro del emulador.

Capturas:

- build/qa/examenes_release_oscuro.png
- build/qa/examenes_coloquios_oscuro.png
- build/qa/examenes_detalle_estado_oscuro.png
- build/qa/examenes_claro.png
- build/qa/examenes_detalle_claro_estable.png

El buscador React, tema global Atlassian y pubspec.yaml conservan sus hashes anteriores. Los proveedores y repositorios de Exámenes, la sincronización SAGE y los documentos persistentes no se editaron.

## Entrega

[APK release ARM64 en Drive](https://drive.google.com/file/d/1EQp3qPO2UtPQeZdXYeRdeToOEjWv-eiI/view?usp=drivesdk). El conector confirmó la subida y una lectura posterior de metadatos verificó el nombre y los 34.936.950 bytes.

Enviado al chat propio @maillet.alan (Tú) en WhatsApp; el mensaje aparece como Leído a las 8:03 a. m. del 7 de octubre de 2026. Comprobante: build/qa/775_examenes_whatsapp_enviado.png.

## Archivos revisados

- lib/compartido/tema/tema_herramientas_app.dart
- lib/funcionalidades/calculadora/pantalla/tema/estilos_calculadora.dart
- lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart
- test/examenes/presentacion_examenes_test.dart
- test/examenes/edicion_contextual_admin_test.dart
- test/examenes/sincronizacion_mesas_test.dart
- docs/examenes_estilo_escenarios_775_2026-10-07.md

Los archivos existentes se leyeron como UTF-8 antes de editar y se respaldaron en build/qa/respaldo_examenes_775_20261007. No se detectó corrupción preexistente. Las pruebas anteriores de administración y sincronización se adaptaron al formato del código y al skeleton de presentación del buscador, conservando sus comprobaciones funcionales. Los archivos nuevos se guardaron como UTF-8 sin BOM y se preservaron los saltos LF. La auditoría final está en build/qa/775_examenes_utf8_despues.json.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
