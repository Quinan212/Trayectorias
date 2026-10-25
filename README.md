# Trayectorias

**Tu recorrido académico, en un solo lugar.**

Trayectorias es una aplicación para consultar planes de estudio y correlatividades, organizar exámenes y seguir el avance de una carrera. Se conecta con SAGE para recuperar la trayectoria académica y permite consultar los documentos obtenidos desde el dispositivo.

Está desarrollada con Flutter y Dart, con interfaz en español de Argentina, temas claro y oscuro y navegación que conserva el estado entre secciones.

## Qué podés hacer

| Sección | Para qué sirve |
| --- | --- |
| **Inicio** | Consultar un resumen de tu trayectoria, elegir la carrera activa, conectar SAGE y abrir documentos y herramientas. |
| **Exámenes** | Consultar mesas, aplicar filtros y revisar fechas, docentes, estado y actas cuando están disponibles. |
| **Plan** | Explorar carreras e instituciones, materias por año, requisitos y recursos del plan. |
| **Materias** | Revisar los estados de las materias de tu trayectoria y abrir su detalle académico. |
| **Datos** | Consultar el perfil sincronizado, las carreras y los datos de la copia local, o desincronizar la trayectoria. |

### Conexión con SAGE

- Acceso al portal desde una vista web integrada y opción de sincronizar la trayectoria.
- Detección de perfiles **Alumno/Estudiante** y **Agente/Docente**, con selección cuando la cuenta dispone de ambos.
- Recuperación de la información académica disponible para el perfil estudiante, sus carreras y materias.
- Conservación de la trayectoria en el dispositivo para consultarla al volver a abrir la app.
- Acciones para volver a sincronizar, abrir SAGE o cerrar su sesión.

Las funciones dependen de los permisos de la cuenta y de la información que entregue SAGE. El acceso como agente no implica que se ofrezcan los mismos documentos académicos del perfil estudiante.

### Documentos académicos

La app integra **Situación académica, Analítico y Libreta**. Permite consultar los datos en una pantalla nativa, ver el PDF y compartirlo o abrirlo con otra aplicación cuando existe una copia PDF disponible.

1. La primera vez se obtiene el documento desde SAGE y se conserva el PDF junto con los datos extraídos.
2. Las siguientes aperturas utilizan la copia local válida, incluso después de cerrar y volver a abrir la app, sin repetir el acceso a SAGE.
3. El botón **Actualizar** solicita una nueva versión. Si la operación falla o se cancela, se conserva la copia anterior.

Las copias se identifican por usuario, institución, carrera y tipo de documento. Los datos nativos pueden seguir disponibles aunque falte el archivo PDF.

### Planes, correlatividades y herramientas

- Consulta de materias, requisitos y correlatividades dentro del plan de estudios.
- **Escenarios:** probá estados de las materias y evaluá condiciones de cursada.
- **Próximos pasos:** revisá finales pendientes, cursada activa y materias que requieren atención.
- **Mi avance:** consultá el progreso y los estados de las materias por año.
- **Diseños:** accedé a contenidos curriculares y recursos cuando el catálogo dispone de ellos.
- **Ayuda:** preguntas frecuentes sobre normativa, cursada y trayectorias.

Las herramientas de planificación son orientativas: la información institucional y la normativa vigente determinan las condiciones académicas oficiales.

### Exámenes, calendario y búsqueda

El calendario y el listado de exámenes comparten la misma fuente de mesas. Las modificaciones recibidas desde el servidor actualizan también los detalles y las búsquedas; las reprogramaciones utilizan la fecha y hora vigentes.

El buscador permite encontrar materias, mesas, planes, contenidos curriculares y accesos a herramientas. La navegación conserva filtros y posición de lectura en las secciones ya abiertas.

### Catálogo disponible

El catálogo visible incluye los profesorados de **Historia, Geografía, Ciencia Política, Artes Visuales, Educación Física y Música**.

La disponibilidad de documentos, enlaces y datos varía según carrera e institución. Existen otras carreras declaradas pero ocultas en la configuración; no se presentan como oferta disponible. Consultá la configuración en [datos_catalogo.dart](lib/compartido/proveedores/datos_catalogo.dart).

### Administración y otros módulos

El menú incluye un acceso administrativo con habilitación por dispositivo. Las operaciones y la edición contextual de mesas están sujetas a los controles de acceso existentes.

El repositorio también conserva módulos de verificación, opiniones, biblioteca, importación de mesas desde Excel e interfaces anteriores o experimentales. Su presencia en el código no significa que todos estén accesibles desde el recorrido principal. Los nombres internos `laboratorio`, `atlassian` y `react_developer` son históricos: algunas de esas carpetas contienen la interfaz pública actual.

