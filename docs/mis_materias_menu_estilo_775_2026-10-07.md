# Mis materias y menú de búsqueda — release 1.3.071026+775

Aplicación del estilo aprobado de Escenarios, calculadora y Exámenes. Cambios locales en la presentación; la trayectoria persistida de SAGE continúa siendo la fuente de datos.

## Cambios

- Mis materias y su detalle comparten la paleta de las pantallas aprobadas, con etiquetas de estado legibles en claro y oscuro, indicadores animados y respuesta al toque de 60/120 ms.
- Los grupos de materias entran con el ritmo común de 240 ms. Los filtros reemplazan el contenido vigente de forma inmediata y animan su entrada, evitando la superposición de listados.
- Cabecera adaptada al tamaño de texto. Filtros y hojas de selección desplazables con texto grande. Las filas de “Mismo año” conservan la misma alineación.
- Área segura inferior y margen para la barra independiente de búsqueda. Se conserva Volver hacia el menú que originó la navegación.
- Menú de búsqueda: degradados conservados, textos secundarios con mayor contraste, bordes claros y respuesta al toque común. Las tarjetas tienen altura adaptable y las herramientas ancho adaptable al texto.
- Entrada coordinada por grupo al terminar el skeleton, conservando los elementos y sus posiciones. La barra de búsqueda permanece en su propia capa.
- Retirado el desenfoque de fondo de las tarjetas de acceso; sus degradados ya son opacos. Dos animaciones de entrada breves, sin animación continua adicional.
- Carrusel de instituciones con altura calculada según texto y distribución de acciones. Scroll del menú recortado antes de la navegación de Android.
- Componentes visuales de Exámenes extraídos a un archivo compartido. Comparación de código confirma que filtros, datos, navegación y administración de Exámenes conservan su implementación.

## Validación

- `flutter test --no-pub`: **263 pruebas pertinentes aprobadas**, incluidas navegación, barra de búsqueda, skeleton y demora 2000/1500/1000/500/0 ms, materias, Exámenes, calculadora, documentos locales y sincronización SAGE. Log: [regresión](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_materias_menu_regresion_entrega.log).
- **23 pruebas de presentación aprobadas** después de añadir la comprobación de alineación del detalle y del área segura del menú: [presentación](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_materias_menu_alineacion_area_segura.log).
- Contraste de etiquetas y textos de tarjetas comprobado ≥ 4,5:1 en ambos temas, pantallas 360×640 y escalas de texto 1×/2×; movimiento reducido respetado.
- `flutter analyze --no-pub`: **0 errores**. Permanecen 40 warnings y 477 infos del proyecto, sin nuevos diagnósticos frente al release anterior. El comando sale con código 1 por esos diagnósticos preexistentes: [análisis](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_materias_busqueda_analyze_final.log).
- El test del importador Excel no forma parte de esta ejecución: sigue faltando el recurso preexistente `test/fixtures/mesas_julio_2026.xlsx`. Se ejecutaron los tests de skeleton del laboratorio de mesas.
- APK release x86_64 instalado con `adb install -r` en `emulator-5556`, conservando datos. Revisión visual en ambos temas y recorrido detalle → Mis materias → menú de búsqueda. La trayectoria guardada, notas y fechas continúan visibles. Tema oscuro restaurado y snapshot `default_boot` guardado.
- APK para teléfono ARM64 firmado con el certificado del proyecto y build **+775**; versión y biblioteca Flutter verificadas. [Verificación de APK](C:/Users/alan/Desktop/Correlativas-principal/build/qa/775_materias_busqueda_apk_verificados.json).
- Google Drive: [Trayectorias-1.3.071026-775-materias-busqueda-arm64-release.apk](https://drive.google.com/file/d/139Sl5LUMrXI56UoDBUMB-Xm5nhR6UmBQ/view?usp=drivesdk). Subida confirmada mediante lectura de metadatos: 34936950 bytes, coincidentes con el archivo local.
- WhatsApp: pendiente. Chrome no está conectado y el navegador interno solicita iniciar sesión; no hay sesión disponible para enviar al chat personal.

## Archivos revisados

- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_materias_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/pantallas/pantalla_examenes_atlassian.dart)
- [lib/funcionalidades/laboratorio_atlassian/componentes/componentes_academicos_app.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/componentes/componentes_academicos_app.dart)
- [lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart](C:/Users/alan/Desktop/Correlativas-principal/lib/funcionalidades/laboratorio_atlassian/busqueda/pantalla_busqueda_global_react_developer.dart)
- [test/laboratorio_atlassian/presentacion_mis_materias_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/presentacion_mis_materias_test.dart)
- [test/laboratorio_atlassian/presentacion_menu_busqueda_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/presentacion_menu_busqueda_test.dart)
- [test/laboratorio_atlassian/modo_claro_react_developer_test.dart](C:/Users/alan/Desktop/Correlativas-principal/test/laboratorio_atlassian/modo_claro_react_developer_test.dart)

Además de este informe, se validaron los JSON de auditoría generados como UTF-8 sin BOM. Los originales afectados tienen copias en `build/qa/respaldo_mis_materias_775_20261007`. El tema global y `pubspec.yaml` mantienen sus hashes anteriores.

## Capturas del release final

[Mis materias, claro](C:/Users/alan/Desktop/Correlativas-principal/build/qa/mis_materias_final_claro.png) · [Mis materias, oscuro](C:/Users/alan/Desktop/Correlativas-principal/build/qa/mis_materias_final_oscuro.png) · [Detalle, claro](C:/Users/alan/Desktop/Correlativas-principal/build/qa/materia_detalle_final_claro.png)

[Menú de búsqueda, claro](C:/Users/alan/Desktop/Correlativas-principal/build/qa/menu_busqueda_final_claro.png) · [Menú de búsqueda, oscuro](C:/Users/alan/Desktop/Correlativas-principal/build/qa/menu_busqueda_final_oscuro.png)

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
