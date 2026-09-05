/* =============================================================
   COSAALT - BATERIA TEMPORAL E2E PARA ASIGNADOR / TECNICO
   Crea 20 solicitudes QA dentro de medidores.* usando SOCIOS/MEDIDORES
   reales SOLO COMO REFERENCIA DE LECTURA. NO INSERTA/UPDATE/DELETE dbo.*.

   Coordenadas: radio de Plaza Los Laureles indicado para las pruebas.
   El script 05 elimina toda esta bateria al finalizar.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

IF OBJECT_ID('medidores.MotivosCambio', 'U') IS NULL
    THROW 51001, 'Primero ejecute 06_ACTUALIZAR_CATALOGOS_APP.sql.', 1;
GO

IF OBJECT_ID('medidores.SolicitudPruebaE2E', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.SolicitudPruebaE2E
    (
        SolicitudId       VARCHAR(60) NOT NULL,
        OrdenPrueba       INT NOT NULL,
        TipoOrigen        VARCHAR(20) NOT NULL,
        Estado            VARCHAR(20) NOT NULL CONSTRAINT DF_SolicitudPruebaE2E_Estado DEFAULT ('Pendiente'),
        EsUrgente         BIT NOT NULL CONSTRAINT DF_SolicitudPruebaE2E_Urgente DEFAULT (0),
        RegSoc            NUMERIC(6,0) NOT NULL,
        NombreCliente     VARCHAR(200) NOT NULL,
        Direccion         VARCHAR(300) NOT NULL,
        Categoria         VARCHAR(50) NULL,
        NumeroMedidor     VARCHAR(30) NULL,
        MarcaMedidor      VARCHAR(50) NULL,
        MotivoObservacion VARCHAR(250) NULL,
        FechaSolicitud    DATETIME2(0) NOT NULL,
        Latitud           DECIMAL(18,12) NOT NULL,
        Longitud          DECIMAL(18,12) NOT NULL,
        CONSTRAINT PK_SolicitudPruebaE2E PRIMARY KEY (SolicitudId),
        CONSTRAINT CK_SolicitudPruebaE2E_Origen CHECK (TipoOrigen IN ('ODECO','LECTURA'))
    );
END;
GO

DELETE FROM medidores.SolicitudPruebaE2E;
GO

/* Motivos QA temporales para completar el formulario del tecnico. */
DECLARE @Motivos TABLE (Nombre VARCHAR(80), Descripcion VARCHAR(250));
INSERT INTO @Motivos VALUES
('QA-E2E - Medidor parado', 'Temporal para pruebas E2E. Eliminar con script 05.'),
('QA-E2E - Medidor destrozado', 'Temporal para pruebas E2E. Eliminar con script 05.'),
('QA-E2E - Consumo bajo', 'Temporal para pruebas E2E. Eliminar con script 05.'),
('QA-E2E - Cambio preventivo', 'Temporal para pruebas E2E. Eliminar con script 05.');

INSERT INTO medidores.MotivosCambio (Nombre, Descripcion, Activo)
SELECT m.Nombre, m.Descripcion, 1
FROM @Motivos m
WHERE NOT EXISTS (SELECT 1 FROM medidores.MotivosCambio x WHERE x.Nombre = m.Nombre);
GO

