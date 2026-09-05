# COSAALT Medidores — prueba final punta a punta

## 0. Qué versión se prueba

- Base institucional: `cosaalt`.
- Datos institucionales: `dbo.*` en lectura durante este flujo.
- Seguimiento nuevo: `medidores.*`.
- Asignador y Técnico: Android.
- Administrador: Windows.
- Mecánico operativo: pendiente de las reglas del Taller. El Administrador conserva las vistas de verificaciones ya desarrolladas.
- El técnico NO actualiza Manantial. La ejecución queda en `medidores.EjecucionCambio` con integración institucional `PENDIENTE`.

No vuelva a ejecutar los scripts 01, 02 y 03 si ya fueron aplicados correctamente. El script 04 es solo SELECT y puede ejecutarse todas las veces que quiera. El 05 se ejecuta únicamente al terminar y aprobar la prueba.

---

## 1. Levantar backend

Abra una terminal en VS Code:

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API
dotnet restore .\Cosaalt.API.csproj
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Debe ver `Build succeeded` y una dirección equivalente a `http://0.0.0.0:5034`.

En la PC abra:

```text
http://localhost:5034/swagger
```

No cierre esa terminal mientras prueba Flutter.

### Control rápido del error de Reportes

Antes de ir a Flutter pruebe una sola vez:

```text
GET /api/reportes/estadisticas
```

Debe responder 200. El controlador de reportes ya no exige `CosaaltDbContext` en su constructor y la configuración local fuerza `RepositoryMode=Sql`.

---

## 2. Preparar Flutter una sola vez después de reemplazar la carpeta

En otra terminal:

```powershell
cd C:\trabajos\Cosaalt\cosaalt_medidores
flutter clean
flutter pub get
flutter analyze
flutter devices
```

`flutter analyze` debe terminar sin errores de compilación. Los warnings no bloquean la prueba, pero conviene enviarlos si aparecen.

---

## 3. Administrador en Windows

