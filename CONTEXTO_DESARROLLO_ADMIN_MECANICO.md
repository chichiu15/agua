# COSAALT — Módulo Medidores · Contexto de Desarrollo (Admin y Mecánico)

Documento de contexto para que una IA (o dev nuevo) entienda qué se está construyendo en los módulos de **administrador** y **mecánico**: arquitectura, estructura de carpetas y funciones de cada parte, fiel al código actual y al plan `Tareas_Administrador_Mecanico.md`.

> Complementa a `CONTEXTO_DESARROLLO.md` (que describe la base asignador/técnico). Este documento se enfoca **solo** en los dos roles nuevos.

## Vista general

El sistema de la cooperativa COSAALT ya tiene en producción (base) el flujo *asignador* y *técnico* (rutas, cambio de medidor, sincronización). Sobre esa base se están construyendo dos módulos nuevos:

- **`administrador` (Rocío)** — Gestión de usuarios, parámetros normativos, supervisión (estado de solicitudes/rutas/verificaciones/sincronización) y reportes.
- **`mecanico` (Manuel)** — Verificación y ensayo de medidores: bandeja de solicitudes, tomar verificación, registrar el ensayo (condiciones, lecturas, caudal, volumen patrón, participantes), cálculo automático de volumen/error, validación contra el parámetro normativo, resultado CUMPLE/NO CUMPLE, e informe técnico con PDF.

**Arquitectura y persistencia:**
- Backend ASP.NET Core + EF Core + SQL Server (misma base y capas que el módulo base).
- Las tablas propias de los roles se crean en el esquema `medidores/` (nuestro esquema). Las tablas `dbo` del cliente (Conexiones, Reclamos, Recurrentes, Predios, Medidores, Marcas, MotivosCambioMedidor) se usan **solo en lectura** para resolver socio/medidor real.
- **Regla de oro:** nunca escribir en tablas `dbo` del cliente; todo lo nuevo va a `medidores/`.
- Los roles **no ocupan tablas de COSAALT**: toda la verificación vive en las 5 tablas nuevas del esquema `medidores`.

**Los roles por tabla:**

| Responsable | Rol | Esquema / tablas |
|---|---|---|
| Rocío | `administrador` | `medidores.Usuarios`, `medidores.ParametrosNormativos` + solo lectura `dbo` |
| Manuel | `mecanico` | `medidores.Verificaciones`, `EnsayoVerificacion`, `ParticipantesVerificacion`, `InformesVerificacion` + solo lectura `dbo` |

---

## 1. Contratos de DTOs compartidos (los acuerdos entre Rocío y Manuel)

Son la forma EXACTA del JSON que cruza la frontera entre los dos módulos. Se fijaron **antes de codear** en la sección 6 de `Tareas_Administrador_Mecanico.md`. Si se modifica algo, se actualiza ESE documento primero.

### Contrato A — Parámetro normativo (lo EXPONE Rocío, lo LEE Manuel en M12)

```jsonc
{
  "id": 1,
  "codigo": "NB-ISO4064-1",
  "descripcion": "Regla de ensayo, caudal medio",
  "errorMaxPermitido": 2.5,
  "caudalMin": 15,
  "caudalMax": 120,
  "vigenciaInicio": "2026-01-01T00:00:00",
  "vigenciaFin": null,
  "activo": true
}
```

Endpoints: `GET /api/parametros-normativos` (listado) y `GET /api/parametros-normativos/vigente` (el activo según caudal/fecha, para M12).

### Contrato B — Resumen de verificación (lo EXPONE Manuel, lo LEE Rocío en R9/R14)

```jsonc
{
  "idVerificacion": 12,
  "codCon": 50014,
  "fecha": "2026-08-29T10:30:00",
  "estado": "Completada",        // Pendiente | EnCurso | Completada
  "resultado": "CUMPLE",         // CUMPLE | NO CUMPLE (derivado)
  "error": 1.3,
  "caudal": 40.5,
  "medidor": "SAG497888",
  "mecanico": { "id": 3, "nombre": "Manuel" }
}
```

Endpoint: `GET /api/verificaciones/resumen?desde=...&hasta=...&mecanicoId=...`.

---

## 2. Estructura de .NET (`Cosaalt.API/`)

