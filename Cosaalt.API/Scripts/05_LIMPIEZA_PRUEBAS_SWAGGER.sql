/* =============================================================
   COSAALT - LIMPIEZA TOTAL QA / E2E
   SOLO TOCA medidores.*. NO TOCA dbo.*.

   Elimina:
   - rutas/cambios/evidencias QA
   - usuarios QA
   - parametros QA
   - motivos QA-E2E
   - tabla temporal SolicitudPruebaE2E completa

   Conserva los catalogos permanentes medidores.MotivosCambio y
   medidores.MarcasMedidor, excepto filas cuyo nombre sea QA-E2E.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @UsuariosQa TABLE (Id INT PRIMARY KEY);
INSERT INTO @UsuariosQa(Id)
SELECT Id FROM medidores.Usuarios WHERE NombreUsuario LIKE 'qa[_]%';

DECLARE @RutasQa TABLE (IdAsignacion INT PRIMARY KEY);
INSERT INTO @RutasQa(IdAsignacion)
SELECT DISTINCT a.IdAsignacion
FROM medidores.AsignacionRuta a
LEFT JOIN medidores.DetalleRuta d ON d.IdAsignacion = a.IdAsignacion
WHERE a.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR a.IdUsuarioAsignador IN (SELECT Id FROM @UsuariosQa)
   OR d.SolicitudId LIKE 'QA-%'
   OR d.IdOrigen LIKE 'QA-%';

DECLARE @EjecucionesQa TABLE (IdEjecucion INT PRIMARY KEY);
INSERT INTO @EjecucionesQa(IdEjecucion)
SELECT e.IdEjecucion
FROM medidores.EjecucionCambio e
WHERE e.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR e.IdOrigen LIKE 'QA-%'
   OR e.ObservacionesInstalacion LIKE 'QA-%';

DELETE FROM medidores.EvidenciaFotografica
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);

DELETE FROM medidores.EjecucionCambio
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);

DELETE pv
FROM medidores.ParticipantesVerificacion pv
INNER JOIN medidores.Verificaciones v ON v.IdVerificacion = pv.IdVerificacion
WHERE v.IdUsuarioMecanico IN (SELECT Id FROM @UsuariosQa);

DELETE ev
FROM medidores.EnsayoVerificacion ev
INNER JOIN medidores.Verificaciones v ON v.IdVerificacion = ev.IdVerificacion
WHERE v.IdUsuarioMecanico IN (SELECT Id FROM @UsuariosQa);

DELETE iv
FROM medidores.InformesVerificacion iv
INNER JOIN medidores.Verificaciones v ON v.IdVerificacion = iv.IdVerificacion
WHERE v.IdUsuarioMecanico IN (SELECT Id FROM @UsuariosQa);

DELETE FROM medidores.Verificaciones
WHERE IdUsuarioMecanico IN (SELECT Id FROM @UsuariosQa);

DELETE FROM medidores.DetalleRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);

DELETE FROM medidores.AsignacionRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);

DELETE FROM medidores.ParametrosNormativos
WHERE Codigo LIKE 'QA-%';

IF OBJECT_ID('medidores.MotivosCambio','U') IS NOT NULL
    DELETE FROM medidores.MotivosCambio WHERE Nombre LIKE 'QA-E2E - %';

IF OBJECT_ID('medidores.MarcasMedidor','U') IS NOT NULL
    DELETE FROM medidores.MarcasMedidor
    WHERE Codigo LIKE 'QA%' OR Nombre LIKE 'QA-E2E - %' OR Alias LIKE 'QA-E2E - %';

DELETE FROM medidores.Usuarios
WHERE Id IN (SELECT Id FROM @UsuariosQa);

IF OBJECT_ID('medidores.SolicitudPruebaE2E','U') IS NOT NULL
    DROP TABLE medidores.SolicitudPruebaE2E;

COMMIT TRANSACTION;
GO

SELECT 'Usuarios QA restantes' AS Verificacion, COUNT(*) AS Cantidad
FROM medidores.Usuarios WHERE NombreUsuario LIKE 'qa[_]%'
UNION ALL
SELECT 'Parametros QA restantes', COUNT(*)
FROM medidores.ParametrosNormativos WHERE Codigo LIKE 'QA-%'
UNION ALL
SELECT 'Motivos QA restantes', COUNT(*)
FROM medidores.MotivosCambio WHERE Nombre LIKE 'QA-E2E - %'
UNION ALL
SELECT 'Ejecuciones con origen QA restantes', COUNT(*)
FROM medidores.EjecucionCambio WHERE IdOrigen LIKE 'QA-%';
GO
