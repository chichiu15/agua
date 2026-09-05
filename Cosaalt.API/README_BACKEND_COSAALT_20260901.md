# COSAALT Medidores - Backend actualizado a la base `cosaalt`

## Que hace este paquete

Este paquete toma el backend que ya se venia desarrollando y lo adapta a la estructura institucional auditada de la base `cosaalt`, conservando los contratos principales que ya consume el frontend.

### Se conserva

- Login por rol.
- Usuarios y roles de la aplicacion.
- Asignador: consulta de solicitudes, tecnicos, asignacion y consulta de rutas.
- Tecnico: consulta de ruta, evidencias, registro de cambio, historial y sincronizacion.
- Administrador R1-R14: usuarios, catalogos, parametros, dashboard, solicitudes, recorridos, sincronizacion, movimientos, historico, verificaciones, estadisticas y PDF/XLSX.
- Estructura del modulo mecanico ya existente, sin expandirlo todavia mas alla de la compatibilidad necesaria.

## Cambio principal de arquitectura

`CosaaltDbContext` ahora mapea solamente las 11 tablas propias `medidores.*`.

La informacion institucional `dbo.*` se consulta mediante `CosaaltInstitutionalReader`, usando la estructura que fue auditada en `cosaalt`:

- `dbo.PERSONAS`
- `dbo.SOCIO`
- `dbo.Medidor`
- `dbo.Estado_medidor`
- `dbo.Lectura`
- `dbo.RECLAMOS`
- `dbo.TIPOSRECLAMOS`
- `dbo.TIPOSPRIORIDADES`
- `dbo.hist_pred_med`

No se usan como fuente real las estructuras antiguas asumidas en `cosaaltunoprueba` como `dbo.Conexiones`, `dbo.Funcionarios`, `dbo.CambioMedidores`, `dbo.Marcas` ni las tablas propias antiguas `SolicitudLectura/DetalleSolicitudLectura`.

## Reglas importantes

- Un usuario puede quedar sin vincular a una persona institucional.
- Si se vincula, `medidores.Usuarios.CodPersonaCorporativa` se valida contra `dbo.PERSONAS.CodPer`.
- Marcas se derivan de `dbo.Medidor.Mar_Med`.
- El medidor actualmente relacionado con un socio se resuelve por `dbo.Medidor.reg_soc`, priorizando el registro mas reciente; no se inventa el significado de `dis_med` para decidir vigencia.
- La lista de medidores candidatos usa provisionalmente `cod_est=5`, `dis_med='L'`, `reg_soc=0`, porque esa regla esta pendiente de confirmacion de COSAALT.
- ODECO se lee desde `dbo.RECLAMOS` y sus catalogos reales.
- El origen LECTURA no se inventa mientras no se confirme la relacion exacta entre la lectura y la observacion que genera trabajo.
- `dbo.hist_pred_med` reemplaza el supuesto anterior de `dbo.CambioMedidores` para el historico administrativo.
- El cambio ejecutado se guarda en `medidores.EjecucionCambio`; el backend no modifica el medidor institucional todavia.
- `EstadoIntegracionInstitucional` queda `PENDIENTE` hasta confirmar como COSAALT desea reflejar el cambio en Manantial.
- El registro del cambio es idempotente por `TipoOrigen + IdOrigen`.
- El mismo `CodMedidorInstalado` no puede quedar usado por dos ejecuciones propias.
- Los nuevos passwords se guardan PBKDF2-SHA256. Si existe un usuario antiguo en texto plano y hace login correctamente, se actualiza automaticamente al formato seguro.

## Motivos de cambio

El CRUD de motivos no crea una tabla paralela.

Si `dbo.MotivosCambioMedidor` existe en `cosaalt`, se utiliza esa tabla. Si no existe, la API devuelve `503 INTEGRACION_PENDIENTE` hasta que COSAALT confirme el catalogo definitivo. Esto evita modificar la base institucional basandonos en un supuesto.

## Archivos SQL

- `Scripts/01_CREAR_ESQUEMA_MEDIDORES_COSAALT.sql`: esquema base propio; no modifica dbo.
- `Scripts/02_AJUSTES_INTEGRIDAD_BACKEND.sql`: indices unicos para idempotencia; no modifica dbo.
- `Scripts/03_SMOKE_TEST_BACKEND_COSAALT.sql`: solo SELECT.
- `Scripts/04_VERIFICAR_PRUEBAS_SWAGGER.sql`: solo SELECT de los datos QA creados.
- `Scripts/05_LIMPIEZA_PRUEBAS_SWAGGER.sql`: elimina solo datos QA de `medidores.*`.

## IMPORTANTE SOBRE MIGRATIONS

La carpeta `Migrations` pertenece a una etapa anterior del proyecto y **no debe utilizarse para actualizar la base institucional**. Para esta fase, la estructura autorizada se aplica mediante los scripts SQL del directorio `Scripts`.

No ejecutar:

```powershell
dotnet ef database update
```

contra `cosaalt`.

## Como levantar

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API
$env:RepositoryMode="Sql"
$env:ConnectionStrings__CosaaltDb="CADENA_REAL_CON_Database=cosaalt"

dotnet restore .\Cosaalt.API.csproj
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Swagger:

```text
http://localhost:5034/swagger
```

Para las pruebas paso a paso abrir `PRUEBAS_SWAGGER_BACKEND_COSAALT.md`.

## Que falta confirmar con COSAALT

No bloquea la compilacion ni la mayor parte del backend, pero si el cierre funcional definitivo:

1. significado de `Medidor.dis_med` L/O/B y regla exacta de disponibilidad;
2. tipos de reclamo ODECO que corresponden a cambio/revision de medidor;
3. origen exacto de solicitudes procedentes de Lectura/Obs_Lec;
4. significado de `hist_pred_med.est_med` A/B;
5. mecanismo oficial que actualiza Manantial despues del cambio fisico;
6. catalogo institucional definitivo de motivos si no existe en `cosaalt`;
7. parametros y limites normativos definitivos del ensayo mecanico.

## Confirmaciones institucionales recibidas 02/09/2026

- `dbo.Medidor.dis_med`: `L=Libre`, `O=Ocupado`, `B=Baja`.
- Para conocer el medidor actual de un socio se utiliza `dbo.Medidor.reg_soc`.
- El cambio de medidor NO nace automaticamente de un tipo de reclamo; se incorpora como observacion del inspector y la Unidad de Lecturas/Taller lo procesa manualmente.
- En lecturas, COSAALT indico las observaciones 2, 4 y 11 como relevantes para problemas de medidor. Aun falta cerrar la vinculacion fisica exacta de ese codigo con la fila de `dbo.Lectura` antes de automatizar el origen LECTURA.
- El tecnico de campo no actualiza Manantial directamente. La aplicacion registra la ejecucion en `medidores.EjecucionCambio` y conserva `EstadoIntegracionInstitucional=PENDIENTE` para validacion posterior por Unidad de Lecturas/Taller.
- `dbo.hist_pred_med` no debe ser modificada por esta aplicacion; Manantial mantiene esas modificaciones.
- Las reglas metrologicas de verificacion mecanica (datos, formula y limites CUMPLE/NO CUMPLE) quedan pendientes de confirmacion del encargado del Taller de Medidores.
