# COSAALT - Backend reestructurado para la base `cosaalt`

## 1. Reemplazo

1. Haz una copia de seguridad de tu carpeta actual `Cosaalt.API`.
2. Reemplaza el contenido de `C:\trabajos\Cosaalt\Cosaalt.API` por el contenido de esta carpeta `Cosaalt.API`.
3. Conserva tu cadena real de SQL solo de forma local. El `appsettings.Development.json` del paquete viene sin contraseña.
4. No ejecutes `dotnet ef database update` contra la base institucional.

## 2. SQL antes de Swagger

En SSMS, apuntando a `cosaalt`, ejecuta:

1. `Scripts/01_CREAR_ESQUEMA_MEDIDORES_COSAALT.sql`
2. `Scripts/02_AJUSTES_INTEGRIDAD_BACKEND.sql`
3. `Scripts/03_SMOKE_TEST_BACKEND_COSAALT.sql`

Los scripts 01 y 02 solo crean/ajustan objetos de `medidores.*`. El script 03 es solo lectura.

## 3. Levantar backend

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API
$env:RepositoryMode="Sql"
$env:ConnectionStrings__CosaaltDb="Server=TU_SERVIDOR;Database=cosaalt;User Id=TU_USUARIO;Password=TU_PASSWORD;Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=True;"
dotnet restore .\Cosaalt.API.csproj
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Swagger: `http://localhost:5034/swagger`

## 4. Pruebas

Sigue `PRUEBAS_SWAGGER_BACKEND_COSAALT.md` en orden. Las pruebas crean datos QA solamente en `medidores.*`; no insertan datos ficticios en `dbo.*`.

Al terminar:

1. Ejecuta `Scripts/04_VERIFICAR_PRUEBAS_SWAGGER.sql`.
2. Si todo esta correcto, ejecuta `Scripts/05_LIMPIEZA_PRUEBAS_SWAGGER.sql`.

El script 05 elimina únicamente los usuarios/rutas/ejecuciones/parametros QA identificados por las pruebas y no modifica `dbo.*`.

## 5. Punto pendiente de COSAALT

Mientras el Lic. no confirme el mecanismo oficial de Manantial, registrar un cambio físico crea trazabilidad en `medidores.EjecucionCambio` pero **no actualiza `dbo.Medidor`**. El registro queda con `EstadoIntegracionInstitucional = PENDIENTE`.