Si Windows aparece en `flutter devices`:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5034
```

Si Windows no aparece:

```powershell
flutter config --enable-windows-desktop
flutter devices
```

Para compilar Windows Flutter necesita Visual Studio con el workload **Desktop development with C++**.

### Prueba Administrador

Inicie sesión con una cuenta Administrador existente. Si aún no existe ninguna, créela una sola vez mediante `POST /api/usuarios` con `idRol = 3` y luego continúe toda la prueba desde Flutter.

Revise en este orden:

1. Dashboard: tarjetas, actividad y datos reales.
2. Usuarios: listar, crear/editar/desactivar una cuenta QA si desea.
3. Catálogos: motivos y marcas.
4. Parámetros normativos: listado/CRUD. Los valores oficiales del Taller siguen pendientes.
5. Solicitudes: filtros y detalle.
6. Recorridos: ruta asignada y avance.
7. Sincronización: estado por técnico.
8. Planilla / movimientos.
9. Verificaciones: consulta administrativa, sin completar el flujo Mecánico todavía.
10. Reportes / estadísticas.
11. Exportar Movimientos PDF/XLSX.
12. Exportar Histórico PDF/XLSX.
13. Exportar Verificaciones PDF/XLSX.

Los PDF/Excel deben mostrar el diseño institucional restaurado: título COSAALT, descripción, fecha de generación, cantidad de registros, cabeceras formateadas y tablas profesionales.

---

## 4. Emulador Android Studio — no importa que Android Studio tenga otro proyecto abierto

El emulador es independiente del proyecto abierto.

1. En Android Studio abra **Device Manager**. En su captura ya aparecen `Pixel 10` y `Pixel 4`.
2. Pulse el triángulo ▶ al lado de `Pixel 10`.
3. Espere a que aparezca la pantalla de inicio de Android.
4. No necesita abrir el proyecto Flutter en Android Studio. Vuelva a la terminal de VS Code.
5. Ejecute:

```powershell
cd C:\trabajos\Cosaalt\cosaalt_medidores
flutter devices
```

Verá un ID parecido a `emulator-5554`.

6. Ejecute, usando el ID que realmente le muestre:

```powershell
flutter run -d emulator-5554
```

Para el emulador Android la app usa automáticamente:

```text
http://10.0.2.2:5034
```

`10.0.2.2` significa “localhost de la PC” visto desde el emulador.

Si el Android 17/API 37 de esos emuladores diera un problema extraño de compatibilidad, cree uno estable: Device Manager → `+` → Create Virtual Device → Pixel 6 → imagen Android 15/API 35 x86_64 → Finish.

---

## 5. Prueba Asignador en Android

Puede usar la cuenta QA ya creada durante Swagger:

```text
Usuario: qa_asignador_20260901
Contraseña QA: Qa2026!Asignador
```

1. Login: debe entrar al Dashboard de Asignador.
2. Compruebe tarjetas ODECO, Lectura, completadas, técnicos activos/en campo.
3. Entre a **Asignar Ruta a Trabajadores**.
4. Seleccione una solicitud ODECO pendiente para la prueba.
5. Continúe al orden de visitas.
6. Seleccione `qa_tecnico_20260901`.
7. Confirme la asignación.
8. Abra **Monitoreo de Asignaciones**.
9. Debe aparecer la ruta y su porcentaje. La pantalla actualiza silenciosamente cada 20 segundos y también permite arrastrar hacia abajo para refrescar.

La asignación solo escribe `medidores.AsignacionRuta/DetalleRuta`; el `dbo.RECLAMOS` original no se modifica.

---

## 6. Prueba Técnico + OFFLINE real

Cierre sesión del Asignador e ingrese:

```text
Usuario: qa_tecnico_20260901
Contraseña QA: Qa2026!Tecnico
```

### 6.1 Descargar la ruta con Internet

1. Entre a **Mi Recorrido**.
2. Debe aparecer la ruta que acaba de asignar.
3. Espere unos segundos. Al descargar la ruta, la app también almacena en SQLite:
   - la ruta;
   - detalle de las solicitudes;
   - catálogo de motivos;
   - una lista reciente de medidores institucionales disponibles.

### 6.2 Probar que funciona sin Internet

1. En el emulador abra ajustes rápidos y active Modo avión, o desconecte Wi-Fi/datos.
2. Regrese a la app.
3. Actualice/abra **Mi Recorrido**: debe poder seguir viendo la ruta descargada.
4. Pulse **IR / EJECUTAR** en la parada.
5. El formulario debe abrir con la solicitud almacenada localmente.
6. Ingrese lectura de retiro.
7. Seleccione motivo.
8. Seleccione un medidor de la lista institucional cacheada. No se escribe manualmente número/marca: la app utiliza un `dbo.Medidor` candidato que figuraba PERFECTO + Libre (`L`) + sin socio.
9. Las fotografías son opcionales. Para probar evidencias, tome una o dos; para validar el flujo sin fotografías, continúe sin capturarlas.
10. Escriba observación `QA-E2E-20260902 - prueba offline` para que el script 05 pueda identificarla adicionalmente.
11. Pulse **GUARDAR EN EL DISPOSITIVO**.
12. Debe volver a la ruta, mostrar la parada como `Pendiente sync` y el contador de Sincronización debe aumentar.

Todavía NO debe existir `medidores.EjecucionCambio` en SQL: el trabajo sigue únicamente en el celular.

### 6.3 Sincronizar

1. Reactive Internet.
2. Abra la pestaña **Sincronizar**.
3. Pulse **SINCRONIZAR**.
4. Se suben primero las fotos y luego el cambio.
5. El backend vuelve a comprobar el medidor: `cod_est=5`, `dis_med='L'`, `reg_soc=0`.
6. Si todo está bien, la cola local se elimina únicamente para ese trabajo confirmado.
7. Si un registro falla, NO se borra del celular. La pantalla muestra el motivo y la ruta permite **REVISAR** el trabajo para elegir otro medidor y volver a guardarlo.
8. La misma ejecución reenviada no debe duplicarse: el backend devuelve `YaExistia=true` y se considera confirmada.

Después de éxito, **Mi Recorrido** debe mostrar la parada `Completada`.

---

## 7. Ver punta a punta desde el Asignador y Administrador

### Asignador Android

Vuelva a entrar como Asignador:

- Monitoreo → la ruta debe haber aumentado a 100% si era la única parada.
- Si había varias, debe reflejar el nuevo porcentaje.

### Administrador Windows

Vuelva a la instancia Windows:

- Dashboard: debe reflejar actividad.
- Recorridos: ruta y parada completada.
- Sincronización: técnico actualizado.
- Movimientos: debe aparecer el cambio.
- Reportes/estadísticas: debe responder sin 409.
- Exporte PDF y Excel y ábralos visualmente.

El cambio queda en la aplicación con:

```text
EstadoIntegracionInstitucional = PENDIENTE
```

No se actualiza `dbo.Medidor`. La validación/registro posterior en Manantial corresponde a Unidad de Lecturas o Taller, según lo confirmado por COSAALT.

---

## 8. Probar en CELULAR FÍSICO por USB

### 8.1 Activar modo desarrollador

La ruta exacta cambia por marca, pero normalmente:

1. Ajustes → Acerca del teléfono.
2. Pulse **Número de compilación** 7 veces. En Xiaomi suele ser “Versión de MIUI/HyperOS”.
3. Vuelva a Ajustes → Sistema / Ajustes adicionales → **Opciones de desarrollador**.
4. Active **Depuración USB**.
5. Conecte un cable USB que transmita datos.
6. Acepte en el teléfono **Permitir depuración USB** / huella RSA.

En PowerShell:

```powershell
flutter devices
```

Debe aparecer el nombre/ID del teléfono.

### 8.2 Método recomendado: USB + `adb reverse`

No necesita que celular y PC estén en la misma Wi-Fi.

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:5034 tcp:5034
```

