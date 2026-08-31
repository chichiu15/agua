# COSAALT — Módulo Medidores · Contexto de Desarrollo

Documento de contexto para que una IA (o dev nuevo) entienda qué se está construyendo: arquitectura, estructura de carpetas y funciones de cada parte. Generado fiel al código actual.

## Vista general

Sistema de **gestión y cambio de medidores** para la cooperativa COSAALT (que empresas de servicios de agua usan para asignar y ejecutar trabajos de campo).

- **Frontend:** aplicación Flutter multiplataforma (Android / Windows / Web).
- **Backend:** API REST en .NET (ASP.NET Core Web API + EF Core + SQL Server).
- **Flujo principal:** el *asignador* arma un recorrido (selecciona solicitudes en un mapa, les da orden y las asigna a un técnico) → el *técnico* ve su recorrido del día, ejecuta cada parada (registra datos y fotos de cambio de medidor) → los datos se guardan localmente y luego se **sincronizan** al servidor → el *historial* muestra las ejecuciones.

**Roles:**
- `asignador` — arma y asigna recorridos, monitorea el avance, ve historial.
- `tecnico` — ve su recorrido del día, ejecuta cambios de medidor, sincroniza.

**Persistencia:** SQL Server en esquema `medidores` para las tablas propias del módulo, y tablas `dbo` (Reclamos, Conexiones, etc.) que se usan como fuente de datos legacy (solicitudes ODECO).

---

## 1. Estructura de .NET (`Cosaalt.API/`)

Backend REST con arquitectura en capas (Controllers → Services → Repositories → EF Core → SQL Server).

```
Cosaalt.API/
├── Program.cs                          # Bootstrap: DI, Swagger, CORS, EF Core, Seed, esquemas
├── Controllers/                        # Capa HTTP (endpoints)
│   ├── AuthController.cs               # POST /api/auth/login
│   ├── SolicitudesController.cs        # GET  /api/solicitudes, GET /api/solicitudes/{id}
│   ├── UsuariosController.cs           # GET  /api/usuarios/tecnicos
│   ├── CatalogosController.cs          # GET  /api/catalogos/motivos
│   ├── RutasController.cs              # POST /api/rutas/asignar, GET /api/rutas/tecnico/{id}, GET /api/rutas/{id}
│   ├── EjecucionesController.cs        # POST /api/ejecuciones, GET /api/ejecuciones/historial
│   ├── EvidenciasController.cs         # POST /api/evidencias/upload (multipart)
│   └── SincronizacionController.cs     # POST /api/sincronizacion/procesar-cambios
├── Application/
│   ├── DTOs/                           # Records de entrada/salida por dominio
│   │   ├── AuthDtos.cs                 # LoginRequest, LoginResponse
│   │   ├── SolicitudDtos.cs            # SolicitudBandejaDto, DashboardResumenDto, SolicitudesResponse
│   │   ├── RutaDtos.cs                 # TecnicoDto, DetalleRuta*, AsignarRutaRequest/Response, RutasTecnicoResponse
│   │   ├── EjecucionDtos.cs            # EjecucionCambioRequest/Response, EvidenciaFoto, EjecucionHistorial
│   │   ├── EvidenciaDtos.cs            # UploadEvidenciaResponse
│   │   ├── CatalogoDtos.cs             # Motivo
│   │   └── SincronizacionDtos.cs       # SincronizacionRequest/Response/Estado
│   ├── Mappers/
│   │   └── EntityMappers.cs            # DTO <-> Entidad (Ejecucion, Evidencia, Ruta, ...)
│   └── Services/
│       └── AppServices.cs              # AuthService, CatalogoService, SolicitudService, EjecucionService, UsuarioService, RutaService, SincronizacionService
├── Domain/
│   └── Entities/                       # Entidades de negocio (mapeadas a tablas)
│       ├── Propias del módulo: AsignacionRuta, DetalleRuta, EjecucionCambio, EvidenciaFotografica, UsuarioApp, MotivoCambioMedidor, Socio, Medidor
│       └── Legacy/dbo: Conexion, Predio, Reclamo, ReclamoOdeco, Recurrente, Persona, Funcionario, Barrio, Calle, Zona, CategoriaConexion, TipoConexion, ClaseMedidor, SolicitudLectura, DetalleSolicitudLectura
└── Infrastructure/
    ├── Context/
    │   └── CosaaltDbContext.cs         # DbContext + crea esquema "medidores"
    ├── Configurations/                 # Mapeo columna a columna con EF (una por entidad)
    ├── Repositories/
    │   ├── IRepositories.cs            # Interfaces de repositorio
    │   ├── SqlRepositories.cs          # Auth, Catalogo, Ejecucion, Historial (SQL real)
    │   ├── SqlRepositories.RutasUsuariosSincronizacion.cs  # Rutas, Usuarios, Sincronizacion (SQL real)
    │   ├── SolicitudVirtualService.cs  # Solicitudes ODECO virtuales desde dbo.Reclamos/Conexiones
    │   ├── MockRepositories.cs         # Implementaciones en memoria (modo Mock)
    │   └── CambioMedidorPersistence.cs # Helper de persistencia de ejecución
    ├── Seed/
    │   └── DatabaseSeeder.cs           # Siembra datos demo al arrancar (modo Sql)
    └── Migrations/                     # Migraciones EF (InitialCreate)
```

