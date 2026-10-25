# Pantallas públicas, trayectoria compartida y movimiento

Revisión del 7 de octubre de 2026. Preferencia indicada: efectos más marcados, como Che, Preguntame. El trabajo se realiza en segundo plano, sin controlar ventanas, mouse ni teclado del equipo.

## Recorridos revisados

Los accesos se siguieron desde `main.dart`, el menú, las acciones del Inicio y los destinos de ambos buscadores. Una carpeta llamada «laboratorio» puede contener la interfaz pública actual.

| Acceso público | Datos utilizados | Movimiento y conservación del estado |
| --- | --- | --- |
| Inicio React | Trayectoria, carrera seleccionada, documentos y estado local | Entrada del encabezado y contenido; respuesta al toque |
| Menú → Exámenes | Fuente compartida de mesas, filtros locales | Entrada de sección, filtros y tarjetas; respuesta de filas |
| Exámenes → detalle / acta / edición autorizada | Mesa vigente por identificador | Transición común; las actualizaciones remotas siguen llegando al detalle |
| Inicio o búsqueda → calendario | Mesas vigentes y aprobaciones de la trayectoria actual | Transición común, entrada de paneles y selección de día |
| Búsqueda del Inicio | Trayectoria, catálogo, mesas y contenidos curriculares | Resultados escalonados, tarjetas con respuesta al toque |
| Búsqueda desde otras secciones | Las mismas fuentes | Entrada común y caché renovada aunque no cambie la cantidad de registros |
| Plan → carrera / institución / detalle / PDF / presentación | Catálogo visible, planes y recursos de institución | Entrada de sección y tarjetas escalonadas; movimiento horizontal pausado al ocultar la sección |
| Materias → detalle | Trayectoria compartida; detalle localizado por carrera y materia | Conserva filtros y lectura; renueva nota, fecha y estado |
| Datos → detalle de carrera | Trayectoria compartida y carrera localizada por identidad | Contadores e información renovados sin reabrir |
| Búsqueda → Avance / Próximos pasos | Carrera actualmente seleccionada | Responde al cambio de carrera y a la sincronización de SAGE |
| Búsqueda → Diseños / detalle / Escenarios / Ayuda | Catálogo, contenidos y proveedores correspondientes | Transición común y componentes compartidos |
| SAGE → autenticación / sincronización / documentos | Flujo público de SAGE y sus callbacks al contenedor | Transición de entrada común; cambio de vistas nativas con el mismo ritmo |
| Menú → Administración → pantallas autorizadas | Acceso por dispositivo y proveedores administrativos | Rutas internas con la transición común; conserva los controles de acceso existentes |

El Inicio Atlassian anterior, Liquid Glass, el contenedor SAGE anterior, el shell legado y el laboratorio Excel no se usaron como raíz de esta implementación. El motor `PantallaSageLaboratorio` sí pertenece al recorrido público actual.

## Cambios aplicados

- Política compartida: entrada de contenido de 480 ms, navegación de 380 ms, regreso de 260 ms y respuesta de 80/180 ms. Se combinan desplazamiento, escala y aparición, con entradas escalonadas limitadas a los primeros elementos.
- Las cinco secciones conservan sus navegadores, formularios, filtros y scroll. Las secciones ocultas detienen sus tickers y dejan de recibir foco del teclado.
- Los efectos respetan «reducir animaciones». El desplazamiento al inicio usa un salto inmediato en ese caso, para evitar animaciones con duración cero inválidas.
- Se conserva el gesto nativo de regreso en iOS. En Android y escritorio se aplica la transición nueva compartida.
- Abrir una pantalla desde la búsqueda prepara primero la sección, sus filtros y el destino detrás del buscador. Su salida revela directamente esa pantalla, sin pasar por el Inicio. Los destinos internos se montan sin una segunda transición de entrada y conservan el regreso animado. Se evita tramitar dos destinos simultáneos y abrir buscadores duplicados durante la entrada o salida.
- Las transiciones de página conservan el fondo opaco y se desplazan horizontalmente. El desvanecimiento queda en el contenido, para evitar que los textos de dos pantallas se mezclen durante el cambio.
- El foco inicial del buscador Atlassian espera su transición real de entrada; ya no depende de una espera fija de 220 ms.
- Calendario, Avance, Próximos pasos, detalle de materia y detalle de carrera leen la trayectoria compartida. Una desincronización elimina la información que antes permanecía en copias antiguas.
- Las cachés de búsqueda detectan cambios en trayectoria y contenidos curriculares, además de las mesas. Mantienen actualizados los destinos de la misma consulta abierta.
- Educación Física y Música conservan su identificador al abrir herramientas; antes podían resolverse como Historia. Educación Física figura en los filtros de Exámenes y Calendario y en sus etiquetas.
- La primera entrada desde el menú a Exámenes o Plan toma la carrera de la trayectoria seleccionada. Las siguientes visitas conservan los filtros propios de la sección.
- Las tiras de materias del plan detienen su movimiento al ocultarse o reducir animaciones y limitan el salto después de una pausa larga.

## Archivos revisados y modificados

Todos los archivos de esta lista se comprobaron como UTF-8 antes de la edición. No presentaban las secuencias sospechosas revisadas. Los archivos previos cuentan con respaldo en `build/qa/respaldo_movimiento_20261006`; se conservaron sus saltos LF.

