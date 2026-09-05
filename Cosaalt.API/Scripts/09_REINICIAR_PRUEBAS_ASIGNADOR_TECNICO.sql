/* =============================================================
   COSAALT - REINICIO CONTROLADO DE PRUEBAS ASIGNADOR / TECNICO

   Borra únicamente resultados y rutas relacionados con solicitudes QA.
   Conserva usuarios QA, roles, catálogos y todas las tablas dbo.*.

   Después de este script ejecute:
   07_CARGAR_BATERIA_E2E_SOLICITUDES.sql
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @EjecucionesQa TABLE (IdEjecucion INT PRIMARY KEY);
INSERT INTO @EjecucionesQa(IdEjecucion)
SELECT e.IdEjecucion
FROM medidores.EjecucionCambio e
WHERE e.IdOrigen LIKE 'QA-%'
   OR e.ObservacionesInstalacion LIKE 'QA-%';

DELETE FROM medidores.EvidenciaFotografica
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);

DELETE FROM medidores.EjecucionCambio
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);

DECLARE @RutasQa TABLE (IdAsignacion INT PRIMARY KEY);
INSERT INTO @RutasQa(IdAsignacion)
SELECT DISTINCT d.IdAsignacion
FROM medidores.DetalleRuta d
WHERE d.SolicitudId LIKE 'QA-%'
   OR d.IdOrigen LIKE 'QA-%';

DELETE FROM medidores.DetalleRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);

DELETE FROM medidores.AsignacionRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);

IF OBJECT_ID('medidores.SolicitudPruebaE2E','U') IS NOT NULL
    UPDATE medidores.SolicitudPruebaE2E SET Estado = 'Pendiente';

COMMIT TRANSACTION;
GO

SELECT 'Rutas QA restantes' AS Verificacion, COUNT(*) AS Cantidad
FROM medidores.DetalleRuta
WHERE SolicitudId LIKE 'QA-%' OR IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Ejecuciones QA restantes', COUNT(*)
FROM medidores.EjecucionCambio
WHERE IdOrigen LIKE 'QA-%';
GO
