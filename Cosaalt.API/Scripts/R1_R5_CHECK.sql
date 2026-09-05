-- R1-R5: verificacion de estructura. SOLO LECTURA.

SELECT IdRol, Nombre, Descripcion, Activo
FROM medidores.RolApp
ORDER BY IdRol;

SELECT TOP (50) Id, CodFunCorporativo, NombreUsuario, IdRol, Activo, FechaCreacion
FROM medidores.Usuarios
ORDER BY Id;

SELECT CodMoCaMe, NomMoCaMe, EstMoCaMe
FROM dbo.MotivosCambioMedidor
ORDER BY CodMoCaMe;

SELECT TOP (100) CodMar, NomMar, AliMar
FROM dbo.Marcas
ORDER BY NomMar;

SELECT IdParametro, Codigo, Descripcion, ErrorMaxPermitido, CaudalMin, CaudalMax,
       VigenciaInicio, VigenciaFin, Activo
FROM medidores.ParametrosNormativos
ORDER BY IdParametro;
