/* =============================================================
   COSAALT - VERIFICACION DE DATOS QA / E2E
   SOLO SELECT. Ejecutar ANTES del script 05 de limpieza.
   Incluye Swagger + Flutter + bateria QA del mapa.
   ============================================================= */
USE cosaalt;
-- 9) Resumen por ruta para validar Monitoreo/Trabajo de Hoy
SELECT a.IdAsignacion, a.IdUsuarioApp, u.NombreUsuario AS Tecnico,
       a.FechaAsignacion, a.Estado,
       COUNT(d.IdDetalle) AS TotalParadas,
       SUM(CASE WHEN d.Estado = 'Completada' THEN 1 ELSE 0 END) AS Completadas,
       SUM(CASE WHEN d.Estado NOT IN ('Completada','Cancelada') THEN 1 ELSE 0 END) AS Pendientes
FROM medidores.AsignacionRuta a
LEFT JOIN medidores.DetalleRuta d ON d.IdAsignacion = a.IdAsignacion
LEFT JOIN medidores.Usuarios u ON u.Id = a.IdUsuarioApp
WHERE a.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR d.SolicitudId LIKE 'QA-%'
GROUP BY a.IdAsignacion, a.IdUsuarioApp, u.NombreUsuario, a.FechaAsignacion, a.Estado
ORDER BY a.IdAsignacion DESC;

GO

DECLARE @UsuariosQa TABLE (Id INT PRIMARY KEY, NombreUsuario VARCHAR(100));
INSERT INTO @UsuariosQa(Id, NombreUsuario)
SELECT Id, NombreUsuario
FROM medidores.Usuarios
WHERE NombreUsuario LIKE 'qa[_]%';

-- 1) Usuarios QA
SELECT u.Id, u.CodPersonaCorporativa, u.NombreUsuario, r.Nombre AS Rol, u.Activo,
       u.FechaCreacion, u.FechaActualizacion
FROM medidores.Usuarios u
JOIN medidores.RolApp r ON r.IdRol = u.IdRol
WHERE u.Id IN (SELECT Id FROM @UsuariosQa)
ORDER BY u.Id;

-- 2) Catalogos propios del modulo
IF OBJECT_ID('medidores.MotivosCambio','U') IS NOT NULL
    SELECT * FROM medidores.MotivosCambio ORDER BY IdMotivo;
IF OBJECT_ID('medidores.MarcasMedidor','U') IS NOT NULL
    SELECT * FROM medidores.MarcasMedidor ORDER BY Codigo;

-- 3) Parametros QA
SELECT p.*
FROM medidores.ParametrosNormativos p
WHERE p.Codigo LIKE 'QA-%';

-- 4) Bateria temporal del mapa
IF OBJECT_ID('medidores.SolicitudPruebaE2E','U') IS NOT NULL
BEGIN
    SELECT SolicitudId, OrdenPrueba, TipoOrigen, Estado, EsUrgente, RegSoc,
           NombreCliente, Direccion, NumeroMedidor, MarcaMedidor,
           MotivoObservacion, FechaSolicitud, Latitud, Longitud
    FROM medidores.SolicitudPruebaE2E
    ORDER BY OrdenPrueba;
END;

-- 5) Rutas QA: por usuario QA o por solicitudes QA
SELECT a.IdAsignacion, a.IdUsuarioApp, ut.NombreUsuario AS Tecnico,
       a.IdUsuarioAsignador, ua.NombreUsuario AS Asignador,
       a.FechaAsignacion, a.Estado, a.FechaCreacion,
       d.IdDetalle, d.TipoOrigen, d.IdOrigen, d.SolicitudId, d.RegSoc,
       d.CodMedidorActual, d.OrdenVisita, d.Estado AS EstadoDetalle,
       d.NombreCliente, d.Direccion, d.Latitud, d.Longitud, d.FechaFinalizacion
FROM medidores.AsignacionRuta a
JOIN medidores.DetalleRuta d ON d.IdAsignacion = a.IdAsignacion
LEFT JOIN medidores.Usuarios ut ON ut.Id = a.IdUsuarioApp
LEFT JOIN medidores.Usuarios ua ON ua.Id = a.IdUsuarioAsignador
WHERE a.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR a.IdUsuarioAsignador IN (SELECT Id FROM @UsuariosQa)
   OR d.SolicitudId LIKE 'QA-%'
ORDER BY a.IdAsignacion, d.OrdenVisita;

-- 6) Cambios QA
SELECT e.IdEjecucion, e.TipoOrigen, e.IdOrigen, e.RegSoc,
       e.IdUsuarioApp, u.NombreUsuario,
       e.FechaHoraEjecucion,
       e.CodMedidorRetirado, e.SerieMedidorRetirado, e.MarcaRetirado,
       e.LecturaRetiro, e.IdMotivoInstitucional, e.MotivoDescripcionSnapshot,
       e.CodMedidorInstalado, e.SerieMedidorInstalado, e.MarcaInstalado,
       e.Sincronizado, e.FechaSincronizacion,
       e.EstadoIntegracionInstitucional, e.ObservacionesInstalacion,
       e.Latitud, e.Longitud
FROM medidores.EjecucionCambio e
LEFT JOIN medidores.Usuarios u ON u.Id = e.IdUsuarioApp
WHERE e.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR e.IdOrigen LIKE 'QA-%'
   OR e.ObservacionesInstalacion LIKE 'QA-%'
ORDER BY e.IdEjecucion;

-- 7) Evidencias QA
SELECT f.IdFoto, f.IdEjecucion, f.TipoFoto, f.RutaArchivo, f.FechaRegistro
FROM medidores.EvidenciaFotografica f
JOIN medidores.EjecucionCambio e ON e.IdEjecucion = f.IdEjecucion
WHERE e.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR e.IdOrigen LIKE 'QA-%'
   OR e.ObservacionesInstalacion LIKE 'QA-%'
ORDER BY f.IdFoto;

-- 8) Integridad: ambos resultados deben devolver CERO filas
SELECT TipoOrigen, IdOrigen, COUNT(*) AS Cantidad
FROM medidores.EjecucionCambio
GROUP BY TipoOrigen, IdOrigen
HAVING COUNT(*) > 1;

SELECT CodMedidorInstalado, COUNT(*) AS Cantidad
FROM medidores.EjecucionCambio
WHERE CodMedidorInstalado IS NOT NULL
GROUP BY CodMedidorInstalado
HAVING COUNT(*) > 1;
GO
