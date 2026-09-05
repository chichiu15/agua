# COSAALT - Entrega integrada Backend + Frontend (02/09/2026)

## Estado
- Base final: `cosaalt`.
- Tablas propias: `medidores.*`.
- Administrador: se conserva R1-R14 y se adaptan reportes a la base final.
- Asignador: dashboard, bandeja, creación de ruta y monitoreo con refresco periódico.
- Técnico: ruta del día, cache SQLite, formulario de cambio, fotografías locales comprimidas, cola offline y sincronización por lote.
- Mecánico: se conserva lo existente, pero no se amplía el flujo hasta recibir los criterios metrológicos del Taller.

## Correcciones principales de esta entrega
1. `ReportesController` ya no exige `CosaaltDbContext` en su constructor; `/api/reportes/estadisticas` puede activarse con `AdminService` normalmente.
2. Los PDF y Excel de movimientos, histórico y verificaciones vuelven a usar el generador profesional: títulos, metadatos, tablas, formatos, autofiltro/freeze panes en Excel y maquetación paginada en PDF.
3. `RepositoryMode` queda en `Sql` en Development y la API escucha en `0.0.0.0:5034` para poder probar desde Android.
4. Android permite HTTP local (`usesCleartextTraffic=true`) durante desarrollo.
5. Flutter selecciona automáticamente:
   - Windows: `http://localhost:5034`
   - emulador Android: `http://10.0.2.2:5034`
   - celular físico: usar `--dart-define=API_BASE_URL=...` o `adb reverse`.
6. Se agrega cache local SQLite de rutas/solicitudes/catálogos.
7. La ruta del técnico se precarga para uso sin internet.
8. El cambio de medidor obliga a seleccionar un medidor institucional disponible; ya no se escribe serie/marca manualmente como fuente de verdad.
9. La sincronización devuelve resultado por trabajo y solo elimina del dispositivo aquello confirmado por el servidor.
10. Un conflicto (por ejemplo, medidor ya no disponible) queda local como `Pendiente sync` para corregir y volver a enviar.
11. El backend registra `EstadoIntegracionInstitucional=PENDIENTE`; el técnico NO modifica Manantial ni `dbo.Medidor` directamente.
12. SQL 04 y 05 fueron ajustados para verificar/limpiar los usuarios, rutas, ejecuciones y parámetros QA usados en pruebas E2E sin tocar `dbo.*`.

## Antes de probar
No volver a ejecutar SQL 01, 02 ni 03 si ya fueron aplicados correctamente.

Backend:
```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API
dotnet restore
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Frontend:
```powershell
cd C:\trabajos\Cosaalt\cosaalt_medidores
flutter clean
flutter pub get
flutter analyze
flutter devices
```

La secuencia completa de prueba está en `PRUEBAS_E2E_FRONTEND_COSAALT.md`.

## Limpieza
1. Al terminar E2E, ejecutar primero `04_VERIFICAR_PRUEBAS_SWAGGER.sql`.
2. Revisar que solo aparezcan registros QA esperados.
3. Ejecutar `05_LIMPIEZA_PRUEBAS_SWAGGER.sql`.
4. Las fotografías son archivos físicos: eliminar únicamente las rutas QA generadas durante la prueba, no carpetas institucionales ni imágenes ajenas.

## Validación pendiente en el equipo de desarrollo
Este paquete fue revisado estáticamente, pero el entorno de generación no dispone de los SDK `dotnet`/`flutter`; la validación definitiva se realiza en la PC con `dotnet build`, `flutter pub get` y `flutter analyze` antes de E2E.
