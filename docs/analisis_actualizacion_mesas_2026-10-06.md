# Análisis de mesas y actualización para todos los usuarios

Fecha de revisión: 6 de octubre de 2026, hora de Argentina.

**Alcance temporal:** las secciones siguientes registran el diagnóstico previo a la corrección. La revisión posterior del recorrido público y los cambios de sincronización están documentados en [Recorrido público y sincronización](recorrido_publico_y_sincronizacion_mesas.md).

## Resultado principal

La aplicación tiene una base compartida para mesas y coloquios: `public.exam_events` en el proyecto Supabase `Correlativas`. Una edición administrativa puede llegar a todos los clientes compatibles conectados sin publicar otro APK. La sincronización de las distintas pantallas está incompleta y el importador Excel funciona como un laboratorio local separado.

Este informe distingue el código del proyecto actual de lo comprobado en el servidor. No se verificó el código interno de la versión instalada por cada usuario ni se modificaron mesas reales para probar su propagación.

## Estado real del servidor

Se consultaron únicamente metadatos, permisos y estadísticas de mesas; no se cambiaron registros.

| Comprobación | Resultado |
| --- | --- |
| Registros en `exam_events` | 191 |
| Visibles y sin marca `legacy` | 66 |
| Marcados como históricos (`legacy`) | 51 |
| Ocultos (`visible = false`) | 74 |
| Fechas futuras desde el 6/10/2026, visibles y no históricas | 0 |
| Última modificación de una mesa | 23/07/2026, 08:12:56 UTC |
| Carreras con registros | Historia, Geografía y Ciencia Política |
| Meses con fechas originales | Mayo, julio y agosto de 2026 |
| Registros sin fecha original | 8 |
| Estados almacenados | 180 activas y 11 suspendidas |
| Historial de cambios | 10 actualizaciones; la última el 23/07/2026 |
| Función `admin-exam-events` | Activa, versión 9, actualizada el 21/07/2026 |
| Realtime para `exam_events` | Habilitado en `supabase_realtime` |
| Identidad de réplica | `FULL` |
| Lectura sin iniciar sesión | Permitida por la política pública de SELECT |

Las cifras de históricos y ocultos se superponen: no son categorías que deban sumarse. «Sin marca legacy» tampoco significa «fecha futura»: los 66 registros visibles incluyen mesas pasadas y sin fecha.

La tabla no tiene columnas de institución, turno académico o versión de publicación. El identificador principal de cada mesa es un UUID; la carrera se guarda como texto y el tipo solo distingue `llamado_1`, `llamado_2` y `coloquio`.

## 1. Cómo se cargan y editan las mesas compartidas

El panel «Mesas y coloquios» usa `RepositorioEventosExamenAdministrador`. Permite crear, editar y eliminar registros mediante la función del servidor `admin-exam-events`.

La función comprueba que el `device_id` enviado corresponde a un dispositivo habilitado en `admin_devices`. Guarda el cambio en `exam_events`, devuelve el registro y escribe datos anteriores/nuevos en `exam_event_change_log`. Los triggers de la tabla actualizan `updated_at`, completan algunos años y normalizan los estados.

El listado público permite una pulsación prolongada a administradores para editar controles rápidos. El detalle tiene un editor de fecha, hora y docentes. Ambos escriben en la misma base compartida: estos cambios no quedan únicamente en el teléfono del administrador.

Los controles remotos disponibles son: fecha/hora, docentes, enlace del acta, acta habilitada, visible/oculta, activa/suspendida/cancelada/reprogramada y título/mensaje del aviso. Una reprogramación conserva la fecha original y requiere nueva fecha y nueva hora.

Hay dos límites funcionales del circuito administrativo:

- El editor completo envía `expected_updated_at`; los controles rápidos y el editor contextual no lo envían. Estos últimos no detectan que otro administrador haya editado la mesa mientras el formulario estaba abierto.
- El modelo administrativo envía `legacy`, pero `buildPayload` de la función desplegada no lo incorpora a la escritura. La clasificación histórica no se puede cambiar de forma fiable por ese camino. El chequeo de versión también se hace antes del UPDATE y no constituye una escritura condicional atómica.

## 2. Cómo reciben los datos los usuarios

`RepositorioExamenes` lee primero los JSON incluidos en la app y después consulta `exam_events` por instancia. Si la consulta remota funciona, usa la lista remota y filtra `visible`. Solo conserva del JSON un acta cuando el registro remoto no trae enlace y coincide carrera, año, materia y fecha original.

