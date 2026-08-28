using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Seed;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(CosaaltDbContext context)
    {
        await context.Database.EnsureCreatedAsync();

        if (!await context.MotivosCambio.AnyAsync())
        {
            context.MotivosCambio.AddRange(
                new MotivoCambioMedidor { Descripcion = "Empañado", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Destrozado", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Roto", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Descalibrado", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Antiguo", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Parado", Activo = true },
                new MotivoCambioMedidor { Descripcion = "Otro", Activo = true });
            await context.SaveChangesAsync();
        }

        if (!await context.UsuariosApp.AnyAsync())
        {
            context.UsuariosApp.AddRange(
                new UsuarioApp { NombreUsuario = "tecnico1", ContrasenaHash = "123456", NombreCompleto = "Juan Pérez García", Rol = "tecnico", Activo = true },
                new UsuarioApp { NombreUsuario = "tecnico2", ContrasenaHash = "123456", NombreCompleto = "Luis Mamani Condori", Rol = "tecnico", Activo = true },
                new UsuarioApp { NombreUsuario = "tecnico3", ContrasenaHash = "123456", NombreCompleto = "Carlos Rojas Mendoza", Rol = "tecnico", Activo = false },
                new UsuarioApp { NombreUsuario = "tecnico4", ContrasenaHash = "123456", NombreCompleto = "Miguel Ángel Torres", Rol = "tecnico", Activo = true },
                new UsuarioApp { NombreUsuario = "asignador1", ContrasenaHash = "123456", NombreCompleto = "Pedro Encargado López", Rol = "asignador", Activo = true },
                new UsuarioApp { NombreUsuario = "admin", ContrasenaHash = "admin123", NombreCompleto = "Administrador COSAALT", Rol = "asignador", Activo = true });
            await context.SaveChangesAsync();
        }

        if (!await context.Socios.AnyAsync())
        {
            context.Socios.AddRange(
                new Socio { RegistroSocio = 100234, CodigoCatastral = "CAT-001", Nombre = "María Elena Vargas", Direccion = "Av. Las Américas #452, Zona Sur", Categoria = "Doméstica", Ruta = "R-12", Recorrido = 15, Ci = "4567890", Telefono = "70123456" },
                new Socio { RegistroSocio = 100567, CodigoCatastral = "CAT-002", Nombre = "Carlos Mendoza Ríos", Direccion = "Calle Junín #890, Centro", Categoria = "Comercial", Ruta = "R-05", Recorrido = 8, Ci = "5678901", Telefono = "71234567" },
                new Socio { RegistroSocio = 100891, CodigoCatastral = "CAT-003", Nombre = "Ana Lucía Fernández", Direccion = "Pasaje Los Olivos #23, Zona Norte", Categoria = "Doméstica", Ruta = "R-08", Recorrido = 22, Ci = "6789012", Telefono = "72345678" },
                new Socio { RegistroSocio = 101045, CodigoCatastral = "CAT-004", Nombre = "Industrias del Altiplano S.A.", Direccion = "Parque Industrial Mz. 3 Lote 12", Categoria = "Industrial", Ruta = "R-15", Recorrido = 3, Ci = "7890123", Telefono = "73456789" },
                new Socio { RegistroSocio = 101200, CodigoCatastral = "CAT-005", Nombre = "Roberto Sánchez Pérez", Direccion = "Av. Heroínas #1567, Centro", Categoria = "Doméstica", Ruta = "R-03", Recorrido = 11, Ci = "8901234", Telefono = "74567890" });
            await context.SaveChangesAsync();
        }

        if (!await context.Medidores.AnyAsync())
        {
            context.Medidores.AddRange(
                new Medidor { NumeroMedidor = "M-789012", Marca = "SAG", RegistroSocio = 100234, FechaInstalacion = new DateTime(2019, 3, 15), Estado = "Activo", Latitud = -21.5445, Longitud = -64.7285 },
                new Medidor { NumeroMedidor = "M-456789", Marca = "Elster", RegistroSocio = 100567, FechaInstalacion = new DateTime(2018, 7, 20), Estado = "Activo", Latitud = -21.5310, Longitud = -64.7295 },
                new Medidor { NumeroMedidor = "M-123456", Marca = "SAG", RegistroSocio = 100891, FechaInstalacion = new DateTime(2020, 1, 10), Estado = "Activo", Latitud = -21.5185, Longitud = -64.7340 },
                new Medidor { NumeroMedidor = "M-998877", Marca = "Elster", RegistroSocio = 101045, FechaInstalacion = new DateTime(2017, 11, 5), Estado = "Activo", Latitud = -21.5510, Longitud = -64.7120 },
                new Medidor { NumeroMedidor = "M-334455", Marca = "SAG", RegistroSocio = 101200, FechaInstalacion = new DateTime(2021, 6, 12), Estado = "Activo", Latitud = -21.5290, Longitud = -64.7310 });
            await context.SaveChangesAsync();
        }

        if (!await context.SolicitudesLectura.AnyAsync())
        {
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
            await context.SaveChangesAsync();
        }

        if (!await context.DetallesSolicitudLectura.AnyAsync())
        {
            context.DetallesSolicitudLectura.AddRange(
                new DetalleSolicitudLectura { Id = 201, NumeroHoja = "HL-202608-001", RegistroSocio = 100891, LecturaAnterior = 890.3m, LecturaActual = 1250.7m, Consumo = 360.4m },
                new DetalleSolicitudLectura { Id = 202, NumeroHoja = "HL-202608-001", RegistroSocio = 101045, LecturaAnterior = 15600m, LecturaActual = 18900m, Consumo = 3300m },
                new DetalleSolicitudLectura { Id = 203, NumeroHoja = "HL-202608-001", RegistroSocio = 101200, LecturaAnterior = 456.2m, LecturaActual = 458.1m, Consumo = 1.9m });
            await context.SaveChangesAsync();
        }

        if (!await context.ReclamosOdeco.AnyAsync())
        {
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

        // --- Tablas dbo: IDENTITY en SQL Server, no setear IDs explícitos ---

        if (!await context.Barrios.AnyAsync())
        {
            context.Barrios.AddRange(
                new Barrio { NomBar = "Zona Sur", EstBar = true },
                new Barrio { NomBar = "Centro", EstBar = true },
                new Barrio { NomBar = "Zona Norte", EstBar = true },
                new Barrio { NomBar = "Parque Industrial", EstBar = true },
                new Barrio { NomBar = "Centro", EstBar = true });
            await context.SaveChangesAsync();
        }

        if (!await context.Predios.AnyAsync())
        {
            context.Predios.AddRange(
                new Predio { CodUbiPre = "URB-001", NumPre = "452" },
                new Predio { CodUbiPre = "CTR-002", NumPre = "890" },
                new Predio { CodUbiPre = "ZNO-003", NumPre = "23" },
                new Predio { CodUbiPre = "PIN-004", NumPre = "12" },
                new Predio { CodUbiPre = "CTR-005", NumPre = "1567" });
            await context.SaveChangesAsync();
        }

        if (!await context.Recurrentes.AnyAsync())
        {
            context.Recurrentes.AddRange(
                new Recurrente { NomRec = "María Elena Vargas", CeIdRec = "4567890", TelRec = "70123456", SexRec = false },
                new Recurrente { NomRec = "Carlos Mendoza Ríos", CeIdRec = "5678901", TelRec = "71234567", SexRec = true },
                new Recurrente { NomRec = "Ana Lucía Fernández", CeIdRec = "6789012", TelRec = "72345678", SexRec = false },
                new Recurrente { NomRec = "Industrias del Altiplano S.A.", CeIdRec = "7890123", TelRec = "73456789", SexRec = true },
                new Recurrente { NomRec = "Roberto Sánchez Pérez", CeIdRec = "8901234", TelRec = "74567890", SexRec = true });
            await context.SaveChangesAsync();
        }

        if (!await context.Conexiones.AnyAsync())
        {
            var predios = await context.Predios.OrderBy(p => p.CodPre).ToListAsync();
            context.Conexiones.AddRange(
                new Conexion { FecCon = new DateTime(2015, 3, 20), NomSoc = "María Elena Vargas", CanPerCon = 4, CodPre = predios[0].CodPre, CooX2Con = -21.5445, CooY2Con = -64.7285 },
                new Conexion { FecCon = new DateTime(2016, 7, 15), NomSoc = "Carlos Mendoza Ríos", CanPerCon = 3, CodPre = predios[1].CodPre, CooX2Con = -21.5310, CooY2Con = -64.7295 },
                new Conexion { FecCon = new DateTime(2018, 1, 10), NomSoc = "Ana Lucía Fernández", CanPerCon = 5, CodPre = predios[2].CodPre, CooX2Con = -21.5185, CooY2Con = -64.7340 },
                new Conexion { FecCon = new DateTime(2014, 11, 5), NomSoc = "Industrias del Altiplano S.A.", CanPerCon = 20, CodPre = predios[3].CodPre, CooX2Con = -21.5510, CooY2Con = -64.7120 },
                new Conexion { FecCon = new DateTime(2019, 6, 12), NomSoc = "Roberto Sánchez Pérez", CanPerCon = 6, CodPre = predios[4].CodPre, CooX2Con = -21.5290, CooY2Con = -64.7310 });
            await context.SaveChangesAsync();
        }

        if (!await context.Reclamos.AnyAsync())
        {
            var barrios = await context.Barrios.OrderBy(b => b.CodBar).ToListAsync();
            var recurrentes = await context.Recurrentes.OrderBy(r => r.CodRec).ToListAsync();
            var conexiones = await context.Conexiones.OrderBy(c => c.CodCon).ToListAsync();

            context.Reclamos.AddRange(
                new Reclamo { ModRec = 'N', FecRec = DateTime.Today.AddDays(-2), NumRec = 1, FecEstResRec = DateTime.Today.AddDays(3), CodAsFu = 1, CodMoRe = 1, CodCon = conexiones[0].CodCon, PriRec = 'A', EstRec = true, DesRec = "URGENTE - Medidor parado, posible fuga", CodBar = barrios[0].CodBar },
                new Reclamo { ModRec = 'N', FecRec = DateTime.Today.AddDays(-1), NumRec = 2, FecEstResRec = DateTime.Today.AddDays(5), CodAsFu = 1, CodMoRe = 2, CodCon = conexiones[1].CodCon, CodRec2 = recurrentes[1].CodRec, PriRec = 'B', EstRec = true, DesRec = "Medidor destrozado por vandalismo", CodBar = barrios[1].CodBar },
                new Reclamo { ModRec = 'N', FecRec = DateTime.Today, NumRec = 3, FecEstResRec = DateTime.Today.AddDays(7), CodAsFu = 1, CodMoRe = 3, CodCon = conexiones[2].CodCon, CodRec2 = recurrentes[2].CodRec, PriRec = 'B', EstRec = true, DesRec = "Lectura irregular en medidor", CodBar = barrios[2].CodBar },
                new Reclamo { ModRec = 'N', FecRec = DateTime.Today, NumRec = 4, FecEstResRec = DateTime.Today.AddDays(2), CodAsFu = 1, CodMoRe = 1, CodCon = conexiones[3].CodCon, CodRec2 = recurrentes[3].CodRec, PriRec = 'A', EstRec = true, DesRec = "URGENTE - Medidor empañado, no se lee", CodBar = barrios[3].CodBar },
                new Reclamo { ModRec = 'N', FecRec = DateTime.Today.AddDays(-3), NumRec = 5, FecEstResRec = DateTime.Today.AddDays(10), CodAsFu = 1, CodMoRe = 5, CodCon = conexiones[4].CodCon, CodRec2 = recurrentes[4].CodRec, PriRec = 'C', EstRec = true, DesRec = "Medidor antiguo, necesita reemplazo", CodBar = barrios[4].CodBar });
            await context.SaveChangesAsync();
        }
    }
}
