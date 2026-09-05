/* =============================================================
   COSAALT - CATALOGOS PROPIOS DEL MODULO MEDIDORES
   PERMANENTE. NO ES DATA QA.

   MotivosCambio: COSAALT no tiene dbo.MotivosCambioMedidor en la base
   seleccionada, por lo que el modulo administra su catalogo propio.

   MarcasMedidor: dbo.Medidor guarda solo el codigo Mar_Med (varchar(3)).
   Esta tabla agrega nombre/alias/estado SIN modificar dbo.Medidor.
   ============================================================= */
USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

IF SCHEMA_ID('medidores') IS NULL
    EXEC('CREATE SCHEMA medidores');
GO

IF OBJECT_ID('medidores.MotivosCambio', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.MotivosCambio
    (
        IdMotivo          INT IDENTITY(1,1) NOT NULL,
        Nombre            VARCHAR(80) NOT NULL,
        Descripcion       VARCHAR(250) NULL,
        Activo            BIT NOT NULL CONSTRAINT DF_MotivosCambio_Activo DEFAULT (1),
        FechaCreacion     DATETIME2(0) NOT NULL CONSTRAINT DF_MotivosCambio_FechaCreacion DEFAULT (SYSDATETIME()),
        FechaActualizacion DATETIME2(0) NULL,
        CONSTRAINT PK_MotivosCambio PRIMARY KEY (IdMotivo),
        CONSTRAINT UQ_MotivosCambio_Nombre UNIQUE (Nombre)
    );
END;
GO

IF OBJECT_ID('medidores.MarcasMedidor', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.MarcasMedidor
    (
        IdMarca           INT IDENTITY(1,1) NOT NULL,
        Codigo            VARCHAR(3) NOT NULL,
        Nombre            VARCHAR(80) NOT NULL,
        Alias             VARCHAR(80) NULL,
        Activo            BIT NOT NULL CONSTRAINT DF_MarcasMedidor_Activo DEFAULT (1),
        FechaCreacion     DATETIME2(0) NOT NULL CONSTRAINT DF_MarcasMedidor_FechaCreacion DEFAULT (SYSDATETIME()),
        FechaActualizacion DATETIME2(0) NULL,
        CONSTRAINT PK_MarcasMedidor PRIMARY KEY (IdMarca),
        CONSTRAINT UQ_MarcasMedidor_Codigo UNIQUE (Codigo)
    );
END;
GO

/* Incorpora todos los codigos de marca que ya existen institucionalmente. */
INSERT INTO medidores.MarcasMedidor (Codigo, Nombre, Alias, Activo)
SELECT x.Codigo, x.Codigo, NULL, 1
FROM (
    SELECT DISTINCT UPPER(RTRIM(Mar_Med)) AS Codigo
    FROM dbo.Medidor
    WHERE Mar_Med IS NOT NULL
      AND RTRIM(Mar_Med) <> ''
) x
WHERE NOT EXISTS (
    SELECT 1
    FROM medidores.MarcasMedidor m
    WHERE UPPER(RTRIM(m.Codigo)) = x.Codigo
);
GO

SELECT * FROM medidores.MotivosCambio ORDER BY IdMotivo;
SELECT * FROM medidores.MarcasMedidor ORDER BY Codigo;
GO
