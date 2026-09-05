# COSAALT - PRUEBAS EXACTAS DEL BACKEND CONTRA `cosaalt`

Fecha de paquete: 01/09/2026.

Estas pruebas estan pensadas para la base institucional `cosaalt`. Durante esta ronda:

- `dbo.*` se usa como fuente institucional y **no se modifica** por los flujos de prueba incluidos;
- los datos QA se guardan solamente en `medidores.*`;
- al final se ejecuta `Scripts/05_LIMPIEZA_PRUEBAS_SWAGGER.sql` para retirar lo creado por QA;
- COSAALT confirmo `dis_med`: `L=Libre`, `O=Ocupado`, `B=Baja`; para la prueba se usa el criterio conservador `cod_est=5 (PERFECTO) + dis_med='L' + reg_soc=0`;
- no se inventa aun el origen LECTURA ni la integracion final con Manantial.

---

## 0. Antes de abrir Swagger

En SSMS, conectado a la base `cosaalt`, ejecutar en este orden:

1. `Scripts/01_CREAR_ESQUEMA_MEDIDORES_COSAALT.sql`  
   Es idempotente. Si ya se ejecuto, solo verifica/crea lo faltante de `medidores.*`.
2. `Scripts/02_AJUSTES_INTEGRIDAD_BACKEND.sql`  
   Agrega indices unicos necesarios para evitar duplicados de sincronizacion.
3. `Scripts/03_SMOKE_TEST_BACKEND_COSAALT.sql`  
   **Solo SELECT.** Revisar que no haya errores y que aparezcan personas, medidores, reclamos y las tablas `medidores.*`.

No ejecutar el script 05 todavia.

---

## 1. Compilar y levantar la API

PowerShell:

```powershell
cd C:\trabajos\Cosaalt\Cosaalt.API

$env:RepositoryMode="Sql"
$env:ConnectionStrings__CosaaltDb="TU_CADENA_REAL_PERO_CON_Database=cosaalt"

dotnet restore .\Cosaalt.API.csproj
dotnet build .\Cosaalt.API.csproj
dotnet run --project .\Cosaalt.API.csproj --launch-profile http
```

Esperado en build:

```text
Build succeeded.
```

Esperado al ejecutar:

```text
Now listening on: http://localhost:5034
```

Abrir:

```text
http://localhost:5034/swagger
```

> No guardes la contrasena real de SQL dentro del repositorio.

---

# BLOQUE A - BASE, ROLES Y USUARIOS

## 2. Roles

Swagger:

```text
GET /api/usuarios/roles
```

**Execute**.

Debe responder `200` y contener los roles:

- tecnico
- asignador
- mecanico
- administrador

Anota los IDs que devuelva para `tecnico` y `asignador`.

Los llamaremos:

```text
ID_ROL_TECNICO
ID_ROL_ASIGNADOR
```

---

## 3. Personas institucionales

```text
GET /api/usuarios/funcionarios
```

Debe responder `200` y mostrar personas provenientes de `dbo.PERSONAS`.

Para esta prueba no es obligatorio vincular los usuarios QA a una persona, por eso enviaremos `null`.

---

## 4. Crear usuario QA Asignador

```text
POST /api/usuarios
```

Body, reemplazando `ID_ROL_ASIGNADOR` por el numero real:

```json
{
  "codFunCorporativo": null,
  "nombreUsuario": "qa_asignador_20260901",
  "contrasena": "Qa2026!Asignador",
  "idRol": ID_ROL_ASIGNADOR,
  "activo": true
}
```

Debe responder `201`.

Anota el campo:

```text
id
```

Lo llamaremos `ID_ASIGNADOR_QA`.

---

## 5. Crear usuario QA Tecnico

```text
POST /api/usuarios
```

```json
{
  "codFunCorporativo": null,
  "nombreUsuario": "qa_tecnico_20260901",
  "contrasena": "Qa2026!Tecnico",
  "idRol": ID_ROL_TECNICO,
  "activo": true
}
```