Después:

```powershell
flutter run -d ID_DEL_CELULAR --dart-define=API_BASE_URL=http://127.0.0.1:5034
```

Reemplace `ID_DEL_CELULAR` por el valor de `flutter devices`.

### 8.3 Alternativa por Wi-Fi/LAN

PC y celular deben estar en la misma red.

En la PC:

```powershell
ipconfig
```

Busque la IPv4 del adaptador Wi-Fi/Ethernet, por ejemplo `192.168.1.50`. No use `127.0.0.1` ni la puerta de enlace.

Compruebe en el navegador del teléfono:

```text
http://192.168.1.50:5034/swagger
```

Si no abre, permita `dotnet`/puerto 5034 en Windows Defender Firewall para redes privadas.

Después:

```powershell
flutter run -d ID_DEL_CELULAR --dart-define=API_BASE_URL=http://192.168.1.50:5034
```

El `AndroidManifest.xml` de esta entrega ya permite HTTP local (`usesCleartextTraffic=true`).

---

## 9. Verificar SQL antes de limpiar

Después de terminar el E2E ejecute:

```text
Scripts/04_VERIFICAR_PRUEBAS_SWAGGER.sql
```

Revise:

- usuarios QA;
- ruta QA;
- ejecución;
- evidencias;
- `EstadoIntegracionInstitucional=PENDIENTE`;
- 0 duplicados por `TipoOrigen + IdOrigen`;
- 0 duplicados de `CodMedidorInstalado`.

Puede ejecutar 04 varias veces: solo hace SELECT.

---

## 10. Limpieza final de datos de prueba

Solo cuando todo haya sido aprobado:

```text
Scripts/05_LIMPIEZA_PRUEBAS_SWAGGER.sql
```

El script elimina únicamente datos QA de `medidores.*`, incluso si la ruta usó un ODECO real. NO elimina ni actualiza `dbo.RECLAMOS`, `dbo.Medidor`, `dbo.SOCIO`, `dbo.Lectura` ni ninguna otra tabla institucional.

Las fotografías son archivos físicos; SQL no puede borrarlas. Antes de ejecutar 05, el script 04 muestra las rutas exactas de evidencia QA. Después puede eliminar solamente esos archivos concretos dentro de:

```text
C:\trabajos\Cosaalt\Cosaalt.API\wwwroot\uploads
```

No elimine carpetas completas que puedan contener evidencias reales.

`cosaaltunoprueba` se mantiene intacta como respaldo temporal hasta que todo el E2E final sea aprobado. Su limpieza se hará después mediante un procedimiento separado.