### Backend del mecánico (ya en marcha, M1–M4 completos)

Todo el módulo del mecánico vive bajo un solo controlador `VerificacionesController` y el repo `SqlVerificacionRepository`, con los mismos patrones del módulo base (DTOs record, service fino, repo SQL con EF Core).

```
Cosaalt.API/
├── Controllers/
│   └── VerificacionesController.cs     # Mecánico: bandeja, tomar, detalle, datos socio/medidor
├── Application/
│   ├── DTOs/
│   │   └── VerificacionDtos.cs         # VerificacionDto, EnsayoVerificacionDto, ParticipanteVerificacionDto,
│   │                                   # SolicitudVerificacionDto, TomarVerificacion*Dto, DatosSocioMedidorDto
│   ├── Mappers/
│   │   └── EntityMappers.cs            # VerificacionMapper (DTO <-> Entidad)
│   └── Services/
│       └── AppServices.cs              # + VerificacionService
├── Domain/
│   └── Entities/
│       ├── Verificacion.cs             # cabecera del ensayo (mapea medidores.Verificaciones)
│       ├── EnsayoVerificacion.cs       # condiciones/lecturas/volumen/caudal/error (medidores.EnsayoVerificacion)
│       ├── ParticipanteVerificacion.cs # personas presentes (medidores.ParticipantesVerificacion)
│       └── InformeVerificacion.cs      # informes técnicos + PDF (medidores.InformesVerificacion)
└── Infrastructure/
    ├── Context/
    │   └── CosaaltDbContext.cs         # + DbSet Verificaciones/Ensayos/Participantes/Informes
    ├── Configurations/
    │   ├── VerificacionConfiguration.cs        # ToTable("Verificaciones", "medidores")
    │   ├── EnsayoVerificacionConfiguration.cs  # ToTable("EnsayoVerificacion", "medidores")
    │   ├── ParticipanteVerificacionConfiguration.cs
    │   └── InformeVerificacionConfiguration.cs
    └── Repositories/
        ├── IRepositories.cs            # + IVerificacionRepository
        └── SqlVerificacionRepository.cs # bandeja (dbo), tomar, detalle, datos socio+medidor (SQL real)
```

> **Nota:** el módulo de verificación es **100% SQL puro**. NO hay `MockVerificacionRepository` (se eliminó a pedido: el trabajo es directo contra la base real, `RepositoryMode=Sql`). En modo Mock, `VerificacionesController` no tendría repo registrado (intencional; el foco es la BD real).

### Backend del administrador (pendiente de arrancar)

Según el plan, se esperan estos archivos (aún no creados):

```
Cosaalt.API/
├── Controllers/
│   ├── AdministracionController.cs    # Rocío: usuarios (POST/PUT) y parámetros normativos (CRUD) — R2, R5
│   ├── ReportesController.cs          # Rocío: reportes de movimientos y verificaciones — R11–R14
│   └── DashboardController.cs         # Rocío: dashboard ejecutivo global — R6–R10
├── Application/Services/
│   ├── AdministracionService.cs       # Rocío
│   ├── ReporteService.cs              # Rocío
│   └── DashboardService.cs            # Rocío
└── Infrastructure/Configurations/
    └── (Configuration de ParametrosNormativos — R5)
```

> Nota de arquitectura: `Program.cs` lee `RepositoryMode` (actualmente `"Sql"`). `VerificacionService` (scoped) y `SqlVerificacionRepository` ya están registrados en ambas ramas de DI (Sql y Mock quedaron sin mock de verificación). Para el administrador se seguirá el mismo patrón.

### Tablas del esquema `medidores/` (roles) — YA CREADAS

Resumen de las 5 (creadas por `Scripts/03_creacion_tablas_roles.sql`):

