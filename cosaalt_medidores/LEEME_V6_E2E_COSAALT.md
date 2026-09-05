# COSAALT V6 - flujo E2E Asignador/Tecnico

Esta entrega corrige el circuito que en V5 podia guardar una ruta pero no mostrarla en Monitoreo ni en Trabajo de Hoy.

## Cambios principales

- POST `/api/rutas/asignar` confirma la persistencia releyendo SQL.
- GET `/api/rutas/activas?fecha=YYYY-MM-DD` alimenta Monitoreo del Asignador.
- GET `/api/rutas/tecnico/{id}/actual` alimenta Trabajo de Hoy del Tecnico.
- La ruta se guarda con fecha normalizada al dia.
- El Tecnico usa cache SQLite primero y luego intenta refrescar API.
- Se precargan solicitud, motivos y medidores libres para abrir el formulario sin conexion.
- Al registrar una ejecucion: DetalleRuta -> Completada; ruta -> EnCurso/Finalizado.
- ODECO intenta georreferenciarse desde la ultima `dbo.Lectura` valida del medidor/socio.
- LECTURA queda preparada para observaciones 2,4,11 si `dbo.Lec_Obl` posee `Cod_Lec` y `Cod_Obl`.
- Android compila contra SDK 37.

## SQL

- 04: verificar QA/E2E y duplicados.
- 05: limpiar todo lo QA de `medidores.*` sin tocar `dbo.*`.
- 06: crear/sincronizar catalogos permanentes del modulo.
- 07: cargar bateria temporal de 20 solicitudes alrededor de Plaza Los Laureles.
- 08: diagnostico SOLO SELECT de rutas y estructura real de `dbo.Lec_Obl`.

## Prueba offline en Windows

Si Flutter Windows y la API corren en la MISMA PC con `http://localhost:5034`, apagar Wi-Fi no garantiza modo offline: Flutter aun puede llegar a la API por localhost.

Para probar offline de verdad:

1. Con API encendida, inicia sesion como Tecnico y abre `Mi Recorrido` una vez para descargar la ruta a SQLite.
2. Deten la API con `Ctrl+C` en la terminal de `dotnet run`.
3. Sin cerrar Flutter, vuelve a `Mi Recorrido`: debe mostrarse desde cache.
4. Abre una parada y guarda el cambio: debe quedar `Pendiente sync`.
5. Vuelve a iniciar la API.
6. Pulsa `Sincronizar`: debe pasar a `Completada` y actualizar el avance del Asignador.

No es necesario desconectar la VPN para esta prueba. De hecho, conviene dejarla conectada para que al volver a iniciar la API esta pueda acceder inmediatamente a la BD institucional.

## Android fisico

Con dos dispositivos conectados, indicar siempre `-s ID` en ADB. Ejemplo:

```powershell
adb -s 1209dd0f reverse tcp:5034 tcp:5034
flutter run -d 1209dd0f --dart-define=API_BASE_URL=http://127.0.0.1:5034
```

Para simular offline en el telefono sin apagar la VPN de la PC:

```powershell
adb -s 1209dd0f reverse --remove tcp:5034
```

Para volver online:

```powershell
adb -s 1209dd0f reverse tcp:5034 tcp:5034
```

## Orden final de prueba

1. Asignador selecciona 4 puntos y asigna a un tecnico.
2. Monitoreo debe mostrar la ruta inmediatamente.
3. Tecnico inicia sesion y ve las mismas 4 paradas.
4. Tecnico abre ruta una vez online.
5. Cortar API / adb reverse.
6. Ruta y formulario siguen disponibles desde SQLite.
7. Guardar cambio -> Pendiente sync.
8. Restablecer API / adb reverse.
9. Sincronizar -> Completada.
10. Asignador ve avance actualizado.
11. Al completar todas las paradas -> ruta Finalizado/100%.
12. Ejecutar SQL 04; duplicados deben ser cero.
13. Cuando todo sea aprobado, ejecutar SQL 05.