Debe responder `201`.

Anota `id` como:

```text
ID_TECNICO_QA
```

---

## 6. Login de ambos usuarios

### Tecnico

```text
POST /api/auth/login
```

```json
{
  "usuario": "qa_tecnico_20260901",
  "contrasena": "Qa2026!Tecnico"
}
```

Esperado: `200`, rol `tecnico` y token no vacio.

### Asignador

```json
{
  "usuario": "qa_asignador_20260901",
  "contrasena": "Qa2026!Asignador"
}
```

Esperado: `200`, rol `asignador`.

La API conserva compatibilidad con usuarios antiguos y los nuevos usuarios se almacenan con hash PBKDF2-SHA256.

---

# BLOQUE B - CATALOGOS Y REGLAS

## 7. Marcas institucionales

```text
GET /api/catalogos/marcas
```

Esperado `200`.

Las marcas se obtienen de los valores reales de `dbo.Medidor.Mar_Med`; no se usa una tabla inventada.

---

## 8. Medidores candidatos disponibles

```text
GET /api/catalogos/medidores-disponibles?limite=20
```

Esperado `200` y una coleccion `medidores`.

Escoge **una sola fila** y anota:

```text
COD_MEDIDOR_NUEVO
SERIE_MEDIDOR_NUEVO
MARCA_MEDIDOR_NUEVO
```

No modifica ese medidor en `dbo.Medidor`; solo lo utilizaremos como candidato en una ejecucion QA de `medidores.EjecucionCambio`.

---

## 9. Motivos de cambio

```text
GET /api/catalogos/motivos?incluirInactivos=true
```

Hay dos resultados validos en esta fase:

### Caso A - responde `200`
La tabla institucional de motivos existe en `cosaalt`. Escoge un motivo activo y anota su `id` como `ID_MOTIVO`.

### Caso B - responde `503 INTEGRACION_PENDIENTE`
Tambien es correcto mientras COSAALT no confirme donde queda el catalogo oficial en `cosaalt`. **No crear ninguna tabla alternativa por cuenta propia.**

Para continuar la prueba tecnica de ejecucion si estas en Caso B, usa temporalmente:

```text
ID_MOTIVO = 1
```

El backend guardara el snapshot `Motivo institucional #1`, sin escribir en `dbo`.

---

## 10. Parametro normativo QA

```text
POST /api/parametros-normativos
```

```json
{
  "codigo": "QA-SWAGGER-20260901",
  "descripcion": "Parametro temporal para validar el backend",
  "errorMaxPermitido": 2.0,
  "caudalMin": 99990,
  "caudalMax": 99999,
  "vigenciaInicio": null,
  "vigenciaFin": null,
  "activo": true
}
```

Esperado `201`. Anota el `id` si quieres verificarlo individualmente.

Ahora:

```text
GET /api/parametros-normativos/vigente?caudal=99995
```

Debe responder `200` y devolver `QA-SWAGGER-20260901`.

---

# BLOQUE C - ODECO REAL + ASIGNACION DE RUTA

## 11. Obtener solicitudes

```text
GET /api/solicitudes
```

Esperado `200`.

COSAALT confirmo que el cambio de medidor no nace automaticamente de un `CodTipRec`: se incorpora como observacion del inspector y luego se valida manualmente. Por eso la bandeja muestra reclamos para seleccion operativa y no aplica un filtro automatico inventado. Para la prueba selecciona una fila ODECO que tenga:

- `codCon` mayor que 0;
- medidor/serie si esta disponible;
- estado distinto de `Completada`.

Anota:

```text
COD_REC          = numero de folioOdeco, por ejemplo 1280
COD_CON          = codCon
NOMBRE_SOCIO     = nombreCliente
DIRECCION        = direccion
SERIE_RETIRADO   = numeroMedidor
MARCA_RETIRADO   = marcaMedidor
```