| Tabla | Dueño | Propósito | Campos clave |
|-------|-------|-----------|------------------------|
| `ParametrosNormativos` | Rocío | Reglas de validación de volumen y error | IdParametro, Codigo, Descripcion, ErrorMaxPermitido, CaudalMin, CaudalMax, VigenciaInicio, VigenciaFin, Activo |
| `Verificaciones` | Manuel | Cabecera del ensayo físico de verificación | IdVerificacion, TipoOrigen, IdOrigen, Cod_con (FK dbo.Conexiones), IdUsuarioMecanico, IdMedidor, FechaVerificacion, Estado, Resultado |
| `EnsayoVerificacion` | Manuel | Parámetros específicos, lecturas, error y veredicto | IdEnsayo, IdVerificacion, Condiciones, LecturaInicial, LecturaFinal, VolumenPatron, Caudal, VolumenRegistrado, Error, Fugas, Observaciones |
| `ParticipantesVerificacion` | Manuel | Personas que testifican el ensayo técnico | IdParticipante, IdVerificacion, Nombre, Cargo, Rol |
| `InformesVerificacion` | Manuel | Informes oficiales y PDFs generados | IdInforme, IdVerificacion, NroInforme, FechaEmision, FechaFirma, RutaPdf, Firmado, Repeticiones |

> **Importante antes de escribir datos reales:** M5–M9 en adelante hacen `INSERT` en `medidores.*`. Estas tablas se crean con `Scripts/03_creacion_tablas_roles.sql`; **deben estar ejecutadas en la base real** a la que apunta `CosaaltDb` antes de probar esos endpoints.

### Endpoints del mecánico (implementados M1–M4)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/verificaciones/solicitudes` | Bandeja de solicitudes disponibles para verificar (lee dbo ODECO + LECTURA, excluye las tomadas) |
| POST | `/api/verificaciones/tomar` | Toma una verificación (crea cabecera en medidores.Verificaciones, evita doble toma) |
| GET | `/api/verificaciones/mecanico/{idMecanico}` | Verificaciones de un mecánico |
| GET | `/api/verificaciones/{id}` | Detalle de una verificación (con ensayo y participantes) |
| GET | `/api/verificaciones/{id}/datos` | Datos del socio + medidor vigente real (dbo en caliente) |

### Modelo de datos de verificación (relaciones EF)

- **Verificacion** → tiene 1 `EnsayoVerificacion` (1:1, FK en ensayo), N `ParticipanteVerificacion`, N `InformeVerificacion`; referencia `Conexion` (dbo, por `CodCon`) y `Mecanico` (Usuario).
- **CodCon** se mapea con `NumericConversions.IntToDecimal` (la columna es `NUMERIC(12,0)` en dbo, igual que `EjecucionCambio`).
- `Usuario` ahora tiene la colección `Verificaciones` como relación inversa de `IdUsuarioMecanico`.

---

## 3. Estructura de Flutter (`cosaalt_medidores/lib/`)

App Flutter con **Riverpod** (estado) y **go_router** (navegación), organizada por *features* (data/domain/presentation).

### Estado actual del frontend

**NO existe todavía** ningún feature de `admin/` ni de `verificacion/`. El router (`app_router.dart`) y el `UserRole` únicamente manejan `asignador` y `tecnico`. **Esto es la tarea R1/M1 del frontend**: los roles nuevos no resuelven a ningún dashboard todavía.

Estructura planificada (según sección 7 de `Tareas_Administrador_Mecanico.md`):

```
lib/features/
├── admin/                                # Rocío — administrador
│   ├── data/repositories/api_admin_repository.dart
│   ├── domain/ (entities: usuario, parametro_normativo)
│   └── presentation/ (screens: usuarios, parametros_normativos, dashboard_admin, reportes)
└── verificacion/                         # Manuel — mecánico
    ├── data/repositories/api_verificacion_repository.dart
    ├── domain/ (entities: solicitud_verificacion, ensayo, participante, informe)
    └── presentation/ (controllers + screens: bandeja_verificaciones, registro_ensayo, informe_tecnico)
```

Notas de arquitectura del frontend (heredadas del módulo base):
- Cada feature tiene un `Notifier`/`Controller` + `Provider` (Riverpod). La UI escucha el estado y los controladores llaman repositorios HTTP.
- Navegación con go_router, redirige por rol: no autenticado → `/login`; un rol no entra a rutas de otro.
- `ApiConfig.baseUrl = 'http://localhost:5034'`.
- El patrón de "View reutilizable embebida en pestañas del dashboard con `CosaaltBottomNav`" se puede reutilizar para las nuevas pantallas.

---

## 4. Plan de tareas por rol (de `Tareas_Administrador_Mecanico.md`)

### Mecánico (Manuel) — estado

