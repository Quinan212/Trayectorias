# Documentos académicos, navegación y ajustes visuales — +775

Fecha: 7 de octubre de 2026. Versión: `1.3.071026+775`.

## Documentos académicos

Situación académica, Analítico y Libreta conservan una copia persistente del PDF y de los datos extraídos para la pantalla nativa. Una copia válida se abre directamente desde Inicio sin acceder a SAGE; si falta, se obtiene una vez. El botón **Actualizar** solicita una nueva versión. La cancelación o un error conservan la copia anterior.

Las copias se separan por identidad del usuario, institución, carrera y tipo de documento. Los archivos de cada versión son independientes y se verifican mediante sumas de comprobación. El índice se publica al final de la escritura y conserva una referencia a la versión previa; los datos nativos siguen disponibles aunque falte el PDF.

El aviso «No se pudo abrir el documento académico» se reprodujo en la versión instalada. El historial de SAGE agrega `-SUPERIOR` al nombre de la institución, mientras que el PDF oficial lo omite. Se corrigió esa comparación retirando únicamente el sufijo explícito de nivel al comparar rótulos. La clave de almacenamiento completa se conserva y no se aceptan coincidencias parciales entre instituciones. La validación del titular y la carrera continúa activa.

También se recuperan descargas anteriores sin índice únicamente cuando coincide la identidad completa. La Libreta obtenida durante la sincronización general se conserva antes de eliminar el archivo temporal, sin reemplazar una copia existente salvo una actualización explícita.

## Navegación y sincronización

Las secciones principales y las pantallas de calendario, diseños curriculares, escenarios, ayuda, próximos pasos, avance y detalles abiertas desde el buscador recuperan el menú de búsqueda al volver. La búsqueda corresponde a la pantalla actual. La barra inferior permanece fuera de las transiciones de las secciones y conserva su posición.

El proceso nativo de sincronización vuelve a estar centrado. Los textos del paso mantienen la transición secuencial, sin superposición. La etiqueta **Sesión reutilizada** queda fuera del fundido de esos textos: conserva el mismo elemento, la posición y la opacidad durante los cambios de etapa.

La barra de acciones del documento se redujo de 74 a 66 píxeles lógicos. Las cuatro acciones tienen espacios iguales, iconos del mismo tamaño y etiquetas alineadas. Se eliminó el desplazamiento que elevaba únicamente el icono de PDF. La barra conserva el centrado horizontal y el área táctil de al menos 48 píxeles de altura. Su ancho máximo con cuatro acciones es 360 píxeles; con tres acciones conserva 316.

## Comprobación

- **170 pruebas superadas**: documentos persistentes, apertura local, actualizaciones, extracción de PDF, buscador, navegación, movimiento y sincronización SAGE. Registro: `build/qa/775_documentos_sesion_dock_tests.log`.
- La geometría del dock se comprobó con anchos de 320, 430 y 700 píxeles. Después de corregir una observación de estilo de las pruebas, el archivo correspondiente pasó nuevamente sus **7 pruebas** y el análisis específico quedó sin observaciones.
- `flutter analyze --no-pub`: **0 errores y 40 advertencias preexistentes**. Las observaciones informativas de codificación explícita UTF-8 se conservan conforme a AGENTS.md. Registro: `build/qa/775_documentos_sesion_dock_analyze.log`.
- Compilación release final correcta para el emulador Android x86_64. Registro: `build/qa/775_documentos_sesion_dock_build.log`.
- En el emulador se obtuvieron los tres documentos reales, con PDF y datos nativos persistentes. Registro sin datos personales: `build/qa/775_documentos_reales_guardados.json`.
- Se desactivó la conectividad, se cerró y volvió a abrir la aplicación y se abrieron **los tres documentos**: visor disponible, ninguna pantalla de SAGE y ningún aviso de apertura fallida. Android confirmó que no existía una red predeterminada activa. Registro: `build/qa/775_documentos_reapertura_offline_emulador.json`.
- Una cancelación real de Actualizar dejó intactas las sumas de comprobación de los tres índices. Registro: `build/qa/775_actualizar_cancelacion_emulador.json`.
- Una actualización real de Libreta publicó un índice nuevo y conservó el PDF anterior, con datos nativos disponibles. Registro: `build/qa/775_actualizar_exito_emulador.json`.
- Los errores de red, escritura, documento incompleto e identidad incorrecta se verificaron con pruebas que exigen conservar la copia previa.
- Se restauró la conexión y el emulador queda visible. La instalación final y sus datos quedaron guardados en el estado de arranque del emulador.

## Release instalada

Archivo local: `build/releases/Trayectorias-1.3.071026-775-documentos-sesion-dock-emulador-release.apk`.

- Nombre de versión: `1.3.071026`; código: `775`.
- Tamaño: `36,562,464` bytes.
- SHA-256: `DA54C401A74611E81F071B470218851AB522E7BAD33BED6C01D494D4A9DF8E77`.
- Certificado del proyecto verificado: `162b950fbf54264a04cbc1778ec3a77f42ede1b03bbbe4fcd987ea5f7faf191b`.
- Instalación conservando datos mediante reemplazo en `Recorridos_API_36`, `emulator-5556`.
- APK destinada a ese emulador x86_64. No se publicó ni se subió a Drive o Google Play.

## Archivos revisados como UTF-8

- [docs/documentos_persistentes_y_regreso_buscador_775_2026-10-07.md](C:/Users/alan/Desktop/Correlativas-principal/docs/documentos_persistentes_y_regreso_buscador_775_2026-10-07.md)
- [lib/compartido/navegacion/barra_busqueda_app.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/compartido/navegacion/barra_busqueda_app.dart)
- [lib/funcionalidades/acceso_estudiante/pantallas/pantalla_visor_pdf_sage.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/acceso_estudiante/pantallas/pantalla_visor_pdf_sage.dart)
- [lib/funcionalidades/laboratorio_atlassian/componentes/componentes_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/componentes/componentes_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_disenos_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_disenos_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/datos/repositorio_documentos_academicos_sage.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/abrir_documento_academico_sage.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/abrir_documento_academico_sage.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/modelos_documento_academico_pdf.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/documentos_pdf/vista_documento_academico_nativo.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart)
- [lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sincronizacion_sage_automatica.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sincronizacion_sage_automatica.dart)
- [test/documentos_pdf/apertura_local_y_actualizacion_documentos_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/documentos_pdf/apertura_local_y_actualizacion_documentos_test.dart)
- [test/documentos_pdf/documentos_persistentes_sage_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/documentos_pdf/documentos_persistentes_sage_test.dart)
- [test/documentos_pdf/vista_documento_academico_nativo_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/documentos_pdf/vista_documento_academico_nativo_test.dart)
- [test/laboratorio_atlassian/busqueda_global_react_developer_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/busqueda_global_react_developer_test.dart)
- [test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart)
- [test/sage_sincronizacion/stepper_sincronizacion_sage_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/sage_sincronizacion/stepper_sincronizacion_sage_test.dart)

Se reabrieron los archivos modificados como UTF-8 estricto, sin BOM y sin secuencias sospechosas. Se revisaron los textos visibles en las pantallas de documentos y sincronización. Registro completo: `build/qa/775_documentos_navegacion_validacion_utf8.json`.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