### Nota clave de arquitectura (importante para no romper)

- `Program.cs` lee `RepositoryMode` de configuración (`appsettings.json`). Puede ser `"Sql"` (SQL Server real) o `"Mock"` (en memoria). **Actualmente está en `"Sql"`.**
- **ADVERTENCIA histórica:** las implementaciones SQL de Rutas/Usuarios/Sincronización viven en `SqlRepositories.RutasUsuariosSincronizacion.cs`. Antes, aunque el modo fuera `"Sql"`, esas tres caían al Mock (se perdía todo al reiniciar la API); ya se cablearon a las versiones SQL.
- `SolicitudVirtualService` genera las solicitudes **ODECO** leyendo de `dbo.Reclamos` + `dbo.Conexiones` → `medidores.Socio` → `medidores.Medidor` por nombre (el socio se vincula a la conexión por `NomSoc`). Es la fuente real de la bandeja.
- La API corre sobre el perfil `http` en **`http://localhost:5034`**.
- Fotos subidas se guardan en `wwwroot/uploads/{idOrigen}/` y se sirven con `UseStaticFiles()` (ej. `/uploads/5/xxxx.jpg`).

### Endpoints resumidos

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/auth/login` | Autentica y devuelve token |
| GET | `/api/solicitudes` | Bandeja de solicitudes (ODECO + resumen) |
| GET | `/api/solicitudes/{id}` | Detalle de una solicitud (ODECO-x) |
| GET | `/api/usuarios/tecnicos` | Lista técnicos activos (con flag si tienen ruta hoy) |
| GET | `/api/catalogos/motivos` | Catálogo de motivos de cambio |
| POST | `/api/rutas/asignar` | Crea una asignación de ruta a un técnico |
| GET | `/api/rutas/tecnico/{id}` | Rutas de un técnico (por fecha, default hoy) |
| GET | `/api/rutas/{id}` | Detalle de una ruta por id |
| POST | `/api/ejecuciones` | Registra una ejecución |
| GET | `/api/ejecuciones/historial` | Historial de cambios de medidor (top 100, desc) |
| POST | `/api/evidencias/upload` | Sube una foto (multipart) y devuelve `rutaArchivo` |
| POST | `/api/sincronizacion/procesar-cambios` | Procesa el lote de ejecuciones pendientes |

### Modelo de datos principal (esquema `medidores`)

- **AsignacionRuta** — cabecera: técnico asignado, fecha, estado (Planificado/EnCurso/Completada).
- **DetalleRuta** — paradas de la asignación: orden de visita, tipoOrigen/idOrigen (ej. `ODECO`/`5`), estado, snapshot (cliente/dirección/lat/long).
- **EjecucionCambio** — registro de un cambio realizado: medidor retirado/instalado, lectura, motivo, coords, técnico, fecha.
- **EvidenciaFotografica** — fotos (medidor retirado/nuevo) con `RutaArchivoServidor` (la ruta relativa que devuelve el upload).
- **UsuarioApp** — usuarios y roles.
- **MotivoCambioMedidor** — catálogo de motivos.
- **Socio** / **Medidor** — padrones. `Socio.Reg_soc`, `Nom_soc`; `Medidor.Nro_medidor`, `Marca_medidor`, `Estado_medidor`.

---

## 2. Estructura de Flutter (`cosaalt_medidores/lib/`)

App Flutter con **Riverpod** (gestión de estado) y **go_router** (navegación). Organizada por *features* (clean/feature-first: data, domain, presentation).

```
lib/
├── main.dart                           # Punto de entrada (runApp CosaaltApp)
├── app/
│   ├── app.dart                        # MaterialApp.router + tema + router
│   └── router/
│       └── app_router.dart             # Rutas & redirects por rol (asignador/tecnico)
├── core/
│   ├── config/
│   │   └── api_config.dart             # baseUrl http://localhost:5034 + endpoints
│   ├── theme/
│   │   ├── app_colors.dart             # Paleta (verde institucional, rojo ODECO...)
│   │   └── app_theme.dart              # ThemeData
│   └── widgets/
│       └── dashboard_widgets.dart      # CosaaltAppBar, CosaaltBottomNav, SummaryMetricCard, QuickActionTile
└── features/                           # Funcionalidad por dominio
    ├── auth/                           # Login + sesión
    │   ├── data/repositories/api_auth_repository.dart
    │   ├── domain/entities/app_user.dart
    │   ├── domain/repositories/auth_repository.dart
    │   └── presentation/controllers/auth_controller.dart, screens/login_screen.dart
    ├── home/
    │   └── presentation/screens/
    │       ├── asignador_dashboard_screen.dart   # Dashboard asignador (tabs)
    │       └── tecnico_dashboard_screen.dart     # Dashboard técnico (tabs)
    ├── recorrido/                      # Recorridos: bandeja, armar, asignar, ver recorrido
    │   ├── data/repositories/api_solicitud_repository.dart
    │   ├── domain/entities/ (solicitud, punto_recorrido, ruta_asignada, tecnico)
    │   ├── domain/repositories/solicitud_repository.dart
    │   └── presentation/
    │       ├── controllers/ (solicitud_controller, detalle_recorrido_controller)
    │       └── screens/ (armar_recorrido_scaffold, paso1..paso3, detalle_recorrido)
    ├── ejecucion_cambio/               # Formulario de ejecución del cambio de medidor
    │   ├── data/repositories/ejecucion_repository_impl.dart
    │   ├── data/services/evidencia_local_service.dart   # Captura y guarda fotos local
    │   ├── domain/entities/cambio_medidor.dart
    │   ├── domain/repositories/ejecucion_repository.dart
    │   └── presentation/controllers/cambio_medidor_controller.dart, screens/cambio_medidor_screen.dart
    ├── sincronizacion/                 # Subida del trabajo offline al servidor
    │   ├── data/repositories/api_sync_repository.dart
    │   ├── data/services/sync_local_service.dart      # Lee/borra drafts JSON locales
    │   └── presentation/controllers/sync_controller.dart, screens/sincronizacion_screen.dart
    ├── historial/                      # Historial de ejecuciones
    │   ├── data/repositories/api_historial_repository.dart
    │   ├── domain/entities/ejecucion_historial.dart
    │   └── presentation/controllers/historial_controller.dart, screens/historial_screen.dart
    └── monitoreo/                      # Monitoreo de avance de rutas (asignador)
        ├── presentation/controllers/monitoreo_controller.dart
        └── presentation/screens/ (monitoreo_tecnicos_screen, detalle_monitoreo_ruta_screen)
