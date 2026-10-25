# Calendario, Datos, Plan e instituciones — release +775

Fecha: 7 de octubre de 2026. Versión: `1.3.071026+775`.

## Cambios por pantalla

### Calendario

Se aplicaron el tema académico y las animaciones compartidas a la selección de carrera, los contadores, los días y los eventos. Cada cambio de mes muestra una sola grilla; los títulos anteriores no quedan superpuestos. El botón Hoy se ubicó junto a los controles del mes, con colores legibles en ambos temas. Los días seleccionados, el día actual y los días de otros meses conservan estados visuales distintos.

La grilla tiene seis semanas y alturas adaptables. Se eliminó el espacio adicional heredado de la barra de estado dentro de la grilla. Al seleccionar un día de otro mes, también cambia el mes visible. El skeleton de actualización se conserva y respeta la preferencia de reducir movimiento. El contenido desplazable termina por encima de la navegación del sistema.

### Datos

Se adaptaron el encabezado, el perfil SAGE, el estado de sincronización, las métricas, las fechas y las filas de carreras. Los números usan el mismo ritmo de animación que las otras herramientas. Las etiquetas y los valores se apilan y se alinean a la izquierda en teléfonos o con fuentes grandes; no se recortan para mantener una altura fija.

El detalle de carrera utiliza los datos actuales de la trayectoria compartida. El panel de almacenamiento explica la copia local y mantiene el botón Desincronizar con el mismo comportamiento. Los márgenes inferiores respetan la navegación del sistema.

### Plan completo

Se trabajaron el encabezado, la búsqueda por materia o código, los selectores de carrera, institución y año, el resumen, las materias y sus detalles. Los selectores se pueden desplazar y los botones tienen respuesta al toque y contraste específico para cada tema. El resumen dispone tres métricas cuando hay espacio y se reorganiza para pantallas estrechas o fuentes grandes.

Las tarjetas de materias tienen altura natural: los nombres y las correlativas largos pueden ocupar varias líneas. Los cambios de filtros animan la sección entrante sin superponer textos anteriores. El detalle acomoda los requisitos y los valores según el ancho. Se mantiene el espacio reservado para el buscador inferior y la navegación del sistema.

### Tarjeta de institución del menú de búsqueda

El logo pasó a una insignia propia, con tamaño contenido y fondo legible. El nombre de la carrera y de la institución tienen espacio real; se retiraron la marca de agua gigante y el desenfoque de esta tarjeta. Las cuatro acciones están alineadas en una grilla de dos por dos y conservan sus destinos y carrera correspondientes.

El carrusel adapta su altura al texto y a la escala de fuente. Mantiene una animación breve de entrada y de presión. Los logos particulares de PSCS, Artes e ISEEF se conservan. El fondo negro del menú de búsqueda, los resultados y la barra independiente no se modificaron.

## Archivos revisados y modificados

- [Menú de búsqueda e instituciones](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart)
- [Calendario](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart)
- [Datos](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_datos_atlassian.dart)
- [Plan completo](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart)
- [Componentes académicos](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/componentes/componentes_academicos_app.dart)
- [Pruebas de presentación](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/presentacion_calendario_datos_plan_test.dart)
- [Pruebas de trayectoria y recorridos](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart)
- [Pruebas del menú de búsqueda](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/busqueda_global_react_developer_test.dart)

Los cambios de tema están limitados a estas pantallas y sus detalles. No se modificaron los proveedores, la sincronización SAGE, la persistencia de documentos ni la navegación compartida.

## Verificación

Pasaron **292 pruebas pertinentes**, incluyendo las nuevas pruebas de presentación, los recorridos y regresiones del buscador, los skeletons, la trayectoria compartida, Exámenes, la calculadora, las animaciones y los documentos académicos de SAGE.

Las pruebas de presentación cubren temas claro y oscuro, teléfonos de 360 × 640, fuentes al doble de tamaño, navegación inferior de 48 píxeles, cambios rápidos de mes, contraste, reducción de movimiento y los cuatro destinos de las tarjetas de instituciones.