| # | Tarea | Estado |
|---|-------|--------|
| M1 | Modelo de datos de verificación (entidades EF) | ✅ Backend completo |
| M2 | Bandeja de solicitudes de verificación | ✅ Backend completo |
| M3 | Tomar una verificación | ✅ Backend completo |
| M4 | Consultar datos del socio y medidor | ✅ Backend completo |
| M5 | Registrar condiciones del ensayo | 🔲 Pendiente |
| M6 | Registrar lecturas (inicial/final) | 🔲 Pendiente |
| M7 | Registrar volumen patrón | 🔲 Pendiente |
| M8 | Registrar caudal | 🔲 Pendiente |
| M9 | Registrar participantes | 🔲 Pendiente |
| M10 | Cálculo automático del volumen registrado | 🔲 Pendiente |
| M11 | Cálculo automático del error | 🔲 Pendiente |
| M12 | Validación contra parámetro normativo (Depende de R5 de Rocío) | 🔲 Pendiente |
| M13 | Resultado CUMPLE / NO CUMPLE (automático) | 🔲 Pendiente |
| M14 | Registro de fugas | 🔲 Pendiente |
| M15 | Observaciones técnicas | 🔲 Pendiente |
| M16 | Previsualizar informe | 🔲 Pendiente |
| M17 | Generar informe técnico (persistir) | 🔲 Pendiente |
| M18 | Firmar / emitir informe | 🔲 Pendiente |
| M19 | Generar PDF del informe | 🔲 Pendiente |
| M20 | Historial de informes | 🔲 Pendiente |
| M21 | Reimprimir / consultar informes | 🔲 Pendiente |

### Administrador (Rocío) — estado

| # | Tarea | Estado |
|---|-------|--------|
| R1 | Login + router por rol de admin/mecanico | 🔲 Pendiente (frontend) |
| R2 | CRUD de usuarios + activar/inactivar (GET hecho, faltan POST/PUT) | 🔲 Parcial |
| R3 | Consulta catálogo de motivos (solo lectura) | 🔲 Pendiente |
| R4 | Consulta catálogo de marcas (solo lectura) | 🔲 Pendiente |
| R5 | Gestión de parámetros normativos (tabla existe, falta CRUD) | 🔲 Pendiente |
| R6–R10 | Supervisión (dashboard, solicitudes, rutas, verificaciones, sync) | 🔲 Pendiente |
| R11–R14 | Reportes (movimientos, filtros, exportación, estadísticas) | 🔲 Pendiente |

### Dependencias críticas

- **M12 → R5:** el mecánico valida el error contra el parámetro normativo que configura el admin (`medidores.ParametrosNormativos`). Contrato A fijado.
- **R9, R14 → M13:** el dashboard y las estadísticas del admin leen los resultados de verificación de Manuel. Contrato B fijado.
- **Todos → R1:** los roles `administrador`/`mecanico` deben existir en `medidores.RolApp` y resolverse en el router del frontend antes de probar pantallas.

---

## Credenciales de demo y datos de arranque

Según los mocks del módulo base (y se deben confirmar en la base real al conectar):
- Técnico: `tecnico1` / `123456`
- Asignador: `admin` / `admin123`
- Admin y mecánico: cuentas reales a cargar en `medidores.Usuarios` (rol `administrador` / `mecanico`); el mock base lista "Rocío Flores Medina" (admin, id 6) y "Manuel Ortega Vega" (mecanico, id 7).

> **Nota de base real:** verificar con `Scripts/02c_importar_funcionarios_usuarios.sql` y el seed que existan usuarios con esos roles en `medidores.Usuarios` antes de usar sus pantallas.

## Cómo levantar el entorno

1. **Backend:** `dotnet build` en `Cosaalt.API/` (verificado sin errores hasta M4). Correr con `RepositoryMode=Sql` apuntando a la base real COSAALT (perfil `http` → `http://localhost:5034`).
2. **Base:** asegurar que `Scripts/03_creacion_tablas_roles.sql` (5 tablas de roles) esté ejecutado en la base real.
3. **Frontend:** desde `cosaalt_medidores/`: `flutter run -d windows` (o emulador/web). Apunta a la API local.
4. **Docs API:** Swagger en `/swagger`.
