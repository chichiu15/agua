/* =============================================================
   COSAALT - QA TEMPORAL: LIMPIEZA TOTAL Y REVERSIBLE

   Ejecutar al terminar cada ciclo completo de pruebas.
   SOLO elimina filas QA de medidores.* en la base cosaalt.
   NO modifica dbo.* y NO accede a cosaaltunoprueba.
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

DECLARE @ParametrosQa TABLE (IdParametro INT PRIMARY KEY);
INSERT INTO @ParametrosQa(IdParametro)
SELECT IdParametro FROM medidores.ParametrosNormativos WHERE Codigo LIKE 'QA-%';

DECLARE @VerificacionesQa TABLE (IdVerificacion INT PRIMARY KEY);
INSERT INTO @VerificacionesQa(IdVerificacion)
SELECT IdVerificacion
FROM medidores.Verificaciones
WHERE IdOrigen LIKE 'QA-%'
   OR IdUsuarioMecanico IN (SELECT Id FROM @UsuariosQa)
   OR IdParametroNormativoAplicado IN (SELECT IdParametro FROM @ParametrosQa);

DELETE FROM medidores.ParticipantesVerificacion
WHERE IdVerificacion IN (SELECT IdVerificacion FROM @VerificacionesQa);
DELETE FROM medidores.EnsayoVerificacion
WHERE IdVerificacion IN (SELECT IdVerificacion FROM @VerificacionesQa);
DELETE FROM medidores.InformesVerificacion
WHERE IdVerificacion IN (SELECT IdVerificacion FROM @VerificacionesQa);
DELETE FROM medidores.Verificaciones
WHERE IdVerificacion IN (SELECT IdVerificacion FROM @VerificacionesQa);

DECLARE @EjecucionesQa TABLE (IdEjecucion INT PRIMARY KEY);
INSERT INTO @EjecucionesQa(IdEjecucion)
SELECT IdEjecucion FROM medidores.EjecucionCambio
WHERE IdOrigen LIKE 'QA-%'
   OR IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR ObservacionesInstalacion LIKE 'QA-%';

DELETE FROM medidores.EvidenciaFotografica
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);
DELETE FROM medidores.EjecucionCambio
WHERE IdEjecucion IN (SELECT IdEjecucion FROM @EjecucionesQa);

DECLARE @RutasQa TABLE (IdAsignacion INT PRIMARY KEY);
INSERT INTO @RutasQa(IdAsignacion)
SELECT DISTINCT a.IdAsignacion
FROM medidores.AsignacionRuta a
LEFT JOIN medidores.DetalleRuta d ON d.IdAsignacion=a.IdAsignacion
WHERE a.IdUsuarioApp IN (SELECT Id FROM @UsuariosQa)
   OR a.IdUsuarioAsignador IN (SELECT Id FROM @UsuariosQa)
   OR d.SolicitudId LIKE 'QA-%'
   OR d.IdOrigen LIKE 'QA-%';

DELETE FROM medidores.DetalleRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);
DELETE FROM medidores.AsignacionRuta
WHERE IdAsignacion IN (SELECT IdAsignacion FROM @RutasQa);

DELETE FROM medidores.ParametrosNormativos WHERE IdParametro IN (SELECT IdParametro FROM @ParametrosQa);
IF OBJECT_ID('medidores.MotivosCambio','U') IS NOT NULL
    DELETE FROM medidores.MotivosCambio WHERE Nombre LIKE 'QA-E2E - %';
IF OBJECT_ID('medidores.MarcasMedidor','U') IS NOT NULL
    DELETE FROM medidores.MarcasMedidor
    WHERE Codigo LIKE 'QA%' OR Nombre LIKE 'QA-E2E - %' OR Alias LIKE 'QA-E2E - %';

DELETE FROM medidores.Usuarios WHERE Id IN (SELECT Id FROM @UsuariosQa);

IF OBJECT_ID('medidores.SolicitudPruebaE2E','U') IS NOT NULL
    DROP TABLE medidores.SolicitudPruebaE2E;

COMMIT TRANSACTION;
GO

SELECT 'Usuarios QA restantes' AS Verificacion, COUNT_BIG(*) AS Cantidad
FROM medidores.Usuarios WHERE NombreUsuario LIKE 'qa[_]%'
UNION ALL
SELECT 'Parametros QA restantes', COUNT_BIG(*) FROM medidores.ParametrosNormativos WHERE Codigo LIKE 'QA-%'
UNION ALL
SELECT 'Motivos QA restantes', COUNT_BIG(*) FROM medidores.MotivosCambio WHERE Nombre LIKE 'QA-E2E - %'
UNION ALL
SELECT 'Cambios QA restantes', COUNT_BIG(*) FROM medidores.EjecucionCambio WHERE IdOrigen LIKE 'QA-%'
UNION ALL
SELECT 'Verificaciones QA restantes', COUNT_BIG(*) FROM medidores.Verificaciones WHERE IdOrigen LIKE 'QA-%';
GO