Tambien puedes verificar la misma fila con:

```text
GET /api/solicitudes/ODECO-COD_REC
```

Ejemplo si elegiste 1280:

```text
GET /api/solicitudes/ODECO-1280
```

---

## 12. Asignar el ODECO al tecnico QA

```text
POST /api/rutas/asignar
```

Reemplaza los valores MAYUSCULOS por los que anotaste:

```json
{
  "idUsuarioAsignador": ID_ASIGNADOR_QA,
  "idUsuarioTecnico": ID_TECNICO_QA,
  "fechaAsignacion": "2026-09-01T12:00:00",
  "detalles": [
    {
      "tipoOrigen": "ODECO",
      "idOrigen": "COD_REC",
      "solicitudId": "QA-ODECO-COD_REC",
      "ordenVisita": 1,
      "latitud": null,
      "longitud": null,
      "nombreCliente": "NOMBRE_SOCIO",
      "direccion": "DIRECCION"
    }
  ]
}
```

Esperado `201`.

Anota `idAsignacion` como `ID_RUTA_QA`.

El backend volvera a resolver desde `dbo.RECLAMOS` el socio y, si existe, el medidor actual; no confia solamente en los textos enviados por el frontend.

---

## 13. Consultar ruta del tecnico

```text
GET /api/rutas/tecnico/ID_TECNICO_QA?fecha=2026-09-01
```

Debe aparecer `ID_RUTA_QA`, una parada y `QA-ODECO-COD_REC`.

Tambien:

```text
GET /api/rutas/ID_RUTA_QA
```

---

# BLOQUE D - EVIDENCIAS Y CAMBIO DE MEDIDOR

## 14. Subir evidencia del medidor retirado

```text
POST /api/evidencias/upload
```

En Swagger elige `multipart/form-data`:

```text
archivo   = una foto JPG/PNG/WEBP pequena
TipoFoto  = MedidorRetirado
idOrigen  = QA-COD_REC
```

> En Swagger el nombre visible del campo puede aparecer `tipoFoto`; utiliza el nombre que muestre el formulario generado.

Debe responder `200` con una ruta de archivo. Copiala como:

```text
RUTA_FOTO_RETIRADO
```

Repite con:

```text
tipoFoto = MedidorNuevo
```

Copia la segunda ruta como:

```text
RUTA_FOTO_NUEVO
```

---

## 15. Registrar el cambio

```text
POST /api/ejecuciones
```

Body:

```json
{
  "tipoOrigen": "ODECO",
  "idOrigen": "COD_REC",
  "idUsuarioApp": ID_TECNICO_QA,
  "fechaHoraEjecucion": "2026-09-01T12:30:00",
  "numeroMedidorRetirado": "SERIE_RETIRADO",
  "marcaRetirado": "MARCA_RETIRADO",
  "lecturaRetiro": 123.45,
  "idMotivo": ID_MOTIVO,
  "numeroMedidorInstalado": "SERIE_MEDIDOR_NUEVO",
  "marcaInstalado": "MARCA_MEDIDOR_NUEVO",
  "observacionesInstalacion": "QA-SWAGGER-20260901 - prueba controlada; no integra dbo",
  "latLong": null,
  "evidencias": [
    {
      "tipoFoto": "MedidorRetirado",
      "rutaArchivo": "RUTA_FOTO_RETIRADO"
    },
    {
      "tipoFoto": "MedidorNuevo",
      "rutaArchivo": "RUTA_FOTO_NUEVO"
    }
  ],
  "regSoc": COD_CON,
  "codMedidorRetirado": null,
  "codMedidorInstalado": COD_MEDIDOR_NUEVO,
  "latitud": null,
  "longitud": null
}
```

Esperado `201`.

Debe devolver:

```text
sincronizado = true
yaExistia = false
```

Anota `id` como `ID_EJECUCION_QA`.

### IMPORTANTE
Esta operacion:

