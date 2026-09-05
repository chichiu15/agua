/* =============================================================
   COSAALT - SMOKE TEST DE INTEGRACION DEL BACKEND
   SOLO LECTURA. NO INSERTA, NO ACTUALIZA Y NO ELIMINA DATOS.
   Ejecutar en la base cosaalt antes de probar Swagger.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

PRINT '1) Base y objetos propios';
SELECT DB_NAME() AS BaseActual, @@SERVERNAME AS Servidor;

SELECT s.name AS Esquema, t.name AS Tabla, SUM(p.rows) AS FilasAproximadas
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE s.name = 'medidores'
GROUP BY s.name, t.name
ORDER BY t.name;
GO

PRINT '2) Roles de la aplicacion';
SELECT IdRol, Nombre, Descripcion, Activo
FROM medidores.RolApp
ORDER BY IdRol;
GO

PRINT '3) Fuentes institucionales obligatorias';
SELECT
    OBJECT_ID('dbo.PERSONAS','U') AS PERSONAS,
    OBJECT_ID('dbo.SOCIO','U') AS SOCIO,
    OBJECT_ID('dbo.Medidor','U') AS Medidor,
    OBJECT_ID('dbo.Estado_medidor','U') AS Estado_medidor,
    OBJECT_ID('dbo.Lectura','U') AS Lectura,
    OBJECT_ID('dbo.RECLAMOS','U') AS RECLAMOS,
    OBJECT_ID('dbo.TIPOSRECLAMOS','U') AS TIPOSRECLAMOS,
    OBJECT_ID('dbo.TIPOSPRIORIDADES','U') AS TIPOSPRIORIDADES,
    OBJECT_ID('dbo.hist_pred_med','U') AS hist_pred_med;
GO

PRINT '4) Personas institucionales para vincular usuarios';
SELECT TOP (10)
    CodPer,
    LTRIM(RTRIM(CONCAT(NomPer, ' ', PriApePer, ' ', SegApePer))) AS NombreCompleto
FROM dbo.PERSONAS
ORDER BY CodPer;
GO

PRINT '5) Medidores candidatos con la regla PROVISIONAL que se esta validando con COSAALT';
SELECT TOP (20)
    m.Cod_Med,
    RTRIM(m.Ser_Med) AS Serie,
    RTRIM(m.Mar_Med) AS Marca,
    m.cod_est,
    RTRIM(em.nom_est) AS Estado,
    RTRIM(m.dis_med) AS Disponibilidad,
    m.reg_soc
FROM dbo.Medidor m
LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
WHERE m.cod_est = 5
  AND RTRIM(m.dis_med) = 'L'
  AND m.reg_soc = 0
ORDER BY m.Cod_Med DESC;
GO

PRINT '6) Reclamos ODECO disponibles para validacion funcional';
SELECT TOP (20)
    r.CodRec,
    r.FecHorRec,
    r.Reg_Soc,
    r.CodTipRec,
    RTRIM(tr.NomTipRec) AS TipoReclamo,
    r.CodTipPri,
    RTRIM(tp.NomTipPri) AS Prioridad,
    RTRIM(r.ObsRec) AS Observacion
FROM dbo.RECLAMOS r
LEFT JOIN dbo.TIPOSRECLAMOS tr ON tr.CodTipRec = r.CodTipRec
LEFT JOIN dbo.TIPOSPRIORIDADES tp ON tp.CodTipPri = r.CodTipPri
WHERE r.Reg_Soc IS NOT NULL
ORDER BY r.CodRec DESC;
GO

PRINT '7) Medidor actualmente asociado a algunos socios de reclamos';
SELECT TOP (20)
    r.CodRec,
    r.Reg_Soc,
    m.Cod_Med,
    RTRIM(m.Ser_Med) AS Serie,
    RTRIM(m.Mar_Med) AS Marca,
    m.Fis_Med,
    RTRIM(m.dis_med) AS Disponibilidad,
    m.cod_est
FROM dbo.RECLAMOS r
OUTER APPLY
(
    SELECT TOP (1) m0.*
    FROM dbo.Medidor m0
    WHERE m0.reg_soc = r.Reg_Soc
    ORDER BY m0.Fis_Med DESC, m0.Cod_Med DESC
) m
WHERE r.Reg_Soc IS NOT NULL
ORDER BY r.CodRec DESC;
GO

PRINT '8) Catalogo de motivos: informar si existe o queda pendiente de definicion';
SELECT CASE WHEN OBJECT_ID('dbo.MotivosCambioMedidor','U') IS NULL
            THEN 'PENDIENTE: dbo.MotivosCambioMedidor no existe en cosaalt'
            ELSE 'OK: dbo.MotivosCambioMedidor existe en cosaalt'
       END AS EstadoCatalogoMotivos;
GO

IF OBJECT_ID('dbo.MotivosCambioMedidor','U') IS NOT NULL
BEGIN
    SELECT TOP (50) * FROM dbo.MotivosCambioMedidor;
END;
GO

PRINT '9) Integridad basica del esquema propio';
SELECT 'Usuarios' AS Tabla, COUNT_BIG(*) AS Cantidad FROM medidores.Usuarios
UNION ALL SELECT 'AsignacionRuta', COUNT_BIG(*) FROM medidores.AsignacionRuta
UNION ALL SELECT 'DetalleRuta', COUNT_BIG(*) FROM medidores.DetalleRuta
UNION ALL SELECT 'EjecucionCambio', COUNT_BIG(*) FROM medidores.EjecucionCambio
UNION ALL SELECT 'EvidenciaFotografica', COUNT_BIG(*) FROM medidores.EvidenciaFotografica
UNION ALL SELECT 'ParametrosNormativos', COUNT_BIG(*) FROM medidores.ParametrosNormativos
UNION ALL SELECT 'Verificaciones', COUNT_BIG(*) FROM medidores.Verificaciones
UNION ALL SELECT 'EnsayoVerificacion', COUNT_BIG(*) FROM medidores.EnsayoVerificacion
UNION ALL SELECT 'ParticipantesVerificacion', COUNT_BIG(*) FROM medidores.ParticipantesVerificacion
UNION ALL SELECT 'InformesVerificacion', COUNT_BIG(*) FROM medidores.InformesVerificacion;
GO

PRINT '10) Duplicados que deben quedar en cero';
SELECT TipoOrigen, IdOrigen, COUNT_BIG(*) AS Cantidad
FROM medidores.EjecucionCambio
GROUP BY TipoOrigen, IdOrigen
HAVING COUNT_BIG(*) > 1;

SELECT CodMedidorInstalado, COUNT_BIG(*) AS Cantidad
FROM medidores.EjecucionCambio
WHERE CodMedidorInstalado IS NOT NULL
GROUP BY CodMedidorInstalado
HAVING COUNT_BIG(*) > 1;
GO
