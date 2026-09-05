/* =============================================================
   COSAALT - QA TEMPORAL: USUARIOS Y PARAMETROS PARA TODA LA APP

   Ejecutar DESPUES de 01, 02 y 06, y ANTES de 07.
   SOLO modifica medidores.* en la base cosaalt.
   NO modifica dbo.* y NO accede a la base cosaaltunoprueba.

   Las contrasenas se guardan temporalmente en formato compatible con
   versiones anteriores. En el primer login la API las migra a PBKDF2.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

IF OBJECT_ID('medidores.RolApp','U') IS NULL
   OR OBJECT_ID('medidores.Usuarios','U') IS NULL
   OR OBJECT_ID('medidores.ParametrosNormativos','U') IS NULL
    THROW 51001, 'Primero ejecute 01_CREAR_ESQUEMA_MEDIDORES_COSAALT.sql y 02_AJUSTES_COMPATIBILIDAD_COSAALT.sql.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @Cuentas TABLE
(
    NombreUsuario VARCHAR(50) NOT NULL,
    Contrasena VARCHAR(80) NOT NULL,
    Rol VARCHAR(50) NOT NULL
);

INSERT INTO @Cuentas VALUES
('qa_admin_20260905',      'Qa2026!Admin',      'administrador'),
('qa_asignador_20260905',  'Qa2026!Asignador',  'asignador'),
('qa_tecnico_20260905',    'Qa2026!Tecnico',    'tecnico'),
('qa_mecanico_20260905',   'Qa2026!Mecanico',   'mecanico');

IF EXISTS
(
    SELECT 1
    FROM @Cuentas c
    LEFT JOIN medidores.RolApp r ON LOWER(RTRIM(r.Nombre)) = c.Rol AND r.Activo = 1
    WHERE r.IdRol IS NULL
)
    THROW 51002, 'Falta uno o mas roles activos de la aplicacion.', 1;

UPDATE u
SET u.HashPassword = c.Contrasena,
    u.IdRol = r.IdRol,
    u.Activo = 1,
    u.CodPersonaCorporativa = NULL,
    u.FechaActualizacion = SYSDATETIME()
FROM medidores.Usuarios u
INNER JOIN @Cuentas c ON c.NombreUsuario = u.NombreUsuario
INNER JOIN medidores.RolApp r ON LOWER(RTRIM(r.Nombre)) = c.Rol;

INSERT INTO medidores.Usuarios
    (CodPersonaCorporativa, NombreUsuario, HashPassword, IdRol, Activo)
SELECT NULL, c.NombreUsuario, c.Contrasena, r.IdRol, 1
FROM @Cuentas c
INNER JOIN medidores.RolApp r ON LOWER(RTRIM(r.Nombre)) = c.Rol
WHERE NOT EXISTS
(
    SELECT 1 FROM medidores.Usuarios u WHERE u.NombreUsuario = c.NombreUsuario
);

DELETE FROM medidores.ParametrosNormativos WHERE Codigo LIKE 'QA-%';

INSERT INTO medidores.ParametrosNormativos
    (Codigo, Descripcion, ErrorMaxPermitido, CaudalMin, CaudalMax,
     VigenciaInicio, VigenciaFin, Activo)
VALUES
('QA-CAUDAL-BAJO', 'TEMPORAL QA. Limites ilustrativos; no usar como norma oficial.', 5.0000, 0.0000, 14.9999, DATEADD(DAY,-1,SYSDATETIME()), NULL, 1),
('QA-CAUDAL-MEDIO','TEMPORAL QA. Limites ilustrativos; no usar como norma oficial.', 3.0000, 15.0000, 30.0000, DATEADD(DAY,-1,SYSDATETIME()), NULL, 1),
('QA-CAUDAL-ALTO', 'TEMPORAL QA. Limites ilustrativos; no usar como norma oficial.', 2.0000, 30.0001, 1000.0000, DATEADD(DAY,-1,SYSDATETIME()), NULL, 1);

COMMIT TRANSACTION;
GO

SELECT u.Id, u.NombreUsuario, r.Nombre AS Rol, u.Activo
FROM medidores.Usuarios u
INNER JOIN medidores.RolApp r ON r.IdRol = u.IdRol
WHERE u.NombreUsuario LIKE 'qa[_]%'
ORDER BY r.Nombre, u.NombreUsuario;

SELECT Codigo, ErrorMaxPermitido, CaudalMin, CaudalMax, Activo
FROM medidores.ParametrosNormativos
WHERE Codigo LIKE 'QA-%'
ORDER BY CaudalMin;
GO
