# COSAALT — Módulo de Gestión y Cambio de Medidores
## Informe de presentación del sistema (flujo de trabajo)

---

## 1. ¿Qué problema resuelve?

La cooperativa necesita **digitalizar y controlar el proceso de cambio de medidores** que hoy se maneja en papel y de forma descentralizada. Este sistema centraliza:

1. **Qué trabajos hay que hacer** (las solicitudes/órdenes entrantes).
2. **A quién se le asigna cada trabajo** (los técnicos de campo).
3. **Qué se hizo realmente** (la ejecución del cambio, con datos y fotografías de respaldo).
4. **El control posterior** (historial verificable y monitoreo del avance en tiempo real).

El resultado: trazabilidad completa desde que llega la solicitud hasta que el cambio queda registrado con evidencia fotográfica, sin depender de planillas físicas.

---

## 2. Usuarios del sistema

| Rol | Qué puede hacer |
|-----|-----------------|
| **Asignador** | Arma los recorridos, elige qué solicitudes entran, les da orden, las asigna a un técnico, monitorea el avance y consulta el historial. |
| **Técnico de campo** | Ve las visitas asignadas para el día, ejecuta cada cambio de medidor (carga datos y fotos) y sincroniza el trabajo al servidor. |

---

## 3. Flujo del sistema (paso a paso)

El recorrido completo se divide en **cuatro fases**:

```
  ① BANDEJA         ② ASIGNACIÓN       ③ EJECUCIÓN        ④ CONTROL
  ──────────        ─────────────      ─────────────       ──────────
  Llegan las        El asignador        El técnico          El asignador
  solicitudes       arma y asigna      ejecuta cada        monitorea,
  de cambio         la ruta del día    visita en campo      consulta el
  de medidor        a un técnico       (datos + fotos)     historial
```

### Fase 1 — Bandeja de solicitudes
- El sistema **reúne automáticamente** las solicitudes de cambio de medidor (por ejemplo las órdenes ODECO) a partir de los registros existentes de la cooperativa.
- Cada solicitud se muestra en un **mapa** con su ubicación, datos del cliente y del medidor actual.
- Se distinguen visualmente las que tienen carácter **urgente** (ODECO).

### Fase 2 — Asignación del recorrido (asignador)
- El asignador **selecciona en el mapa** las solicitudes que formarán la jornada de trabajo.
- **Reordena la lista** (arrastrar y soltar) para fijar la secuencia lógica de visita y optimizar el recorrido.
- **Elige el técnico** que lo ejecutará y confirma la asignación.
- La ruta queda registrada en el sistema con su fecha, técnico y listado de paradas.

### Fase 3 — Ejecución en campo (técnico)
- El técnico abre **"Mi recorrido"** y ve las paradas del día, su orden y el avance (X de Y completadas con barra de progreso).
- En cada visita toca **"Ejecutar"** y el sistema le presenta la ficha del socio y del medidor a reemplazar.
- Registra:
  - Lectura y datos del **medidor retirado**.
  - Motivo del cambio.
  - Número, marca y estado del **medidor nuevo** instalado.
  - Observaciones.
  - **Dos fotografías de respaldo**: una del medidor retirado y otra del nuevo, tomadas en el momento.
- Al guardar, la parada queda marcada como **"Completada"** y el trabajo se conserva en el dispositivo.

> **Trabajo sin conexión (offline):** como el técnico trabaja a la intemperie, los datos y las fotos se guardan **primero en el dispositivo**. No se pierde nada si en ese momento no hay internet.

### Fase 4 — Sincronización y control (técnico + asignador)
- Cuando el técnico tiene conexión, desde **"Sincronizar"** sube los cambios pendientes al servidor (datos + fotografías) en un solo lote.
- El **asignador** puede **monitorear en tiempo real** el avance de cada ruta: porcentaje de paradas completadas por técnico, y el detalle de cada punto (completado o pendiente).
- El **historial** consolida todas las ejecuciones sincronizadas: fecha, cliente, dirección, medidor retirado → instalado, lecturas, motivo, técnico y miniaturas de las fotos (ampliables).

---

## 4. Resumen del valor para la cooperativa

- **Trazabilidad total:** toda visita queda documentada (datos + fotografía), ideal para auditoría y respaldo ante reclamos.
- **Control de campo real:** el asignador ve quién va, qué hace y cuánto falta, sin depender de llamadas ni planillas.
- **Fiabilidad sin conexión:** el técnico nunca pierde trabajo por falta de internet; sincroniza cuando puede.
- **Centralización:** toda la información vive en una única base de datos del servidor, reemplazando los registros dispersos en papel.

---

## 5. Aspectos técnicos (resumen)

- **App de campo/móvil:** desarrollada en **Flutter** (multiplataforma) para que el técnico la use directamente en el terreno.
- **Servidor central:** **API REST en .NET** con base de datos **SQL Server**, que concentra solicitudes, asignaciones, ejecuciones y evidencias.
- **Fotografías:** se guardan en el servidor y su ruta queda vinculada a cada ejecución, sirviéndose como evidencia visual.
- **Sincronización:** mecanismo de subida por lotes de lo registrado sin conexión.

> *Sistema en estado de prototipo funcional (MVP): el flujo completo ya opera de punta a punta y se encuentra en etapa de pruebas y ajustes.*
