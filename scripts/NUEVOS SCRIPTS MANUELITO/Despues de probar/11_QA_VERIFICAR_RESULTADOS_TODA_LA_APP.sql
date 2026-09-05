/* =============================================================
   COSAALT - QA TEMPORAL: VERIFICACION DE RESULTADOS
   Solo consulta. No modifica ninguna tabla.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

SELECT 'Solicitudes QA' AS Elemento, COUNT_BIG(*) AS Cantidad
FROM medidores.SolicitudPruebaE2E
UNION ALL
SELECT 'Usuarios QA', COUNT_BIG(*) FROM medidores.Usuarios WHERE NombreUsuario LIKE 'qa[_]%'
UNION ALL
SELECT 'Rutas QA', COUNT_BIG(DISTINCT a.IdAsignacion)
FROM medidores.AsignacionRuta a INNER JOIN medidores.DetalleRuta d ON d.IdAsignacion=a.IdAsignacion
WHERE d.SolicitudId LIKE 'QA-%' OR d.IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Paradas QA', COUNT_BIG(*) FROM medidores.DetalleRuta WHERE SolicitudId LIKE 'QA-%' OR IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Cambios QA', COUNT_BIG(*) FROM medidores.EjecucionCambio WHERE IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Fotos QA', COUNT_BIG(*)
FROM medidores.EvidenciaFotografica f INNER JOIN medidores.EjecucionCambio e ON e.IdEjecucion=f.IdEjecucion
WHERE e.IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Verificaciones QA', COUNT_BIG(*) FROM medidores.Verificaciones WHERE IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Ensayos QA', COUNT_BIG(*)
FROM medidores.EnsayoVerificacion e INNER JOIN medidores.Verificaciones v ON v.IdVerificacion=e.IdVerificacion
WHERE v.IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Informes QA', COUNT_BIG(*)
FROM medidores.InformesVerificacion i INNER JOIN medidores.Verificaciones v ON v.IdVerificacion=i.IdVerificacion
WHERE v.IdOrigen LIKE 'QA-%';

SELECT a.IdAsignacion, a.FechaAsignacion, a.Estado AS EstadoRuta,
       u.NombreUsuario AS Tecnico, d.OrdenVisita, d.SolicitudId,
       d.TipoOrigen, d.IdOrigen, d.Estado AS EstadoParada
FROM medidores.AsignacionRuta a
INNER JOIN medidores.Usuarios u ON u.Id=a.IdUsuarioApp
INNER JOIN medidores.DetalleRuta d ON d.IdAsignacion=a.IdAsignacion
WHERE d.SolicitudId LIKE 'QA-%' OR d.IdOrigen LIKE 'QA-%'
ORDER BY a.IdAsignacion DESC, d.OrdenVisita;

SELECT e.IdEjecucion, e.TipoOrigen, e.IdOrigen, u.NombreUsuario AS Tecnico,
       e.FechaHoraEjecucion, e.SerieMedidorRetirado,
       e.SerieMedidorInstalado, e.Sincronizado,
       e.EstadoIntegracionInstitucional
FROM medidores.EjecucionCambio e
INNER JOIN medidores.Usuarios u ON u.Id=e.IdUsuarioApp
WHERE e.IdOrigen LIKE 'QA-%'
ORDER BY e.IdEjecucion DESC;

SELECT v.IdVerificacion, v.TipoOrigen, v.IdOrigen,
       u.NombreUsuario AS Mecanico, v.FechaVerificacion,
       v.Estado, v.Resultado, e.Error, e.Caudal, e.Fugas
FROM medidores.Verificaciones v
INNER JOIN medidores.Usuarios u ON u.Id=v.IdUsuarioMecanico
LEFT JOIN medidores.EnsayoVerificacion e ON e.IdVerificacion=v.IdVerificacion
WHERE v.IdOrigen LIKE 'QA-%'
ORDER BY v.IdVerificacion DESC;
GO