`flutter analyze` terminó sin errores. Mantiene exactamente los mismos 40 warnings y 477 infos de la referencia anterior; no agregó diagnósticos. Por esos avisos preexistentes, el comando devuelve código 1. El test del importador Excel que depende de `test/fixtures/mesas_julio_2026.xlsx` no forma parte de esta ejecución: ese archivo sigue ausente.

- [Registro de las 292 pruebas](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_regresion_entrega.log)
- [Registro de análisis](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_analyze_entrega.log)
- [Auditoría UTF-8 y hashes de fuentes](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_utf8_final.json)
- [Respaldo anterior a los cambios](C:/Users/alan/Desktop/Correlativas-principal/build/qa/respaldo_calendario_datos_plan_instituciones_775_20261007)
- [Parche de cambios](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_cambios.patch)

## Revisión visual

Se verificaron el calendario y la institución en el emulador durante el trabajo. La revisión definitiva se realizó mediante renderizados de pruebas con las fuentes Inter reales, sin controlar el escritorio ni interrumpir la otra aplicación abierta en el emulador. Estas capturas usan datos de ejemplo; no son capturas de la última instalación.

| Pantalla | Oscuro | Claro |
| --- | --- | --- |
| Calendario | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_oscuro_final.png) | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_claro_final.png) |
| Datos | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_datos_oscuro_final.png) | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_datos_claro_final.png) |
| Plan | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_plan_oscuro_final.png) | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_plan_claro_final.png) |
| Institución | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_institucion_oscuro_final.png) | [Captura](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_institucion_claro_final.png) |

No se midieron tiempos de fotograma ni rendimiento en un Samsung A35; la validación confirma comportamiento y presentación, no una mejora cuantificada de rendimiento en ese teléfono.

## APK y entrega

La versión x86_64 release +775 quedó instalada mediante ADB, sin traer la aplicación al frente. Se verificaron el paquete, la versión, la firma y la ausencia del indicador debuggable.

- [APK del emulador](C:/Users/alan/Desktop/Correlativas-principal/build/releases/Trayectorias-1.3.071026-775-calendario-datos-plan-emulador-release.apk)
- [Auditoría del APK instalado](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_apk_x64_verificado.json)

El APK ARM64 definitivo para teléfono se compiló, se verificó y se subió a Drive. La lectura posterior de metadatos confirmó el nombre y los 34.936.974 bytes del archivo local (33,3 MiB). No se cambiaron permisos de uso compartido.

- [APK para teléfono en Drive](https://drive.google.com/file/d/1J3drOJDOnezai-n1IoFqdMHRRnA6N_1D/view?usp=drivesdk)
- [APK ARM64 local](C:/Users/alan/Desktop/Correlativas-principal/build/releases/Trayectorias-1.3.071026-775-calendario-datos-plan-arm64-release.apk)
- [Auditoría del APK ARM64](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_apk_arm64_verificado.json)
- [Comprobación de subida y metadatos](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_calendario_datos_plan_drive_verificado.json)

SHA-256 del APK para teléfono: `08f1d1f730618817cf4e3741425f3a1e2796013c53640ea9b9e8adf6a856c9d9`. SHA-256 del certificado de firma: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`. Ambos APK contienen versión +775 y corresponden a los hashes finales de los ocho archivos de fuente y pruebas.

El envío por WhatsApp al chat propio está pendiente: Chrome no está conectado y WhatsApp en el navegador interno requiere iniciar sesión. No se envió el archivo por WhatsApp.

## Unicode

Los ocho archivos de código y pruebas fueron leídos como UTF-8 estricto antes y después de la edición. Se conservaron los saltos LF, sin BOM. La búsqueda de las secuencias sospechosas de mojibake no encontró coincidencias. Se revisaron los textos afectados y se comprobaron tildes, eñes y símbolos académicos en los renderizados. Este informe también se guardó y revisó como UTF-8 sin BOM.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
