using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Seed;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(CosaaltDbContext context)
    {
        await context.Database.EnsureCreatedAsync();

        if (await context.UsuariosApp.AnyAsync())
            return;

        // Id NO se fija a mano: MotivoCambioMedidor y UsuarioApp SÍ son
        // entidades propias nuestras, así que dejamos que la columna
        // IDENTITY los genere sola (empezarán en 1, 2, 3... en orden).
        context.MotivosCambio.AddRange(
            new MotivoCambioMedidor { Descripcion = "Empañado", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Destrozado", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Roto", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Descalibrado", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Antiguo", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Parado", Activo = true },
            new MotivoCambioMedidor { Descripcion = "Otro", Activo = true });

        context.UsuariosApp.AddRange(
            new UsuarioApp { NombreUsuario = "tecnico1", ContrasenaHash = "123456", NombreCompleto = "Juan Pérez García", Rol = "tecnico", Activo = true },
            new UsuarioApp { NombreUsuario = "asignador1", ContrasenaHash = "123456", NombreCompleto = "Pedro Encargado López", Rol = "asignador", Activo = true },
            new UsuarioApp { NombreUsuario = "admin", ContrasenaHash = "admin123", NombreCompleto = "Administrador COSAALT", Rol = "asignador", Activo = true },
            new UsuarioApp { NombreUsuario = "tecnico2", ContrasenaHash = "123456", NombreCompleto = "Luis Mamani Condori", Rol = "tecnico", Activo = true });

        // Latitud/Longitud ya NO va en Socio.
        context.Socios.AddRange(
            new Socio { RegistroSocio = 100234, CodigoCatastral = "CAT-001", Nombre = "María Elena Vargas", Direccion = "Av. Las Américas #452, Zona Sur", Categoria = "Doméstica", Ruta = "R-12", Recorrido = 15, Ci = "4567890", Telefono = "70123456" },
            new Socio { RegistroSocio = 100567, CodigoCatastral = "CAT-002", Nombre = "Carlos Mendoza Ríos", Direccion = "Calle Junín #890, Centro", Categoria = "Comercial", Ruta = "R-05", Recorrido = 8, Ci = "5678901", Telefono = "71234567" },
            new Socio { RegistroSocio = 100891, CodigoCatastral = "CAT-003", Nombre = "Ana Lucía Fernández", Direccion = "Pasaje Los Olivos #23, Zona Norte", Categoria = "Doméstica", Ruta = "R-08", Recorrido = 22, Ci = "6789012", Telefono = "72345678" },
            new Socio { RegistroSocio = 101045, CodigoCatastral = "CAT-004", Nombre = "Industrias del Altiplano S.A.", Direccion = "Parque Industrial Mz. 3 Lote 12", Categoria = "Industrial", Ruta = "R-15", Recorrido = 3, Ci = "7890123", Telefono = "73456789" });

        // Latitud/Longitud ahora se siembran acá, en cada Medidor.
        context.Medidores.AddRange(
            new Medidor { NumeroMedidor = "M-789012", Marca = "SAG", RegistroSocio = 100234, FechaInstalacion = new DateTime(2019, 3, 15), Estado = "Activo", Latitud = -21.5445, Longitud = -64.7285 },
            new Medidor { NumeroMedidor = "M-456789", Marca = "Elster", RegistroSocio = 100567, FechaInstalacion = new DateTime(2018, 7, 20), Estado = "Activo", Latitud = -21.5310, Longitud = -64.7295 },
            new Medidor { NumeroMedidor = "M-123456", Marca = "SAG", RegistroSocio = 100891, FechaInstalacion = new DateTime(2020, 1, 10), Estado = "Activo", Latitud = -21.5185, Longitud = -64.7340 },
            new Medidor { NumeroMedidor = "M-998877", Marca = "Elster", RegistroSocio = 101045, FechaInstalacion = new DateTime(2017, 11, 5), Estado = "Activo", Latitud = -21.5510, Longitud = -64.7120 });

        context.SolicitudesLectura.Add(
            new SolicitudLectura
            {
                NumeroHoja = "HL-202608-001",
                AnioMes = "202608",
                FechaEmision = DateTime.Today.AddDays(-5),
                HoraEmision = new TimeSpan(8, 30, 0),
                ElaboradoPor = "Oficina Comercial",
                CodigoObservacion = 14,
                DescripcionObservacion = "14 - Posible fuga después del medidor"
            });

        context.DetallesSolicitudLectura.AddRange(
            new DetalleSolicitudLectura { Id = 201, NumeroHoja = "HL-202608-001", RegistroSocio = 100891, LecturaAnterior = 890.3m, LecturaActual = 1250.7m, Consumo = 360.4m },
            new DetalleSolicitudLectura { Id = 202, NumeroHoja = "HL-202608-001", RegistroSocio = 101045, LecturaAnterior = 15600m, LecturaActual = 18900m, Consumo = 3300m });

        context.ReclamosOdeco.AddRange(
            new ReclamoOdeco
            {
                Folio = 1042,
                FechaReclamo = DateTime.Today.AddDays(-1),
                RegistroSocio = 100234,
                NombreSolicitante = "María Elena Vargas",
                MotivoReclamo = "Medidor parado - posible fuga",
                MedidorParado = true,
                Conclusion = "CAMBIAR MEDIDOR",
                PrioridadNota = "URGENTE",
                LecturaAnteriorAnalisis = 1250.5m,
                LecturaActualAnalisis = 1250.5m,
                ConsumoAnalisis = 0m
            },
            new ReclamoOdeco
            {
                Folio = 1043,
                FechaReclamo = DateTime.Today,
                RegistroSocio = 100567,
                NombreSolicitante = "Carlos Mendoza Ríos",
                MotivoReclamo = "Medidor destrozado por vandalismo",
                MedidorParado = false,
                Conclusion = "CAMBIAR MEDIDOR",
                PrioridadNota = "URGENTE",
                LecturaAnteriorAnalisis = 3420m,
                LecturaActualAnalisis = 3420m,
                ConsumoAnalisis = 0m
            });

        await context.SaveChangesAsync();
    }
}