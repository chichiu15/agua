# COSAALT Medidores - V5 E2E (2026-09-02)

Esta entrega parte de la version que ya funcionaba contra la base `cosaalt` y agrega:

- Catalogos Administrador completos: motivos y marcas con alta, lectura, edicion y activar/desactivar.
- `medidores.MotivosCambio` como catalogo propio del modulo (la base `cosaalt` no tiene `dbo.MotivosCambioMedidor`).
- `medidores.MarcasMedidor` como catalogo auxiliar para nombre/alias/estado de los codigos `dbo.Medidor.Mar_Med`, sin modificar medidores historicos.
- Mapa del Asignador siempre visible; ya no desaparece cuando las solicitudes reales no tienen coordenadas.
- Recuperacion de coordenadas/lectura desde la ultima `dbo.Lectura` georreferenciada del socio para ODECO cuando existe.
- Bateria temporal E2E de 20 solicitudes (10 ODECO + 10 LECTURA) alrededor de Plaza Los Laureles, creada SOLO en `medidores.*`.
- Android `compileSdk/targetSdk = 37`.
- Pruebas con celular fisico por USB usando `adb reverse`.

## SQL: NO vuelvas a correr 01/02/03

Como ya los ejecutaste, ahora ejecuta solo:

1. `Scripts/06_ACTUALIZAR_CATALOGOS_APP.sql`  **permanente**
2. `Scripts/07_CARGAR_BATERIA_E2E_SOLICITUDES.sql`  **temporal QA**

El 07 debe mostrar 20 filas `QA-ODECO-*` / `QA-LECTURA-*` y varios motivos `QA-E2E - ...`.

No ejecutes `05_LIMPIEZA_PRUEBAS_SWAGGER.sql` hasta terminar toda la prueba.

## Backend

Conserva tu `appsettings.Development.json` actual que ya apunta a `Database=cosaalt`; el ZIP trae una version sin credenciales reales por seguridad.

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API
dotnet restore
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Swagger: `http://localhost:5034/swagger`

Controles rapidos:

- `GET /api/catalogos/motivos?incluirInactivos=true` -> 200
- `GET /api/catalogos/marcas?incluirInactivos=true` -> 200
- `GET /api/solicitudes` -> debe incluir `QA-ODECO-*` y `QA-LECTURA-*`
- `GET /api/catalogos/medidores-disponibles?limite=20` -> 200
- `GET /api/reportes/estadisticas` -> 200

## Administrador Windows

```powershell
cd C:\trabajos\Cosaalt\cosaalt_medidores
flutter clean
flutter pub get
flutter analyze
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5034
```

En Catalogos debes poder:

- Motivos: crear, editar, leer, activar/desactivar.
- Marcas: crear, editar, leer, activar/desactivar.

Las marcas institucionales existentes se incorporan automaticamente desde `dbo.Medidor.Mar_Med`. Editar nombre/alias/estado NO modifica `dbo.Medidor`.

## Mapa Asignador en PC

Abre `Asignador -> Armar recorrido`.

El mapa OpenStreetMap ahora siempre se dibuja. Con el SQL 07 deben verse 20 marcadores cerca de:

- centro aproximado: `-21.50440, -64.71810`
- incluye exactamente los puntos enviados para Plaza Los Laureles y puntos adicionales dentro del mismo radio.

Filtros:

- ODECO -> 10 solicitudes QA mas ODECO reales con coordenadas disponibles.
- LECTURA -> 10 solicitudes QA.
- ASIGNADAS -> permite visualizar las ya incluidas en ruta.

## Corregir Android SDK 37

El proyecto ya trae:

```kotlin
compileSdk = 37
targetSdk = 37
```

En Android Studio:

`Tools -> SDK Manager -> SDK Platforms -> Android 17 / API 37 -> Apply`

Tambien instala en `SDK Tools` los Build-Tools 37 y Platform-Tools.

O desde PowerShell, si tienes cmdline-tools:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" "platforms;android-37" "build-tools;37.0.0" "platform-tools"
Test-Path "$sdk\platforms\android-37\android.jar"
```

El ultimo comando debe devolver `True`.

Luego:

```powershell
cd C:\trabajos\Cosaalt\cosaalt_medidores
flutter clean
Remove-Item -Recurse -Force .\android\.gradle -ErrorAction SilentlyContinue
flutter pub get
flutter run -d 1209dd0f --dart-define=API_BASE_URL=http://127.0.0.1:5034
```

## Celular fisico por USB (tu caso)

Tu salida de `adb devices` muestra:

- `1209dd0f` = celular fisico
- `emulator-5554` = emulador

Por eso NO uses `adb reverse ...` sin `-s`.

Ejecuta:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s 1209dd0f reverse tcp:5034 tcp:5034
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s 1209dd0f reverse --list
flutter run -d 1209dd0f --dart-define=API_BASE_URL=http://127.0.0.1:5034
```

No necesitas apagar el emulador.

## Prueba E2E recomendada

1. Entra como Asignador.
2. Abre Armar recorrido.
3. Selecciona 4-6 puntos QA mezclando ODECO y LECTURA.
4. Ordenalos y asigna la ruta al tecnico QA.
5. Entra en el celular como Tecnico.
6. Abre Mi recorrido con Internet para descargarlo a SQLite.
7. Para simular offline SIN quitar el cable USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s 1209dd0f reverse --remove tcp:5034
```

8. Abre una parada, llena cambio, toma las dos fotos y guarda localmente.
9. Debe quedar `Pendiente sync`.
10. Recupera la API con:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s 1209dd0f reverse tcp:5034 tcp:5034
```

y pulsa Sincronizar.
11. Debe pasar a Completada y aparecer en Admin/Planilla/Reportes.
12. El tecnico no modifica `dbo.Medidor`; la ejecucion queda `EstadoIntegracionInstitucional=PENDIENTE`.

## Verificacion y limpieza

Al terminar ejecuta:

1. `04_VERIFICAR_PRUEBAS_SWAGGER.sql`
2. Revisa que las consultas de duplicados devuelvan 0 filas.
3. `05_LIMPIEZA_PRUEBAS_SWAGGER.sql`

El 05 borra QA de `medidores.*`, motivos `QA-E2E` y elimina la tabla temporal `SolicitudPruebaE2E`. NO toca `dbo.*` y conserva los catalogos permanentes.

Fotos QA fisicas (solo despues de validar todo):

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API\wwwroot\uploads
Get-ChildItem -Directory -Filter 'QA-*' | Remove-Item -Recurse -Force
```

## Pendiente funcional real

El origen real LECTURA aun requiere identificar fisicamente como se enlaza `lec_obl` con la lectura en esta version de Manantial. Las 10 solicitudes LECTURA del SQL 07 son exclusivamente bateria E2E y desaparecen con el script 05.
