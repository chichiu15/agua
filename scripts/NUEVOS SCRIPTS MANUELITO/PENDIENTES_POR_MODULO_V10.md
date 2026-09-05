# COSAALT Medidores — pendientes por módulo

Fecha de corte: 5 de septiembre de 2026. Esta lista separa lo que ya funciona de lo que falta; sirve para repartir tareas sin asumir que una pantalla parcial equivale a un módulo terminado.

## Prioridad transversal (antes de producción)

| Prioridad | Tarea | Entrega verificable |
|---|---|---|
| Crítica | Implementar JWT real, autenticación y autorización por rol en la API | Endpoints devuelven 401 sin token y 403 con rol incorrecto; pruebas automatizadas por rol |
| Crítica | Confirmar e implementar la escritura institucional posterior al cambio | Procedimiento autorizado actualiza Manantial/dbo y cambia `EstadoIntegracionInstitucional` de PENDIENTE a REGISTRADO o ERROR |
| Crítica | Confirmar origen de solicitudes LECTURA y criterio ODECO | Consultas documentadas con casos reales aprobados por COSAALT |
| Alta | Pruebas automatizadas de repositorios, API, sincronización e idempotencia | Suite reproducible y prueba de carga concurrente |
| Alta | Configuración segura por ambiente | Cadenas y secretos fuera del repositorio; perfiles Desarrollo/QA/Producción |
| Alta | Registro de auditoría | Quién creó, editó, asignó, sincronizó, anuló y exportó, con fecha y valor anterior/nuevo |
| Alta | Instaladores firmados y despliegue | APK/AAB firmado, instalador Windows, iconos, versión, actualización y rollback |
| Media | Observabilidad | Logs estructurados, correlación de errores, métricas y alertas de API/SQL/VPN |

## Asignador

Ya disponible: dashboard, bandeja y filtros, selección múltiple, orden manual/sugerido, asignación a técnico o a sí mismo, técnicos ocupados por rutas antiguas activas, monitoreo y detalle de avance.

| Prioridad | Falta | Criterio de aceptación |
|---|---|---|
| Alta | Cancelar ruta con motivo | Libera técnico, conserva historial y no borra ejecuciones |
| Alta | Reasignar paradas no ejecutadas | Mueve solo pendientes, registra asignador y evita duplicados |
| Alta | Editar orden de una ruta ya creada | No modifica paradas terminadas y actualiza monitoreo |
| Alta | Definir tratamiento de `NoAtendida` y reprogramación | Regla aprobada y flujo visible al día siguiente |
| Media | Actualización en tiempo real | Polling documentado o SignalR; indicador de última actualización |
| Media | Paginación/consulta SQL del lado servidor | No cargar miles de ODECO en memoria para filtrar |

## Técnico

Ya disponible: ruta vigente incluso de días anteriores, caché local, formulario de cambio, medidor disponible con lista/búsqueda, fotos opcionales, guardado offline, historial, sincronización con progreso e idempotencia.

| Prioridad | Falta | Criterio de aceptación |
|---|---|---|
| Crítica | Integración institucional del cambio | Resultado confirmado por COSAALT y reintento controlado |
| Alta | Reservar medidor al abrir/guardar trabajo | Dos técnicos no pueden elegir el mismo medidor disponible |
| Alta | Validaciones funcionales definitivas | Rangos de lectura, motivo, observaciones y casos sin cambio aprobados |
| Alta | Recuperación de conflictos | UI permite corregir y reenviar sin editar JSON manualmente |
| Alta | Gestión de ruta no atendida | Motivo, evidencia opcional, reprogramación y estado consistente |
| Media | Sincronización automática opcional | Reintenta al volver Internet sin duplicar y muestra control al usuario |
| Media | Limpieza de archivos locales | Borra fotos/JSON confirmados y conserva pendientes |
| Media | Pruebas Android reales | Cámara, permisos, GPS, compresión, suspensión y reconexión en dos versiones Android |

## Mecánico

Estado actual: existe login/rol y backend parcial M1–M5 (bandeja, tomar solicitud, listar, consultar datos y guardar ensayo/participantes). El frontend solo es una pantalla provisional; el módulo no está terminado.

| Bloque | Tarea clara | Criterio de aceptación |
|---|---|---|
| M1 | Dashboard y navegación del Mecánico | Acceso a pendientes, en curso, historial e informes |
| M2 | Bandeja de solicitudes | Busca/filtra ODECO, LECTURA o REVISION y evita doble toma |
| M3 | Tomar/iniciar verificación | Asocia mecánico, socio y medidor con control concurrente transaccional |
| M4 | Ficha socio/medidor e historial | Muestra datos institucionales y movimientos anteriores |
| M5 | Formulario completo de ensayo | Valida lecturas, volumen patrón, caudal, fugas, observaciones y participantes |
| M6 | Motor normativo | Selecciona parámetro vigente, calcula volumen/error y conserva la regla aplicada |
| M7 | Finalizar y clasificar | Produce CUMPLE/NO CUMPLE/INDETERMINADO con confirmación y bloqueo de edición |
| M8 | Informe técnico | Genera PDF versionado, número, fecha, firma/estado y descarga |
| M9 | Evidencias mecánicas | Define y carga fotos/documentos si el Taller los exige |
| M10 | Historial y reapertura controlada | Consulta, corrección autorizada y nueva versión sin perder trazabilidad |
| M11 | Frontend Windows completo | Estados de carga/error, búsquedas al escribir y diseño adaptable |
| M12 | Pruebas | Casos límite, concurrencia, cálculo, informe, roles y datos QA |

## Administrador

Ya disponible: dashboard, usuarios, catálogos de marcas/motivos, parámetros, solicitudes, recorridos, sincronización, movimientos, histórico, verificaciones, informes y exportación PDF/Excel. En V10 las solicitudes QA también aparecen y las búsquedas principales filtran al escribir.

| Prioridad | Falta | Criterio de aceptación |
|---|---|---|
| Crítica | Protección real de endpoints por rol | Administrador autorizado; otros roles reciben 403 |
| Alta | Auditoría administrativa | CRUD, activaciones, parámetros y exportaciones quedan registrados |
| Alta | Cierre de verificación/informe | La vista deja de ser solo consulta cuando el flujo Mecánico M6–M8 exista |
| Alta | Gestión de incidencias de sincronización | Reintentar, descartar con autorización y ver detalle técnico amigable |
| Alta | Paginación/filtrado directo en SQL | Consultas estables con volumen institucional real |
| Media | Reglas de retención y privacidad | Plazos para fotos, informes, logs y exportaciones |
| Media | Permisos finos | Separar superadministrador, consulta, catálogos y reportes si COSAALT lo requiere |
| Media | Copias de seguridad/recuperación | Procedimiento probado antes de cambios de esquema o despliegues |