;WITH Puntos AS
(
    SELECT * FROM (VALUES
      (1,  CAST(-21.504100000000 AS DECIMAL(18,12)), CAST(-64.717631000000 AS DECIMAL(18,12))),
      (2,  CAST(-21.504160000000 AS DECIMAL(18,12)), CAST(-64.717151000000 AS DECIMAL(18,12))),
      (3,  CAST(-21.504401000000 AS DECIMAL(18,12)), CAST(-64.716689000000 AS DECIMAL(18,12))),
      (4,  CAST(-21.505031000000 AS DECIMAL(18,12)), CAST(-64.716740000000 AS DECIMAL(18,12))),
      (5,  CAST(-21.505297000000 AS DECIMAL(18,12)), CAST(-64.719021000000 AS DECIMAL(18,12))),
      (6,  CAST(-21.503269611199 AS DECIMAL(18,12)), CAST(-64.719768266171 AS DECIMAL(18,12))),
      (7,  CAST(-21.503650000000 AS DECIMAL(18,12)), CAST(-64.718950000000 AS DECIMAL(18,12))),
      (8,  CAST(-21.503890000000 AS DECIMAL(18,12)), CAST(-64.718410000000 AS DECIMAL(18,12))),
      (9,  CAST(-21.504330000000 AS DECIMAL(18,12)), CAST(-64.718260000000 AS DECIMAL(18,12))),
      (10, CAST(-21.504780000000 AS DECIMAL(18,12)), CAST(-64.718030000000 AS DECIMAL(18,12))),
      (11, CAST(-21.505120000000 AS DECIMAL(18,12)), CAST(-64.718350000000 AS DECIMAL(18,12))),
      (12, CAST(-21.505450000000 AS DECIMAL(18,12)), CAST(-64.718620000000 AS DECIMAL(18,12))),
      (13, CAST(-21.505000000000 AS DECIMAL(18,12)), CAST(-64.719400000000 AS DECIMAL(18,12))),
      (14, CAST(-21.504520000000 AS DECIMAL(18,12)), CAST(-64.719620000000 AS DECIMAL(18,12))),
      (15, CAST(-21.504000000000 AS DECIMAL(18,12)), CAST(-64.719350000000 AS DECIMAL(18,12))),
      (16, CAST(-21.503550000000 AS DECIMAL(18,12)), CAST(-64.719180000000 AS DECIMAL(18,12))),
      (17, CAST(-21.503310000000 AS DECIMAL(18,12)), CAST(-64.718520000000 AS DECIMAL(18,12))),
      (18, CAST(-21.503480000000 AS DECIMAL(18,12)), CAST(-64.717760000000 AS DECIMAL(18,12))),
      (19, CAST(-21.504020000000 AS DECIMAL(18,12)), CAST(-64.716980000000 AS DECIMAL(18,12))),
      (20, CAST(-21.504690000000 AS DECIMAL(18,12)), CAST(-64.717260000000 AS DECIMAL(18,12)))
    ) v(OrdenPrueba, Latitud, Longitud)
),
BaseCandidatos AS
(
    SELECT
        TRY_CONVERT(INT, m.reg_soc) AS RegSoc,
        COALESCE(NULLIF(LTRIM(RTRIM(s.Nom_Soc)), ''), CONCAT('Socio ', m.reg_soc)) AS NombreCliente,
        RTRIM(m.Ser_Med) AS Serie,
        RTRIM(m.Mar_Med) AS Marca,
        TRY_CONVERT(INT, m.Cod_Med) AS CodMedidor,
        ROW_NUMBER() OVER (PARTITION BY m.reg_soc ORDER BY m.Fis_Med DESC, m.Cod_Med DESC) AS rnSocio
    FROM dbo.Medidor m
    INNER JOIN dbo.SOCIO s ON s.Reg_Soc = m.reg_soc
    WHERE m.reg_soc > 0
      AND RTRIM(ISNULL(m.dis_med,'')) = 'O'
      AND m.Ser_Med IS NOT NULL
),
Candidatos AS
(
    SELECT TOP (20)
        ROW_NUMBER() OVER (ORDER BY CodMedidor DESC) AS rn,
        RegSoc, NombreCliente, Serie, Marca
    FROM BaseCandidatos
    WHERE rnSocio = 1
    ORDER BY CodMedidor DESC
)
INSERT INTO medidores.SolicitudPruebaE2E
(
    SolicitudId, OrdenPrueba, TipoOrigen, Estado, EsUrgente, RegSoc,
    NombreCliente, Direccion, Categoria, NumeroMedidor, MarcaMedidor,
    MotivoObservacion, FechaSolicitud, Latitud, Longitud
)
SELECT
    CASE WHEN p.OrdenPrueba <= 10
         THEN CONCAT('QA-ODECO-', RIGHT('00' + CAST(p.OrdenPrueba AS VARCHAR(2)), 2))
         ELSE CONCAT('QA-LECTURA-', RIGHT('00' + CAST(p.OrdenPrueba - 10 AS VARCHAR(2)), 2)) END,
    p.OrdenPrueba,
    CASE WHEN p.OrdenPrueba <= 10 THEN 'ODECO' ELSE 'LECTURA' END,
    'Pendiente',
    CASE WHEN p.OrdenPrueba IN (2,5,9,12,16,20) THEN 1 ELSE 0 END,
    c.RegSoc,
    c.NombreCliente,
    CONCAT('QA E2E - Plaza Los Laureles - Punto ', p.OrdenPrueba),
    CASE WHEN p.OrdenPrueba IN (2,5,9,12,16,20) THEN 'URGENTE' ELSE 'NORMAL' END,
    c.Serie,
    c.Marca,
    CASE
      WHEN p.OrdenPrueba <= 10 THEN CONCAT('QA E2E ODECO - observacion manual de inspector #', p.OrdenPrueba)
      WHEN p.OrdenPrueba % 3 = 1 THEN 'QA E2E LECTURA - Obs 2: MEDIDOR PARADO'
      WHEN p.OrdenPrueba % 3 = 2 THEN 'QA E2E LECTURA - Obs 4: MEDIDOR DESTROZADO'
      ELSE 'QA E2E LECTURA - Obs 11: CONSUMO BAJO'
    END,
    DATEADD(DAY, -p.OrdenPrueba, SYSDATETIME()),
    p.Latitud,
    p.Longitud
FROM Puntos p
INNER JOIN Candidatos c ON c.rn = p.OrdenPrueba;
GO

SELECT SolicitudId, TipoOrigen, RegSoc, NombreCliente, NumeroMedidor, MarcaMedidor,
       MotivoObservacion, Latitud, Longitud
FROM medidores.SolicitudPruebaE2E
ORDER BY OrdenPrueba;

SELECT IdMotivo, Nombre, Activo
FROM medidores.MotivosCambio
WHERE Nombre LIKE 'QA-E2E - %'
ORDER BY IdMotivo;
GO
