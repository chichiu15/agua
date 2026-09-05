/* =============================================================
   COSAALT - DIAGNOSTICO E2E (SOLO SELECT)
   No modifica ninguna tabla.
   ============================================================= */
USE cosaalt;
GO

-- A) Ultimas rutas creadas y sus detalles
SELECT TOP (30)
    a.IdAsignacion,
    a.IdUsuarioApp,
    ut.NombreUsuario AS Tecnico,
    a.IdUsuarioAsignador,
    ua.NombreUsuario AS Asignador,
    a.FechaAsignacion,
    a.Estado,
    a.FechaCreacion,
    COUNT(d.IdDetalle) AS TotalParadas,
    SUM(CASE WHEN d.Estado = 'Completada' THEN 1 ELSE 0 END) AS Completadas,
    SUM(CASE WHEN d.Estado NOT IN ('Completada','Cancelada') THEN 1 ELSE 0 END) AS Pendientes
FROM medidores.AsignacionRuta a
LEFT JOIN medidores.DetalleRuta d ON d.IdAsignacion = a.IdAsignacion
LEFT JOIN medidores.Usuarios ut ON ut.Id = a.IdUsuarioApp
LEFT JOIN medidores.Usuarios ua ON ua.Id = a.IdUsuarioAsignador
GROUP BY a.IdAsignacion, a.IdUsuarioApp, ut.NombreUsuario,
         a.IdUsuarioAsignador, ua.NombreUsuario,
         a.FechaAsignacion, a.Estado, a.FechaCreacion
ORDER BY a.IdAsignacion DESC;

-- B) Detalles de las ultimas rutas
SELECT TOP (200)
    d.IdDetalle, d.IdAsignacion, d.OrdenVisita, d.SolicitudId,
    d.TipoOrigen, d.IdOrigen, d.RegSoc, d.CodMedidorActual,
    d.Estado, d.NombreCliente, d.Direccion,
    d.Latitud, d.Longitud, d.FechaInicio, d.FechaFinalizacion
FROM medidores.DetalleRuta d
ORDER BY d.IdAsignacion DESC, d.OrdenVisita;

-- C) Estructura real de dbo.Lec_Obl (si existe)
IF OBJECT_ID('dbo.Lec_Obl','U') IS NOT NULL
BEGIN
    SELECT c.column_id AS Orden, c.name AS Columna,
           TYPE_NAME(c.user_type_id) AS Tipo,
           c.max_length, c.precision, c.scale, c.is_nullable
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('dbo.Lec_Obl')
    ORDER BY c.column_id;
END
ELSE
BEGIN
    SELECT 'dbo.Lec_Obl no existe en esta base.' AS Diagnostico;
END;

-- D) Confirmar observaciones institucionales 2, 4 y 11
IF OBJECT_ID('dbo.Obs_Lec','U') IS NOT NULL
BEGIN
    SELECT Cod_Obl, Des_Obl, Obs_Obl, Uni_Obl, Foto_Obl
    FROM dbo.Obs_Lec
    WHERE Cod_Obl IN (2,4,11)
    ORDER BY Cod_Obl;
END;
GO
