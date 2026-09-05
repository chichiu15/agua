/* COSAALT Medidores - ajustes de integridad necesarios para sincronizacion concurrente.
   Ejecutar UNA VEZ en cosaalt despues del script 01. No modifica dbo.*. */
USE cosaalt;
GO
IF DB_NAME() <> 'cosaalt' THROW 51000, 'Ejecutar exclusivamente en cosaalt.', 1;
GO

-- Idempotencia: una solicitud/origen produce como maximo una ejecucion fisica.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('medidores.EjecucionCambio')
      AND name = 'UX_EjecucionCambio_Origen')
BEGIN
    CREATE UNIQUE INDEX UX_EjecucionCambio_Origen
        ON medidores.EjecucionCambio(TipoOrigen, IdOrigen);
END;
GO

-- Evita que dos sincronizaciones concurrentes instalen el mismo medidor.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('medidores.EjecucionCambio')
      AND name = 'UX_EjecucionCambio_CodMedidorInstalado')
BEGIN
    CREATE UNIQUE INDEX UX_EjecucionCambio_CodMedidorInstalado
        ON medidores.EjecucionCambio(CodMedidorInstalado)
        WHERE CodMedidorInstalado IS NOT NULL;
END;
GO

SELECT name, is_unique, filter_definition
FROM sys.indexes
WHERE object_id = OBJECT_ID('medidores.EjecucionCambio')
ORDER BY name;
GO
