/*
  COSAALT R.L. - Sistema de Gestion, Cambio y Verificacion de Medidores
  Script base definitivo del esquema propio de la aplicacion.

  DESTINO: base de datos cosaalt
  OBJETIVO: crear solamente objetos del esquema medidores.

  IMPORTANTE:
  - Este script NO elimina ni modifica tablas dbo.
  - No crea SolicitudLectura ni DetalleSolicitudLectura: el origen se resuelve desde dbo.
  - No crea FKs fisicas hacia dbo mientras COSAALT no confirme el mecanismo institucional final.
  - Es seguro volver a ejecutarlo: crea objetos solo si no existen.
*/

USE cosaalt;
GO

IF DB_NAME() <> 'cosaalt'
    THROW 51000, 'Este script debe ejecutarse exclusivamente sobre la base cosaalt.', 1;
GO

/* ============================================================
   1. ESQUEMA
   ============================================================ */
IF SCHEMA_ID('medidores') IS NULL
    EXEC('CREATE SCHEMA medidores AUTHORIZATION dbo');
GO

/* ============================================================
   2. ROLES DE LA APLICACION
   ============================================================ */
IF OBJECT_ID('medidores.RolApp', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.RolApp
    (
        IdRol       INT IDENTITY(1,1) NOT NULL,
        Nombre      VARCHAR(50) NOT NULL,
        Descripcion VARCHAR(200) NULL,
        Activo      BIT NOT NULL CONSTRAINT DF_RolApp_Activo DEFAULT (1),
        CONSTRAINT PK_RolApp PRIMARY KEY (IdRol),
        CONSTRAINT UQ_RolApp_Nombre UNIQUE (Nombre)
    );
END;
GO

/* ============================================================
   3. USUARIOS DE LA APLICACION
   CodPersonaCorporativa se vinculara logicamente con dbo.PERSONAS.CodPer.
   No se crea FK a dbo para mantener desacoplado el esquema propio.
   ============================================================ */
IF OBJECT_ID('medidores.Usuarios', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.Usuarios
    (
        Id                    INT IDENTITY(1,1) NOT NULL,
        CodPersonaCorporativa NUMERIC(18,0) NULL,
        NombreUsuario         VARCHAR(50) NOT NULL,
        HashPassword          VARCHAR(255) NOT NULL,
        IdRol                 INT NOT NULL,
        Activo                BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
        FechaCreacion         DATETIME2(0) NOT NULL CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT (SYSDATETIME()),
        FechaActualizacion    DATETIME2(0) NULL,
        CONSTRAINT PK_Usuarios PRIMARY KEY (Id),
        CONSTRAINT FK_Usuarios_RolApp FOREIGN KEY (IdRol)
            REFERENCES medidores.RolApp(IdRol),
        CONSTRAINT UQ_Usuarios_NombreUsuario UNIQUE (NombreUsuario)
    );
END;
GO

/* ============================================================
   4. PARAMETROS NORMATIVOS
   ============================================================ */
IF OBJECT_ID('medidores.ParametrosNormativos', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.ParametrosNormativos
    (
        IdParametro       INT IDENTITY(1,1) NOT NULL,
        Codigo            VARCHAR(30) NOT NULL,
        Descripcion       VARCHAR(200) NULL,
        ErrorMaxPermitido DECIMAL(10,4) NOT NULL,
        CaudalMin         DECIMAL(10,4) NULL,
        CaudalMax         DECIMAL(10,4) NULL,
        VigenciaInicio    DATETIME2(0) NULL,
        VigenciaFin       DATETIME2(0) NULL,
        Activo            BIT NOT NULL CONSTRAINT DF_ParametrosNormativos_Activo DEFAULT (1),
        CONSTRAINT PK_ParametrosNormativos PRIMARY KEY (IdParametro),
        CONSTRAINT UQ_ParametrosNormativos_Codigo UNIQUE (Codigo),
        CONSTRAINT CK_ParametrosNormativos_Caudal CHECK
            (CaudalMin IS NULL OR CaudalMax IS NULL OR CaudalMin <= CaudalMax),
        CONSTRAINT CK_ParametrosNormativos_Vigencia CHECK
            (VigenciaInicio IS NULL OR VigenciaFin IS NULL OR VigenciaInicio <= VigenciaFin),
        CONSTRAINT CK_ParametrosNormativos_Error CHECK (ErrorMaxPermitido >= 0)
    );
END;
GO

/* ============================================================
   5. ASIGNACION DE RUTAS
   ============================================================ */
IF OBJECT_ID('medidores.AsignacionRuta', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.AsignacionRuta
    (
        IdAsignacion        INT IDENTITY(1,1) NOT NULL,
        IdUsuarioApp        INT NOT NULL,       -- tecnico asignado
        IdUsuarioAsignador  INT NOT NULL,       -- quien armo/asigno la ruta
        FechaAsignacion     DATETIME2(0) NOT NULL,
        Estado              VARCHAR(20) NOT NULL CONSTRAINT DF_AsignacionRuta_Estado DEFAULT ('Planificado'),
        Observaciones       VARCHAR(500) NULL,
        FechaCreacion       DATETIME2(0) NOT NULL CONSTRAINT DF_AsignacionRuta_FechaCreacion DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_AsignacionRuta PRIMARY KEY (IdAsignacion),
        CONSTRAINT FK_AsignacionRuta_Tecnico FOREIGN KEY (IdUsuarioApp)
            REFERENCES medidores.Usuarios(Id),
        CONSTRAINT FK_AsignacionRuta_Asignador FOREIGN KEY (IdUsuarioAsignador)
            REFERENCES medidores.Usuarios(Id),
        CONSTRAINT CK_AsignacionRuta_Estado CHECK (Estado IN ('Planificado','EnCurso','Finalizado','Cancelado'))
    );
END;
GO

IF OBJECT_ID('medidores.DetalleRuta', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.DetalleRuta
    (
        IdDetalle          INT IDENTITY(1,1) NOT NULL,
        IdAsignacion       INT NOT NULL,
        TipoOrigen         VARCHAR(20) NOT NULL,
        IdOrigen           VARCHAR(50) NOT NULL,
        OrdenVisita        INT NOT NULL,
        Estado             VARCHAR(20) NOT NULL CONSTRAINT DF_DetalleRuta_Estado DEFAULT ('Pendiente'),
        SolicitudId        VARCHAR(60) NOT NULL,
        RegSoc             NUMERIC(6,0) NULL,
        CodMedidorActual   NUMERIC(6,0) NULL,
        NombreCliente      VARCHAR(200) NOT NULL,
        Direccion          VARCHAR(300) NOT NULL,
        Latitud            DECIMAL(18,12) NULL,
        Longitud           DECIMAL(18,12) NULL,
        FechaInicio        DATETIME2(0) NULL,
        FechaFinalizacion  DATETIME2(0) NULL,
        CONSTRAINT PK_DetalleRuta PRIMARY KEY (IdDetalle),
        CONSTRAINT FK_DetalleRuta_AsignacionRuta FOREIGN KEY (IdAsignacion)
            REFERENCES medidores.AsignacionRuta(IdAsignacion),
        CONSTRAINT CK_DetalleRuta_Origen CHECK (TipoOrigen IN ('ODECO','LECTURA','REVISION')),
        CONSTRAINT CK_DetalleRuta_Estado CHECK (Estado IN ('Pendiente','EnProceso','Completada','NoAtendida','Cancelada')),
        CONSTRAINT CK_DetalleRuta_Orden CHECK (OrdenVisita > 0)
    );
END;
GO

/* ============================================================
   6. EJECUCION DEL CAMBIO FISICO
   Los CodMedidor* y RegSoc son identificadores institucionales de dbo.
   Se guardan tambien serie/marca como snapshot para trazabilidad.
   EstadoIntegracionInstitucional registra si el cambio ya fue reflejado
   posteriormente en el sistema institucional de COSAALT.
   ============================================================ */
IF OBJECT_ID('medidores.EjecucionCambio', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.EjecucionCambio
    (
        IdEjecucion                    INT IDENTITY(1,1) NOT NULL,
        TipoOrigen                     VARCHAR(20) NOT NULL,
        IdOrigen                       VARCHAR(50) NOT NULL,
        RegSoc                         NUMERIC(6,0) NOT NULL,
        IdUsuarioApp                   INT NOT NULL,
        FechaHoraEjecucion             DATETIME2(0) NOT NULL,

        CodMedidorRetirado             NUMERIC(6,0) NULL,
        SerieMedidorRetirado           VARCHAR(30) NOT NULL,
        MarcaRetirado                  VARCHAR(50) NULL,
        LecturaRetiro                  DECIMAL(18,2) NOT NULL,

        IdMotivoInstitucional          NUMERIC(10,0) NULL,
        MotivoDescripcionSnapshot      VARCHAR(200) NULL,

        CodMedidorInstalado            NUMERIC(6,0) NULL,
        SerieMedidorInstalado          VARCHAR(30) NOT NULL,
        MarcaInstalado                 VARCHAR(50) NULL,
        ObservacionesInstalacion       VARCHAR(500) NULL,

        Latitud                        DECIMAL(18,12) NULL,
        Longitud                       DECIMAL(18,12) NULL,

        Sincronizado                   BIT NOT NULL CONSTRAINT DF_EjecucionCambio_Sincronizado DEFAULT (0),
        FechaSincronizacion            DATETIME2(0) NULL,

        EstadoIntegracionInstitucional VARCHAR(30) NOT NULL
            CONSTRAINT DF_EjecucionCambio_EstadoIntegracion DEFAULT ('PENDIENTE'),
        FechaIntegracionInstitucional  DATETIME2(0) NULL,
        DetalleIntegracionInstitucional VARCHAR(500) NULL,

        CONSTRAINT PK_EjecucionCambio PRIMARY KEY (IdEjecucion),
        CONSTRAINT FK_EjecucionCambio_Usuario FOREIGN KEY (IdUsuarioApp)
            REFERENCES medidores.Usuarios(Id),
        CONSTRAINT CK_EjecucionCambio_Origen CHECK (TipoOrigen IN ('ODECO','LECTURA','REVISION')),
        CONSTRAINT CK_EjecucionCambio_EstadoIntegracion CHECK
            (EstadoIntegracionInstitucional IN ('PENDIENTE','PROCESANDO','REGISTRADO','ERROR','NO_APLICA'))
    );
END;
GO

IF OBJECT_ID('medidores.EvidenciaFotografica', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.EvidenciaFotografica
    (
        IdFoto       INT IDENTITY(1,1) NOT NULL,
        IdEjecucion  INT NOT NULL,
        TipoFoto     VARCHAR(30) NOT NULL,
        RutaArchivo  VARCHAR(500) NOT NULL,
        FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Evidencia_FechaRegistro DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_EvidenciaFotografica PRIMARY KEY (IdFoto),
        CONSTRAINT FK_Evidencia_EjecucionCambio FOREIGN KEY (IdEjecucion)
            REFERENCES medidores.EjecucionCambio(IdEjecucion)
            ON DELETE CASCADE
    );
END;
GO

/* ============================================================
   7. VERIFICACION MECANICA
   ============================================================ */
IF OBJECT_ID('medidores.Verificaciones', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.Verificaciones
    (
        IdVerificacion              INT IDENTITY(1,1) NOT NULL,
        TipoOrigen                  VARCHAR(20) NOT NULL,
        IdOrigen                    VARCHAR(50) NOT NULL,
        RegSoc                      NUMERIC(6,0) NOT NULL,
        IdUsuarioMecanico           INT NOT NULL,
        CodMedidor                  NUMERIC(6,0) NOT NULL,
        IdParametroNormativoAplicado INT NULL,
        FechaVerificacion           DATETIME2(0) NOT NULL CONSTRAINT DF_Verificaciones_Fecha DEFAULT (SYSDATETIME()),
        Estado                      VARCHAR(20) NOT NULL CONSTRAINT DF_Verificaciones_Estado DEFAULT ('Pendiente'),
        Resultado                   VARCHAR(20) NULL,
        CONSTRAINT PK_Verificaciones PRIMARY KEY (IdVerificacion),
        CONSTRAINT FK_Verificaciones_Mecanico FOREIGN KEY (IdUsuarioMecanico)
            REFERENCES medidores.Usuarios(Id),
        CONSTRAINT FK_Verificaciones_Parametro FOREIGN KEY (IdParametroNormativoAplicado)
            REFERENCES medidores.ParametrosNormativos(IdParametro),
        CONSTRAINT CK_Verificaciones_Origen CHECK (TipoOrigen IN ('ODECO','LECTURA','REVISION','INTERNA')),
        CONSTRAINT CK_Verificaciones_Estado CHECK (Estado IN ('Pendiente','EnCurso','Completada','Cancelada')),
        CONSTRAINT CK_Verificaciones_Resultado CHECK (Resultado IS NULL OR Resultado IN ('CUMPLE','NO CUMPLE','INDETERMINADO'))
    );
END;
GO

IF OBJECT_ID('medidores.EnsayoVerificacion', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.EnsayoVerificacion
    (
        IdEnsayo          INT IDENTITY(1,1) NOT NULL,
        IdVerificacion    INT NOT NULL,
        Condiciones       VARCHAR(500) NULL,
        LecturaInicial    DECIMAL(18,2) NULL,
        LecturaFinal      DECIMAL(18,2) NULL,
        VolumenPatron     DECIMAL(18,4) NULL,
        Caudal            DECIMAL(18,4) NULL,
        VolumenRegistrado DECIMAL(18,4) NULL,
        Error             DECIMAL(10,4) NULL,
        Fugas             BIT NULL,
        Observaciones     VARCHAR(500) NULL,
        FechaRegistro     DATETIME2(0) NOT NULL CONSTRAINT DF_Ensayo_FechaRegistro DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_EnsayoVerificacion PRIMARY KEY (IdEnsayo),
        CONSTRAINT FK_Ensayo_Verificacion FOREIGN KEY (IdVerificacion)
            REFERENCES medidores.Verificaciones(IdVerificacion)
            ON DELETE CASCADE,
        CONSTRAINT UQ_Ensayo_Verificacion UNIQUE (IdVerificacion)
    );
END;
GO

IF OBJECT_ID('medidores.ParticipantesVerificacion', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.ParticipantesVerificacion
    (
        IdParticipante INT IDENTITY(1,1) NOT NULL,
        IdVerificacion INT NOT NULL,
        Nombre         VARCHAR(200) NOT NULL,
        Cargo          VARCHAR(100) NULL,
        Rol            VARCHAR(100) NULL,
        CONSTRAINT PK_ParticipantesVerificacion PRIMARY KEY (IdParticipante),
        CONSTRAINT FK_Participante_Verificacion FOREIGN KEY (IdVerificacion)
            REFERENCES medidores.Verificaciones(IdVerificacion)
            ON DELETE CASCADE
    );
END;
GO

IF OBJECT_ID('medidores.InformesVerificacion', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.InformesVerificacion
    (
        IdInforme      INT IDENTITY(1,1) NOT NULL,
        IdVerificacion INT NOT NULL,
        NroInforme     VARCHAR(50) NOT NULL,
        FechaEmision   DATETIME2(0) NOT NULL CONSTRAINT DF_Informe_FechaEmision DEFAULT (SYSDATETIME()),
        FechaFirma     DATETIME2(0) NULL,
        RutaPdf        VARCHAR(500) NULL,
        Firmado        BIT NOT NULL CONSTRAINT DF_Informe_Firmado DEFAULT (0),
        VersionInforme INT NOT NULL CONSTRAINT DF_Informe_Version DEFAULT (1),
        Observaciones  VARCHAR(500) NULL,
        CONSTRAINT PK_InformesVerificacion PRIMARY KEY (IdInforme),
        CONSTRAINT FK_Informe_Verificacion FOREIGN KEY (IdVerificacion)
            REFERENCES medidores.Verificaciones(IdVerificacion)
            ON DELETE CASCADE,
        CONSTRAINT UQ_Informe_Numero UNIQUE (NroInforme),
        CONSTRAINT CK_Informe_Version CHECK (VersionInforme > 0)
    );
END;
GO

/* ============================================================
   8. INDICES OPERATIVOS
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AsignacionRuta_Tecnico_Fecha' AND object_id = OBJECT_ID('medidores.AsignacionRuta'))
    CREATE INDEX IX_AsignacionRuta_Tecnico_Fecha
        ON medidores.AsignacionRuta(IdUsuarioApp, FechaAsignacion DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DetalleRuta_Origen' AND object_id = OBJECT_ID('medidores.DetalleRuta'))
    CREATE INDEX IX_DetalleRuta_Origen
        ON medidores.DetalleRuta(TipoOrigen, IdOrigen);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DetalleRuta_Asignacion_Orden' AND object_id = OBJECT_ID('medidores.DetalleRuta'))
    CREATE INDEX IX_DetalleRuta_Asignacion_Orden
        ON medidores.DetalleRuta(IdAsignacion, OrdenVisita);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EjecucionCambio_Origen' AND object_id = OBJECT_ID('medidores.EjecucionCambio'))
    CREATE INDEX IX_EjecucionCambio_Origen
        ON medidores.EjecucionCambio(TipoOrigen, IdOrigen);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EjecucionCambio_RegSoc_Fecha' AND object_id = OBJECT_ID('medidores.EjecucionCambio'))
    CREATE INDEX IX_EjecucionCambio_RegSoc_Fecha
        ON medidores.EjecucionCambio(RegSoc, FechaHoraEjecucion DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EjecucionCambio_Sincronizacion' AND object_id = OBJECT_ID('medidores.EjecucionCambio'))
    CREATE INDEX IX_EjecucionCambio_Sincronizacion
        ON medidores.EjecucionCambio(Sincronizado, EstadoIntegracionInstitucional);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Verificaciones_Origen' AND object_id = OBJECT_ID('medidores.Verificaciones'))
    CREATE INDEX IX_Verificaciones_Origen
        ON medidores.Verificaciones(TipoOrigen, IdOrigen);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Verificaciones_Mecanico_Fecha' AND object_id = OBJECT_ID('medidores.Verificaciones'))
    CREATE INDEX IX_Verificaciones_Mecanico_Fecha
        ON medidores.Verificaciones(IdUsuarioMecanico, FechaVerificacion DESC);
GO

/* ============================================================
   9. ROLES INICIALES
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM medidores.RolApp WHERE LOWER(Nombre) = 'tecnico')
    INSERT INTO medidores.RolApp (Nombre, Descripcion) VALUES ('tecnico', 'Ejecuta cambios de medidor y recorridos asignados.');
IF NOT EXISTS (SELECT 1 FROM medidores.RolApp WHERE LOWER(Nombre) = 'asignador')
    INSERT INTO medidores.RolApp (Nombre, Descripcion) VALUES ('asignador', 'Organiza solicitudes y asigna recorridos a tecnicos.');
IF NOT EXISTS (SELECT 1 FROM medidores.RolApp WHERE LOWER(Nombre) = 'mecanico')
    INSERT INTO medidores.RolApp (Nombre, Descripcion) VALUES ('mecanico', 'Realiza verificaciones y ensayos de medidores.');
IF NOT EXISTS (SELECT 1 FROM medidores.RolApp WHERE LOWER(Nombre) = 'administrador')
    INSERT INTO medidores.RolApp (Nombre, Descripcion) VALUES ('administrador', 'Supervisa la operacion y administra configuraciones del sistema.');
GO

/* ============================================================
   10. VERIFICACION FINAL
   ============================================================ */
SELECT
    s.name AS Esquema,
    t.name AS Tabla
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'medidores'
ORDER BY t.name;
GO

SELECT IdRol, Nombre, Descripcion, Activo
FROM medidores.RolApp
ORDER BY IdRol;
GO

/* ============================================================
   CATALOGOS PROPIOS DEL MODULO (agregado 2026-09-02)
   ============================================================ */
IF OBJECT_ID('medidores.MotivosCambio', 'U') IS NULL
BEGIN
    CREATE TABLE medidores.MotivosCambio
    (
        IdMotivo INT IDENTITY(1,1) NOT NULL,
        Nombre VARCHAR(80) NOT NULL,
        Descripcion VARCHAR(250) NULL,
        Activo BIT NOT NULL CONSTRAINT DF_MotivosCambio_Activo DEFAULT (1),
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_MotivosCambio_FechaCreacion DEFAULT (SYSDATETIME()),
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
        IdMarca INT IDENTITY(1,1) NOT NULL,
        Codigo VARCHAR(3) NOT NULL,
        Nombre VARCHAR(80) NOT NULL,
        Alias VARCHAR(80) NULL,
        Activo BIT NOT NULL CONSTRAINT DF_MarcasMedidor_Activo DEFAULT (1),
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_MarcasMedidor_FechaCreacion DEFAULT (SYSDATETIME()),
        FechaActualizacion DATETIME2(0) NULL,
        CONSTRAINT PK_MarcasMedidor PRIMARY KEY (IdMarca),
        CONSTRAINT UQ_MarcasMedidor_Codigo UNIQUE (Codigo)
    );
END;
GO

INSERT INTO medidores.MarcasMedidor (Codigo, Nombre, Alias, Activo)
SELECT x.Codigo, x.Codigo, NULL, 1
FROM (SELECT DISTINCT UPPER(RTRIM(Mar_Med)) Codigo FROM dbo.Medidor WHERE Mar_Med IS NOT NULL AND RTRIM(Mar_Med) <> '') x
WHERE NOT EXISTS (SELECT 1 FROM medidores.MarcasMedidor m WHERE UPPER(RTRIM(m.Codigo)) = x.Codigo);
GO