## Consulta sin conexión

La trayectoria guardada, los documentos ya obtenidos y el catálogo incluido permiten consultar información local. Conectar SAGE, obtener o actualizar documentos y recibir cambios de mesas requiere conexión. Los enlaces y recursos externos también dependen de su disponibilidad.

## Desarrollo

### Requisitos

- Flutter compatible con el rango de Dart declarado en [pubspec.yaml](pubspec.yaml): `>=3.12.0 <4.0.0`.
- Para Android: Android SDK y herramientas de compilación configuradas. El proyecto declara `minSdk 24`, `compileSdk 36` y `targetSdk 36`.
- Acceso a los servicios configurados para probar funciones remotas.

Android es el destino principal de las comprobaciones documentadas. Hay proyectos de plataforma para iOS, Windows, macOS, Linux y web; su presencia no garantiza paridad funcional, especialmente en SAGE y complementos nativos.

### Ejecutar el proyecto

```bash
git clone https://github.com/Quinan212/Trayectorias.git
cd Trayectorias
git switch principal
flutter pub get
flutter run
```

El identificador interno del paquete Dart sigue siendo `correlativas_historia`; el nombre visible de la app es **Trayectorias**. La versión y el número de compilación se declaran en `pubspec.yaml`.

### Servicios y configuración

- **Supabase:** datos remotos, suscripciones y funciones del servidor. El cliente admite `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` y `SUPABASE_ANON_KEY` mediante `--dart-define`.
- **Firebase:** inicialización y soporte de notificaciones según la plataforma y su configuración.
- **SAGE:** acceso mediante WebView, detección de perfiles, extracción de información y obtención de documentos.
- **Almacenamiento local:** preferencias, trayectoria y copias persistentes de documentos.

Para trabajar con un backend propio, revisá las opciones del cliente y los recursos de servidor antes de ejecutar operaciones remotas. Las contraseñas de acceso y el archivo `android/key.properties` permanecen fuera del seguimiento de Git.

### Verificación y compilación

```bash
flutter analyze
flutter test
flutter build apk --release
```

La compilación de distribución requiere la configuración de firma correspondiente. El repositorio conserva `pubspec.lock` para fijar las dependencias y una copia local de `pdfx` en `third_party/pdfx`, referenciada por el proyecto.

**Revisión del 25 de octubre de 2026:** el análisis registró 0 errores, 40 advertencias y 477 observaciones informativas. La suite completa terminó con 419 pruebas correctas y 5 fallidas: dos del listado administrativo, una de la estructura del inicio, una del detalle de Educación Física y otra que requiere el archivo ausente `test/fixtures/mesas_julio_2026.xlsx`. La suite todavía no está completamente en verde.

GitHub Actions ejecuta análisis y pruebas; no publica la app en Google Play. Su versión configurada de Flutter debe revisarse frente al rango de Dart requerido por el proyecto.

## Organización del repositorio

| Ubicación | Contenido |
| --- | --- |
| `lib/main.dart` | Arranque de la aplicación. |
| `lib/compartido/` | Estado, navegación, servicios y componentes comunes. |
| `lib/funcionalidades/` | Pantallas, modelos y lógica por función. |
| `lib/tema/` | Temas de la aplicación. |
| `assets/` | Catálogo, planes, imágenes y otros recursos. |
| `test/` | Pruebas de lógica, interfaz y recorridos. |
| `supabase/` | Migraciones y funciones del servidor. |
| `third_party/pdfx/` | Dependencia local del visor PDF. |
| `docs/` | Notas técnicas y verificaciones. |
| `tool/` | Herramientas de mantenimiento del repositorio. |
| `android/`, `ios/`, `windows/`, etc. | Proyectos de plataforma. |

Las dependencias descargables, cachés, APK y otras compilaciones quedan excluidas mediante `.gitignore` y se regeneran localmente.

## Documentación técnica

- [Recorrido público y actualización de mesas](docs/recorrido_publico_y_sincronizacion_mesas.md).
- [Documentos persistentes y regreso desde el buscador](docs/documentos_persistentes_y_regreso_buscador_775_2026-10-07.md).
- [Sincronización de pantallas y movimiento](docs/sincronizacion_pantallas_y_movimiento_2026-10-07.md).
- [Escenarios y calculadora](docs/escenarios_calculadora_775_2026-10-07.md).
- [Reglas de conservación de UTF-8](AGENTS.md).

Las notas de `docs/` describen revisiones concretas y pueden mencionar entregas o archivos de comprobación locales que no forman parte del repositorio.