```

### Notas de arquitectura del frontend

- **Estado (Riverpod):** cada feature tiene un `Notifier`/`Controller` + un `Provider`. La UI "escucha" el estado y los controladores ejecutan acciones (que llaman a repositorios HTTP).
- **Navegación (go_router):** rutas centralizadas en `AppRoutes`. El router redirige por rol: no autenticado → `/login`; asignador no puede entrar a rutas de técnico y viceversa.
- **Patrón View/Contenido reutilizable:** varias "View" (`MiRecorridoView`, `HistorialView`, `SincronizacionView`) se embeben tanto en pantallas standalone (rutas dedicadas, sin footer) como en las **pestañas de los dashboards** (con footer `CosaaltBottomNav`).
- **Config de API:** `ApiConfig.baseUrl = 'http://localhost:5034'` — todos los repositorios la usan.
- **Doble persistencia local (offline-first):**
  - Datos de ejecución → JSON en `Documents/cosaalt_medidores/pendientes/<localId>.json` (solo app de escritorio/Android; en web no hay guardado local).
  - Fotos de evidencia → archivos en `Documents/cosaalt_medidores/evidencias/<solicitudId>/`.

---

## 3. Lista de pantallas y qué hace cada una

### Autenticación
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Login | `features/auth/screens/login_screen.dart` | Pantalla de inicio de sesión: logo, usuario y contraseña, valida y redirige por rol según el token que devuelve el backend. |

### Dashboards (con footer de navegación inferior)
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Dashboard Asignador | `features/home/screens/asignador_dashboard_screen.dart` | Resumen del día (ODECO urgentes, lecturas, completadas hoy, técnicos activos/en campo) + atajos rápidos (armar recorrido, ver asignaciones, ver mi recorrido). Pestañas: Inicio / Mi Recorrido / Historial / Sincronizar. |
| Dashboard Técnico | `features/home/screens/tecnico_dashboard_screen.dart` | Dashboard del técnico (métricas placeholder) + atajos (ver mi recorrido, probar cambio de medidor en dev). Pestañas iguales (Inicio / Mi Recorrido / Historial / Sincronizar). |

### Recorrido (asignador)
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Paso 1 · Seleccionar solicitudes | `features/recorrido/screens/paso1_seleccionar_screen.dart` | Muestra las solicitudes sobre un **mapa** (OpenStreetMap) con filtros (ODECO/Lectura/Vencidas/Asignadas). El asignador toca los puntos para seleccionar cuáles van al recorrido. |
| Paso 2 · Reordenar | `features/recorrido/screens/paso2_reordenar_screen.dart` | Lista reordenable (drag & drop) de las solicitudes seleccionadas para fijar el orden de visita. Botón "Sugerir orden" (placeholder). |
| Paso 3 · Asignar técnico | `features/recorrido/screens/paso3_asignar_tecnico_screen.dart` | Elige entre los técnicos disponibles (o "asignarse a mí") y confirma la asignación de la ruta. |
| Contenedor del asistente | `features/recorrido/screens/armar_recorrido_scaffold.dart` | Scaffold común de los pasos: título "ARMAR RECORRIDO", subtítulo del paso, botón primario/secundario y footer. |
| Mi Recorrido (detalle) | `features/recorrido/screens/detalle_recorrido_screen.dart` | Muestra la ruta asignada del día, su avance (X de Y completadas, barra de progreso) y las **paradas**. Cada parada tiene botón "IR / EJECUTAR" si está pendiente, o se muestra "Completada" si ya se hizo. |

### Ejecución de cambio de medidor (técnico)
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Cambio de medidor | `features/ejecucion_cambio/screens/cambio_medidor_screen.dart` | Formulario de la visita: muestra tarea/dirección/socio/medidor activo; captura lectura de retiro, motivo, número/marca/estado del medidor nuevo, observaciones y las **2 fotos de respaldo** (medidor retirado y nuevo). Botón "GUARDAR DATOS LOCALMENTE" persiste el borrador local y vuelve al recorrido marcando la parada como Completada. |

### Sincronización (offline → servidor)
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Sincronización | `features/sincronizacion/screens/sincronizacion_screen.dart` | Muestra cuántos cambios pendientes hay guardados localmente, fecha de última sync y botón "SINCRONIZAR". Al sincronizar: sube las fotos al servidor y envía el lote de ejecuciones, luego limpia los borradores locales. |

### Historial
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Historial | `features/historial/screens/historial_screen.dart` | Lista las ejecuciones de cambio de medidor **sincronizadas** (lee el backend). Cada tarjeta muestra fecha, cliente, dirección, medidor retirado → instalado, lecturas, motivo, técnico, registro socio y miniaturas de las fotos (con visor ampliado). |

### Monitoreo (asignador)
| Pantalla | Archivo | Qué hace |
|----------|---------|----------|
| Monitoreo de asignaciones | `features/monitoreo/screens/monitoreo_tecnicos_screen.dart` | Lista las rutas asignadas hoy a cada técnico con su **progreso** (barra + %, completadas/pendientes) y estado. Al tocar una ruta abre su detalle. |
| Detalle de ruta (monitoreo) | `features/monitoreo/screens/detalle_monitoreo_ruta_screen.dart` | Detalle de una ruta: porcentaje de avance global y desglose de cada punto con su estado (Completada / estado actual). Solo lectura para el asignador. |

---

## Credenciales de demo y datos de arranque

- Técnico: `tecnico1` / `123456` (Juan Pérez García, id 25).
- Asignador: `admin` / `admin123` (id 30).
- La bandeja de solicitudes ODECO sale de `dbo.Reclamos` (5 reclamos, CodRec 1–5) + `dbo.Conexiones`, resueltas a socio/medidor por nombre (`Conexiones.NomSoc` == `medidores.Socio.Nom_soc`).

## Cómo levantar el entorno

1. **Backend:** `dotnet run --project Cosaalt.API` (o el exe) sobre el perfil `http` → `http://localhost:5034`. En modo `Sql` siembra datos y crea el esquema `medidores`.
2. **Frontend:** desde `cosaalt_medidores/`: `flutter run -d windows` (o el emulador/web). Apunta a la API local.
3. **Docs API:** Swagger en `/swagger`.
```
