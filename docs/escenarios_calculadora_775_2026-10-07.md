# Escenarios y calculadora — release +775

Se mejoraron las dos interfaces que usan la evaluación de correlatividades. Las reglas de evaluación y los datos académicos conservan su implementación.

## Cambios

- Tema local para estas pantallas: fondo negro en oscuro, tarjetas neutras y colores de texto, bordes y selección con mayor contraste. El tema claro conserva el fondo claro y usa textos más definidos.
- Entrada breve de contenido, respuesta al toque y cambio de resultado con el ritmo de MovimientoApp. La transición conserva un único resultado, sin apilar textos del escenario anterior. Las animaciones nuevas respetan la opción del sistema para reducir movimiento.
- Las opciones no regularizada, regularizada y aprobada conservan su tamaño al seleccionarse. Se distribuyen en varias filas cuando no caben, con blancos táctiles de al menos 48 puntos.
- Área segura inferior en Escenarios y calculadora, más separación al final del scroll. Los selectores de carreras y años pueden desplazarse; la búsqueda de materias limita su altura al espacio disponible y reserva el espacio del teclado.
- El controlador de búsqueda de materias vive hasta que la hoja termina de cerrarse. Se corrigió el error de uso del controlador después de dispose detectado en las pruebas con teclado.
- Volver a elegir la misma carrera, año o materia conserva el escenario actual.

## Verificación

Se ejecutaron 220 pruebas de interfaz y regresión: documentos académicos, documentos persistentes, Libreta, recorridos del buscador, movimiento, SAGE, temas y revisión de mojibake. Todas pasaron. Después del último ajuste de distribución de opciones, se ejecutaron las 17 pruebas específicas de Escenarios/calculadora; todas pasaron.

Estas pruebas comprueban ambas interfaces y ambos temas, insets inferiores de 24 y 48 puntos, viewport de 360 × 640, textos ampliados al doble, selector con teclado de 290 puntos, escritorio de 1400 × 900, selección de correlativas sin superposición de resultados y aislamiento del tema. El contraste de los textos del resultado y sus capacidades alcanza al menos 4,5:1 en ambos temas.

flutter analyze final: 0 errores, 40 warnings y 477 infos preexistentes. No se añadieron diagnósticos respecto de la versión previa; se resolvieron dos infos de const redundante. El comando conserva su salida no cero por los avisos existentes.

Se compilaron APK release x64 y ARM64 sin split-per-abi: versión 1.3.071026, versionCode 775, firma del proyecto verificada. El release x64 final quedó instalado con adb install -r en emulator-5556, conservando los datos.

En el emulador se comprobó Escenarios en claro y oscuro: elección de carrera y materia, todas las opciones de estado visibles y resultado habilitado al aprobar las correlativas. El resultado y su último texto quedan por encima de la navegación gestual de Android. Las pruebas cubren además el margen equivalente a navegación de tres botones; no se modificó el modo de navegación del dispositivo. Se restauró el modo oscuro del emulador y se guardó su snapshot.

El archivo del buscador, tema global Atlassian y pubspec.yaml conservan sus hashes previos. El resto de herramientas en pantallas_herramientas_atlassian.dart, desde PantallaAyudaAtlassian, conserva su contenido exacto. SAGE y el repositorio de documentos no se modificaron.

## Entrega

[APK release ARM64 en Drive](https://drive.google.com/file/d/1LnfKyzPer0HkAOgEsH70m-d0JM8lQnmk/view?usp=drivesdk), verificado con lectura de metadatos: 34.936.950 bytes. Enviado al chat propio de WhatsApp; confirmó “Leído” a las 7:38 a. m. del 7 de octubre de 2026.

Los dos APK y sus SHA-256 están registrados en build/qa/775_escenarios_apk.json. Comprobantes visuales: build/qa/escenarios_resultado_final_oscuro.png, escenarios_resultado_final_claro.png y 775_escenarios_whatsapp_enviado.png.

## Archivos revisados

- lib/funcionalidades/laboratorio_atlassian/pantallas/pantallas_herramientas_atlassian.dart
- lib/funcionalidades/calculadora/pantalla/pantalla_calculadora.dart
- lib/funcionalidades/calculadora/pantalla/tema/estilos_calculadora.dart
- lib/funcionalidades/calculadora/pantalla/componentes/tarjeta_espera_calculadora.dart
- lib/funcionalidades/calculadora/panel/panel_estilos.dart
- lib/funcionalidades/calculadora/panel/panel_requisitos.dart
- lib/funcionalidades/calculadora/panel/panel_evaluacion.dart
- lib/funcionalidades/calculadora/panel/panel_resultado.dart
- lib/funcionalidades/calculadora/pantalla/componentes/contenido_animado_calculadora.dart
- test/calculadora/escenarios_calculadora_test.dart
- docs/escenarios_calculadora_775_2026-10-07.md

Los ocho archivos existentes se leyeron como UTF-8 antes de editar y se respaldaron en build/qa/respaldo_escenarios_calculadora_775_20261007. No había corrupción preexistente. Los archivos nuevos se guardaron como UTF-8 sin BOM. Se conservaron los saltos LF y se revisaron textos con tildes, ñ y símbolos académicos en las capturas de ambos temas.

Validación anti-mojibake completada. Los archivos modificados fueron leídos nuevamente como UTF-8, se buscaron secuencias sospechosas y se revisaron los textos visibles afectados.