- **SI** inserta en `medidores.EjecucionCambio` y `medidores.EvidenciaFotografica`;
- **SI** marca el `medidores.DetalleRuta` QA como completado;
- **NO** cambia `dbo.Medidor`;
- **NO** cambia `dbo.SOCIO`;
- **NO** crea historial institucional;
- deja `EstadoIntegracionInstitucional = PENDIENTE` hasta que COSAALT confirme el mecanismo oficial de Manantial.

---

## 16. Prueba de idempotencia

Sin cambiar absolutamente nada, vuelve a ejecutar el mismo:

```text
POST /api/ejecuciones
```

con exactamente el mismo body del paso 15.

Esperado:

- no se crea otra fila;
- devuelve el mismo `id` o el registro ya existente;
- `yaExistia = true`.

---

## 17. Historial del cambio

```text
GET /api/ejecuciones/historial?codCon=COD_CON
```

Debe aparecer la ejecucion QA con:

- socio;
- medidor retirado;
- medidor instalado;
- tecnico;
- motivo/snapshot;
- las dos evidencias.

---

## 18. Sincronizacion offline idempotente

```text
POST /api/sincronizacion/procesar-cambios
```

Puedes reutilizar la ejecucion ya registrada para comprobar que no duplica:

```json
{
  "idUsuario": ID_TECNICO_QA,
  "ejecuciones": [
    {
      "tipoOrigen": "ODECO",
      "idOrigen": "COD_REC",
      "idUsuarioApp": ID_TECNICO_QA,
      "fechaHoraEjecucion": "2026-09-01T12:30:00",
      "numeroMedidorRetirado": "SERIE_RETIRADO",
      "marcaRetirado": "MARCA_RETIRADO",
      "lecturaRetiro": 123.45,
      "idMotivo": ID_MOTIVO,
      "numeroMedidorInstalado": "SERIE_MEDIDOR_NUEVO",
      "marcaInstalado": "MARCA_MEDIDOR_NUEVO",
      "observacionesInstalacion": "QA-SWAGGER-20260901 - prueba controlada; no integra dbo",
      "latLong": null,
      "evidencias": [],
      "regSoc": COD_CON,
      "codMedidorRetirado": null,
      "codMedidorInstalado": COD_MEDIDOR_NUEVO,
      "latitud": null,
      "longitud": null
    }
  ]
}
```

Esperado `200`, `procesadosOk = 1`, `errores = 0`. No debe aparecer una segunda ejecucion en SQL.

---

# BLOQUE E - ADMINISTRADOR / SUPERVISION

## 19. Dashboard

```text
GET /api/admin/dashboard
```

Esperado `200` aunque haya datos vacios en algun modulo.

Debe incluir, segun lo disponible:

- solicitudes;
- rutas;
- cambios;
- verificaciones;
- tecnicos;
- alertas de integracion pendiente.

No debe aparecer stack trace SQL en la respuesta.

---

## 20. Bandeja global

```text
GET /api/admin/solicitudes?page=1&pageSize=25
```

Esperado `200`.

Busca el `COD_REC` usado. Debe mostrarse como completado porque ya existe `medidores.EjecucionCambio`.

---

## 21. Recorridos

```text
GET /api/admin/rutas?fecha=2026-09-01&page=1&pageSize=20
```

Debe aparecer la ruta QA y su avance.

Luego:

```text
GET /api/admin/rutas/ID_RUTA_QA
```

---

## 22. Estado de sincronizacion

```text
GET /api/admin/sincronizacion?fecha=2026-09-01
```

Esperado `200`.

---

## 23. Movimiento de medidores

```text
GET /api/reportes/movimientos?buscar=COD_CON&page=1&pageSize=25
```

Debe aparecer `ID_EJECUCION_QA`.

---

## 24. Historico institucional

```text
GET /api/reportes/historico-corporativo?codCon=COD_CON&page=1&pageSize=25
```