Si hay error o transcurren 25 segundos, vuelve al JSON incluido en esa versión de la app. Ese respaldo es de mayo/julio de 2026; no es una copia persistente de la última descarga del servidor. El repositorio no devuelve a la interfaz si los datos provienen del servidor o del respaldo.

Los consumidores llaman seis métodos (julio y mayo para cada instancia), aunque las consultas remotas solo filtran por instancia y no por mes. Se repiten tres consultas; las copias de los métodos antiguos se marcan `legacy` y luego se descartan. Los nombres «julio» no impiden recibir mesas remotas de octubre, noviembre u otro período.

| Pantalla del código actual | Carga | Recepción de cambios |
| --- | --- | --- |
| Listado principal de exámenes | Future propio con consultas al repositorio | Realtime de toda la tabla; recarga tras 250 ms y actualización manual |
| Detalle de una mesa | Registro recibido al abrir y consulta por ID tras un evento | Realtime, identifica la mesa y recarga tras 180 ms |
| Calendario | Future propio al abrir o refrescar | Actualización manual; no tiene suscripción Realtime |
| Buscador principal React y buscador Atlassian | `proveedorTodosLosExamenes` | FutureProvider conservado; no tiene suscripción Realtime ni invalidación compartida |
| Pantallas antiguas de exámenes | Proveedores Riverpod | Actualización manual mediante invalidación |
| Panel administrativo | FutureProvider administrativo | Recarga al guardar/eliminar o al tocar actualizar; no escucha cambios de otros administradores |

El listado y el detalle ya tienen la base de recepción en vivo. Los 250/180 ms son el tiempo de espera para agrupar eventos, no una garantía de entrega: también intervienen la red, Realtime y las consultas de recarga.

Al regresar desde segundo plano no hay una recarga explícita común de mesas. El observador global de la app actualiza presencia del dispositivo, no los exámenes. Realtime puede reconectar, pero no reemplaza una comprobación explícita de cambios perdidos.

## 3. Problemas visibles encontrados

1. **Calendario y detalle pueden discrepar ante una reprogramación.** El calendario coloca el evento usando `event.fecha` y muestra `event.hora`, mientras que el detalle y el orden del listado usan `fechaVigente` y `horaVigente`. Una mesa reprogramada puede aparecer todavía en el día anterior del calendario.
2. **Cambios guardados no invalidan todas las pantallas.** El listado, el calendario y el buscador tienen estados independientes. Una edición remota no refresca el FutureProvider usado por el buscador.
3. **La caché del buscador omite campos relevantes.** Su huella incluye ID, carrera, materia, instancia, fecha/hora vigente y visible, pero omite docentes, división, estado, aviso y acta. Incluso con una lista renovada, un cambio solo en esos campos puede conservar el modelo anterior hasta cambiar la búsqueda.
4. **Educación Física aún no está integrada en mesas.** Ya está visible en el catálogo general, pero el selector público de exámenes y el del calendario enumeran otras cinco carreras. El panel administrativo también omite `fisica`, y el editor de creación restringe las carreras a Historia, Geografía y Ciencia Política. El servidor no tiene mesas de Educación Física.
5. **Falta separar instituciones.** Actualmente una mesa se identifica por carrera, sin una institución como ISEEF. Si se incorporan instituciones que comparten carrera, hay que añadir esa relación al dato remoto y a los filtros.
6. **Sin conexión pueden reaparecer datos antiguos.** Una suspensión, ocultamiento o acta corregida en el servidor no se conserva en el respaldo estático de un cliente. El usuario tampoco ve claramente si se recurrió al respaldo.
7. **El detalle confunde ausencia con error.** `loadById` devuelve null cuando la mesa no existe, pero también ante un timeout/error. El detalle interpreta null como «La mesa ya no está disponible» y se cierra. Además conserva el acta anterior si la consulta nueva no trae enlace.
8. **No hay aviso push de cambios de mesas.** La función desplegada solo guarda y audita. Las funciones de notificaciones existentes y la navegación al tocar una notificación cubren verificaciones, no exámenes.

## 4. Qué hace el laboratorio Excel

Existe otro circuito, accesible desde «Acceso developer»: `PantallaSistemaMesasExcelAtlassian` → `ControladorMesasExcel`.

Descarga el archivo institucional de Google Drive configurado con ID `1zkPX0IK7ikpRA1qpzgdMunEqd5dVFPGz`. Este ID está fijo en el código; reemplazarlo requiere una nueva versión si no se agrega antes configuración remota. Se intentó consultar la vista web en esta revisión, pero la herramienta no pudo acceder; no se certifica aquí el contenido actual del archivo.

