# Recorrido público y sincronización de mesas

Revisión del 6 de octubre de 2026. Se siguieron los constructores y las acciones desde `main.dart`; los nombres de carpetas «laboratorio» y «developer» no determinan qué es público.

## Lo que abre actualmente la aplicación

`main.dart` → `PantallaLaboratorioAtlassian(hideExit: true)` → cinco secciones con navegadores conservados. Desde la revisión del 7 de octubre, `SeccionesMovimientoApp` coordina su entrada, conserva el estado y pausa los efectos de las secciones ocultas.

| Recorrido real | Implementación | Alcance |
| --- | --- | --- |
| Inicio | `PantallaInicioReactDeveloper` | Público; el diseño React ya es el inicio principal |
| Exámenes | `PantallaExamenesAtlassian` | Listado público; edición contextual solo para dispositivos administradores |
| Calendario | Inicio → acceso Calendario, o destino del buscador | `PantallaCalendarioAtlassian`, público |
| Detalle de mesa | Listado, calendario o resultado del buscador | `PantallaDetalleExamenAtlassian`, público |
| Búsqueda del Inicio | `_openReactSearch` | `PantallaBusquedaGlobalReactDeveloper`, pública |
| Búsqueda de Exámenes, Plan y Datos | `_openGlobalSearch` | `PantallaBusquedaGlobalAtlassian`, pública |
| Plan, Materias y Datos | Secciones 2, 3 y 4 del contenedor | Vistas Atlassian públicas |
| SAGE | Inicio → abrir SAGE, sincronizar o descargar documento | Usa `PantallaSageLaboratorio` como motor del flujo público |
| Administración | Menú del contenedor → acceso administrador | Las operaciones se habilitan según el dispositivo |

El contenedor conserva las secciones ya abiertas. Por eso una copia cargada al entrar no se renovaba necesariamente al volver a esa sección: la pantalla seguía montada.

## Ensayos y recorridos anteriores

| Implementación | Dónde aparece en el código | Situación en el recorrido actual |
| --- | --- | --- |
| `PantallaInicioAtlassian` original | Define acceso developer y un Inicio React experimental | No se instancia desde el contenedor principal actual; React ya lo reemplazó |
| `PantallaAccesoDeveloperAtlassian` | La abre el Inicio Atlassian original con `ENABLE_DEVELOPER_LEGACY` | No hay entrada desde el Inicio React público actual |
| Mesas Excel | Acceso developer → «Exámenes desde Excel» | Laboratorio local separado; no es la fuente de Exámenes públicos |
| Modo legacy | Acceso developer → modo legacy | Inicio histórico, mapa, calculadora y preguntas; sus accesos externos están desactivados |
| `PantallaLaboratorioSage` | Acceso de estudiante antiguo | Contenedor de ensayo distinto del motor SAGE que usa el Inicio público |
| Liquid Glass | Acceso de estudiante antiguo → laboratorio de interfaces | Usa la vista antigua de exámenes; no reemplaza el listado público actual |
| Acceso de estudiante antiguo | Inicio de mapa histórico con accesos externos | No es el inicio de `main.dart`; los ensayos se alcanzaban desde ese recorrido |

La revisión anterior mencionaba el acceso developer del Excel sin dejar claro que no pertenece al Inicio público actual. Este documento precisa esa diferencia. No se cambiaron entradas, permisos ni diseños de esos laboratorios.

## Qué significaba «pueden quedar desactualizados»

El servidor y las consultas funcionaban. Lo incompleto era la coordinación de las copias en memoria:

1. Exámenes y detalle tenían suscripciones propias a cambios del servidor.
2. El calendario conservaba un Future propio y solo recargaba manualmente.
3. Ambos buscadores utilizaban otro FutureProvider, sin suscripción a cambios.
4. React reconocía algunos cambios de la mesa en su caché; Atlassian comparaba principalmente cantidades. Cambiar únicamente docentes, estado o acta podía conservar el resultado anterior con la misma consulta.
5. El calendario y partes del buscador Atlassian usaban la fecha original en reprogramaciones.

Eso no implica que todos los teléfonos estuvieran mostrando datos incorrectos: el caso concreto era editar una mesa con esas pantallas ya abiertas y reutilizar sus datos anteriores.

## Corrección realizada

- Se comparte `proveedorTodosLosExamenes` entre listado, calendario, detalle y ambos buscadores, conservando sus filtros y diseños.
- Una suscripción `exam-events-shared` escucha altas, cambios y eliminaciones. Agrupa eventos durante 250 ms e incrementa una revisión compartida.
- La suscripción confirmada, incluida una reconexión, solicita otra descarga para recuperar cambios perdidos. Volver a la app también solicita actualización.
- La revisión compartida renueva el panel administrativo abierto, además de las vistas públicas.
- La carga pública consulta las tres instancias; ya no repite las tres consultas históricas que después se descartaban.
- Actualizar manualmente desde listado, calendario o detalle administrativo renueva la misma fuente para todas las vistas.
- Las cachés de búsqueda se reconstruyen al recibir una nueva lista, incluso cuando solo cambian docentes, estado, aviso o acta.
- Calendario y buscador Atlassian usan fecha y hora vigentes. Una reprogramación conserva su fecha original solo como información histórica en el detalle.
- Un error de conexión al comprobar una mesa no se interpreta como eliminación ni cierra su detalle.
- Se conserva el contenido previo del listado/calendario mientras se descarga una actualización, para evitar reemplazarlo innecesariamente por esqueletos.

Estas correcciones de interfaz y coordinación requieren distribuir una nueva versión de la app. Las futuras ediciones de mesas siguen llegando desde el servidor a los clientes que incorporen esta versión.

## Límites que siguen pendientes

No se publicaron mesas nuevas ni se cambiaron registros reales. El Excel sigue separado, no se añadió el envío push, no se incorporó el esquema de instituciones y no se reemplazó el respaldo JSON antiguo por una caché persistente. Esos puntos del diagnóstico inicial siguen siendo trabajos distintos.

## Verificación

Las pruebas de sincronización utilizan las pantallas públicas reales con un repositorio remoto simulado. Cubren cambios con listado/calendario/detalle/buscadores abiertos, reprogramación, docentes y acta con la misma consulta, regreso desde segundo plano y agrupación de avisos. El servidor se consulta únicamente en lectura; no se altera una mesa de usuarios para ensayar la entrega.

Archivos principales: repositorio/proveedores de exámenes, servicio de sincronización, proveedor administrativo, vistas públicas de listado/calendario/detalle y ambos buscadores. Los textos y archivos se mantienen en UTF-8.

La revisión posterior de herramientas, trayectoria y animaciones está en [Sincronización de pantallas y movimiento](sincronizacion_pantallas_y_movimiento_2026-10-07.md).