Esperado `200`.

La fuente ahora es `dbo.hist_pred_med`; no se inventa `dbo.CambioMedidores`.

Los estados historicos A/B se muestran sin inventar su significado.

---

## 25. Verificaciones administrativas

```text
GET /api/admin/verificaciones?page=1&pageSize=25
```

Esperado `200`, incluso si no existen verificaciones.

No es necesario crear datos mecanicos en esta ronda porque ese modulo se continuara despues.

---

## 26. Estadisticas

```text
GET /api/reportes/estadisticas
```

Esperado `200`.

Debe contabilizar el cambio QA dentro de los datos propios de la aplicacion.

---

# BLOQUE F - EXPORTACIONES

## 27. Excel de movimientos

```text
GET /api/reportes/movimientos/excel?buscar=COD_CON
```

Debe descargar un `.xlsx` que abra en Excel **sin ventana de reparacion**.

---

## 28. PDF de movimientos

```text
GET /api/reportes/movimientos/pdf?buscar=COD_CON
```

Debe descargar un PDF valido.

---

## 29. Historico Excel/PDF

```text
GET /api/reportes/historico-corporativo/excel?codCon=COD_CON
GET /api/reportes/historico-corporativo/pdf?codCon=COD_CON
```

Ambos deben abrir correctamente.

---

## 30. Verificaciones Excel/PDF

```text
GET /api/reportes/verificaciones/excel
GET /api/reportes/verificaciones/pdf
```

Deben abrir correctamente aunque el listado sea pequeno o este vacio.

---

# BLOQUE G - COMPROBACION SQL Y LIMPIEZA

## 31. Revisar exactamente lo que se guardo

En SSMS ejecutar:

```text
Scripts/04_VERIFICAR_PRUEBAS_SWAGGER.sql
```

Debe mostrar:

- los dos usuarios QA;
- el parametro QA;
- la ruta QA;
- la ejecucion QA;
- evidencias QA;
- **cero duplicados** por origen;
- **cero duplicados** por medidor instalado.

---

## 32. Limpiar los datos QA

Solo cuando todo este validado, ejecutar:

```text
Scripts/05_LIMPIEZA_PRUEBAS_SWAGGER.sql
```

Este script elimina solamente los datos identificados como QA de `medidores.*`.

**No elimina ni modifica registros de `dbo.*`.**

Al final las cuatro verificaciones del script deben devolver `Cantidad = 0`.

---

# RESULTADO DE CIERRE DE ESTA RONDA

La ronda queda aprobada cuando:

1. `dotnet build` termina correctamente.
2. Swagger levanta en puerto 5034.
3. Personas, marcas, reclamos y medidores salen de `cosaalt`.
4. Se crean usuarios QA sin tocar `dbo.PERSONAS`.
5. El asignador crea una ruta.
6. El tecnico consulta la ruta.
7. El tecnico registra el cambio con evidencias.
8. Repetir el cambio no duplica datos.
9. Sincronizar el mismo cambio tampoco lo duplica.
10. Dashboard/Admin/Reportes responden 200.
11. Excel abre sin reparacion y PDF abre normalmente.
12. El script 04 confirma los registros.
13. El script 05 deja limpios los datos QA.
14. No se realizo ninguna escritura institucional en `dbo`.

## Pendientes que NO deben inventarse

Quedan condicionados a la respuesta de COSAALT:

- significado exacto de `dis_med = L/O/B`;
- confirmacion oficial de la regla de disponibilidad;
- tipos `CodTipRec` que pertenecen al modulo de medidores;
- regla que convierte una observacion de lectura en cambio o revision;
- significado A/B de `hist_pred_med.est_med`;
- mecanismo oficial para registrar el cambio final en Manantial;
- catalogo oficial definitivo de motivos si `dbo.MotivosCambioMedidor` no existe en `cosaalt`;
- reglas normativas definitivas del modulo mecanico.