El controlador compara ETag/Last-Modified y SHA-256, interpreta XLSX/OOXML, asocia materias con el catálogo y valida las hojas de primer llamado, segundo llamado y coloquios. Rechaza materias ambiguas/sin coincidencia y enlaces de acta sin asociación. Solo activa un conjunto validado.

Guarda el resultado y sus metadatos en SharedPreferences del teléfono (`mesas_excel_active_v1`, con escritura pendiente antes de activar). Puede conservar la copia local ante un error de red. Al inicializar se comprueba la fuente, con un mínimo de 30 minutos entre comprobaciones automáticas cuando existe copia; esto no es una tarea periódica de fondo. Las pantallas ofrecen actualización manual.

Este módulo no escribe en Supabase. El test de aislamiento incluso comprueba que no dependa de `supabase_flutter`. «publicable» en su diagnóstico significa que se puede mostrar ese conjunto dentro del laboratorio; no significa que ya se haya publicado para todos los usuarios.

Las reglas de carreras del importador cubren Historia, Geografía y Ciencia Política. La fuente y el importador todavía no constituyen un mecanismo para publicar mesas del ISEEF.

## 5. Qué cambios llegan a todos y cuáles requieren una versión nueva

| Cambio | Distribución actual |
| --- | --- |
| Corregir una mesa en `exam_events` | Lo reciben clientes compatibles conectados; algunas pantallas necesitan recarga |
| Agregar una mesa de una carrera ya accesible | Puede llegar desde el servidor sin otro APK |
| Editar una copia del laboratorio Excel | Solo cambia ese teléfono; no publica globalmente |
| Cambiar contenido de JSON incluido en la app | Requiere distribuir una versión nueva |
| Añadir selector de Educación Física, institución, nuevos avisos o efectos visuales | Requiere una versión nueva para los clientes |
| Habilitar notificaciones push de mesas | Requiere servidor emisor y soporte/navegación de mesa en los clientes |

No se debe confundir «registrado en el servidor», «recibido por la app abierta» y «notificado a alguien con la app cerrada». Son tres pasos distintos.

## 6. Orden recomendado para los próximos cambios

1. Unificar listado, calendario, buscador y detalle sobre un proveedor compartido de mesas, con una sola suscripción Realtime, recarga al recuperar conexión/volver a la app y caché persistente del último conjunto válido.
2. Corregir el calendario para usar fecha/hora vigentes y corregir la invalidación de resultados de búsqueda. Mostrar origen y momento de la última actualización.
3. Incorporar Educación Física e instituciones en la administración, los filtros y el esquema compartido; mantener compatibilidad con datos y clientes existentes.
4. Definir una publicación administrativa del Excel: descargar → validar → mostrar diferencias → publicar un conjunto completo en el servidor. Usar IDs estables, conservar correcciones manuales y evitar que los usuarios vean un lote parcialmente cargado.
5. Añadir avisos de cambio y, si se necesitan con la app cerrada, notificaciones push dirigidas a las carreras/instituciones relevantes.
6. Comprobar propagación con dos clientes: alta, cambio de hora/docentes, suspensión, reprogramación, acta, ocultamiento/eliminación, desconexión y regreso. El calendario, listado y buscador deben concordar.

## Fuentes y alcance de la verificación

- Código del proyecto: `lib/funcionalidades/examenes/datos/repositorio_examenes.dart`, `lib/funcionalidades/examenes/proveedores/proveedores_examenes.dart`, `lib/funcionalidades/examenes/modelos/evento_examen.dart`.
- Vistas activas: `pantalla_examenes_atlassian.dart`, `pantalla_calendario_atlassian.dart`, `pantalla_busqueda_global_react_developer.dart` y `pantalla_busqueda_global_atlassian.dart`.
- Administración: repositorio y modelo de eventos, sección administrativa y editor de eventos.
- Excel: configuración de fuente/reglas, controlador, descargador, importador, almacenamiento local y entrada developer.
- Servidor: esquema y permisos reales, publicación Realtime, triggers, estadísticas de mesas y código de `admin-exam-events` versión 9.
- Notificaciones: arranque y servicio push; funciones desplegadas.
- Referencia oficial: [Supabase Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes).

La revisión de producción fue de solo lectura. Las pruebas del modelo y del código local no sustituyen una prueba de entrega Realtime o push entre dos dispositivos reales.