- `lib/compartido/movimiento/movimiento_app.dart` — nuevo sistema compartido.
- `lib/compartido/navegacion/transiciones_paginas_app.dart` — transición general.
- `lib/funcionalidades/laboratorio_atlassian/componentes/componentes_atlassian.dart` — paneles, botones, controles, rutas y hojas.
- `lib/funcionalidades/laboratorio_atlassian/componentes/trayectoria_activa_atlassian.dart` — trayectoria compartida, nuevo.
- `lib/funcionalidades/laboratorio_atlassian/tema/tema_atlassian.dart` — transición también en rutas abiertas directamente.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_laboratorio_atlassian.dart` — contenedor y destinos de navegación.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_inicio_react_developer.dart` — ritmo del Inicio.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart` — filas y filtro de carrera.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_calendario_atlassian.dart` — trayectoria y selección animada.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart` — filas y detalle actualizado.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_datos_atlassian.dart` — detalle de carrera actualizado.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_plan_atlassian.dart` — tarjetas y movimiento horizontal.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_disenos_atlassian.dart` — respuesta al tocar filas.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart` — Avance y Próximos pasos.
- `lib/funcionalidades/laboratorio_atlassian/pantallas/utilidades_atlassian.dart` — correspondencia de carreras.
- `lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_atlassian.dart` — datos y foco coordinados.
- `lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart` — resultados y ritmo compartidos.
- `lib/funcionalidades/administrador/tema/tema_administrador_atlassian.dart` — ruta administrativa compartida.
- `lib/funcionalidades/trayectoria_sage_laboratorio/sage/pantalla_sage_laboratorio.dart` — transiciones entre vistas nativas.
- `test/movimiento/movimiento_app_test.dart` — nuevas pruebas de navegación, estado, foco y entrada.
- `test/laboratorio_atlassian/trayectoria_compartida_y_recorridos_test.dart` — nuevas pruebas con pantallas públicas y captura sin ventanas.
- `docs/recorrido_publico_y_sincronizacion_mesas.md` — recorrido actualizado.
- Este documento.

## Verificación y límites

Las pruebas nuevas comprueban cambios rápidos entre secciones, conservación de formularios y lectura, navegadores conservados, tickers ocultos, foco, movimiento reducido, cancelación de toque, activación con teclado, actualización de herramientas y detalles y búsquedas abiertas. La corrección del destello comprueba cada cuadro de salida desde ambos buscadores hacia Exámenes, Plan, Calendario y Ayuda; el destino está preparado y el Inicio no se pinta debajo. También se comprueban los píxeles de una transición para asegurar que el fondo del destino no transparente el origen, y el regreso animado de las herramientas. Se revisan capturas del calendario durante el cambio y del plan real de Educación Física con el logo ISEEF, sin abrir el emulador.

La verificación de servidor, instituciones de mesas, publicación de contenido y laboratorio Excel mantiene los alcances del [informe de sincronización de mesas](recorrido_publico_y_sincronizacion_mesas.md). Este trabajo no publica mesas nuevas ni modifica registros remotos. Una actualización de la app es necesaria para que los usuarios reciban estas mejoras.

Resultados de la revisión y de la corrección del destello entre pantallas:

- 44 pruebas dirigidas de movimiento, recorridos, actualización de mesas, administración, flujo SAGE y protección de textos: correctas. Incluyen ocho recorridos comprobados cuadro a cuadro y una comprobación de píxeles para evitar transparencias entre páginas. Registro: `build/qa/flash_inicio_test_final.log`.
- Última suite completa, anterior a esta corrección: 222 correctas y cuatro fallos anteriores. Dos son comparaciones de código del listado administrativo; una requiere el archivo ausente `test/fixtures/mesas_julio_2026.xlsx`; la otra compara el tema del menú sin esperar su animación. Registro: `build/qa/movimiento_test_completo.log`.
- `flutter analyze`: cero errores, 40 advertencias anteriores y 482 observaciones. No se añadieron diagnósticos respecto de la revisión anterior. Registro: `build/qa/flash_inicio_analyze_final.log`.
- App Bundle de publicación compilado nuevamente con la corrección: `build/app/outputs/bundle/release/app-release.aab`, 80.812.583 bytes, generado el 7 de octubre a las 00:38:34, hora local. La firma se verificó y su certificado coincide con el PEM de carga. SHA256 del bundle: `FA16157778D90CB88E241A1580A79663636B30B9DB553E5FDA95708B2FA64508`. Registros: `build/qa/flash_inicio_build_release.log` y `build/qa/flash_inicio_firma_release.log`.
- Captura renderizada del recorrido público al plan de Educación Física con fuentes e iconos: `build/qa/movimiento_plan_educacion_fisica.png`. Se revisaron «Educación Física», «Año», «código», los datos del plan y el logo ISEEF sin abrir ventanas.
- Captura de la salida del buscador hacia el calendario: `build/qa/transicion_calendario_sin_inicio.png`. El destino aparece directamente y los fondos permanecen opacos; se revisaron «Educación Física», «Miércoles» y los textos del calendario.
- La corrección modifica seis archivos: el sistema de movimiento, el helper de rutas, el contenedor público, las dos pruebas de recorridos y movimiento y este documento. Tienen respaldo exacto en `build/qa/respaldo_flash_inicio_20261007`. Se comprobaron como UTF-8 antes de editar y se leyeron nuevamente después: sin BOM, cero secuencias sospechosas y saltos LF conservados. Registro: `build/qa/flash_inicio_validacion_utf8.log`. La revisión inicial de los 23 archivos se conserva en `build/qa/movimiento_validacion_utf8.log`.

Se validaron el código, las pantallas renderizadas y la compilación Android. No se inició una sesión real de SAGE ni se probó el gesto de regreso en un dispositivo iOS. La publicación en Google Play sigue siendo un paso separado de esta compilación.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
