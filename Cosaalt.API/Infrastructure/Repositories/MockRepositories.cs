using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Infrastructure.Repositories;

public class MockSolicitudRepository : ISolicitudRepository
{
    private static readonly List<SolicitudBandejaDto> SolicitudesMock =
    [
        new("ODECO-1042","ODECO","Pendiente",true,100234,"María Elena Vargas","Av. Las Américas #452, Zona Sur","Doméstica","R-12",15,"M-789012","SAG",1250.5m,1250.5m,0m,"Medidor parado - posible fuga",DateTime.Today.AddDays(-1),1042,"CAMBIAR MEDIDOR",-21.5445,-64.7285),
        new("ODECO-1043","ODECO","Pendiente",true,100567,"Carlos Mendoza Ríos","Calle Junín #890, Centro","Comercial","R-05",8,"M-456789","Elster",3420m,3420m,0m,"Medidor destrozado por vandalismo",DateTime.Today,1043,"CAMBIAR MEDIDOR",-21.5310,-64.7295),
        new("LEC-201","LECTURA","Pendiente",false,100891,"Ana Lucía Fernández","Pasaje Los Olivos #23, Zona Norte","Doméstica","R-08",22,"M-123456","SAG",890.3m,1250.7m,360.4m,"14 - Posible fuga después del medidor",DateTime.Today.AddDays(-5),null,null,-21.5185,-64.7340),
        new("LEC-202","LECTURA","Pendiente",false,101045,"Industrias del Altiplano S.A.","Parque Industrial Mz. 3 Lote 12","Industrial","R-15",3,"M-998877","Elster",15600m,18900m,3300m,"14 - Alto consumo / Posible fuga",DateTime.Today.AddDays(-3),null,null,-21.5510,-64.7120),
        new("LEC-203","LECTURA","Completada",false,101200,"Roberto Sánchez Pérez","Av. Heroínas #1567","Doméstica","R-03",11,"M-334455","SAG",456.2m,458.1m,1.9m,"Medidor empañado",DateTime.Today,null,null,-21.5290,-64.7310)
    ];

    public Task<SolicitudesResponseDto> ObtenerSolicitudesAsync(string? filtro = null)
    {
        var filtradas = filtro?.ToLowerInvariant() switch
        {
            "pendientes" => SolicitudesMock.Where(s => s.Estado == "Pendiente").ToList(),
            "urgentes" => SolicitudesMock.Where(s => s.EsUrgente && s.Estado == "Pendiente").ToList(),
            "odeco" => SolicitudesMock.Where(s => s.TipoOrigen == "ODECO").ToList(),
            "lectura" => SolicitudesMock.Where(s => s.TipoOrigen == "LECTURA").ToList(),
            _ => SolicitudesMock
        };

        var resumen = new DashboardResumenDto(
            OdecoUrgentes: SolicitudesMock.Count(s => s.TipoOrigen == "ODECO" && s.EsUrgente && s.Estado == "Pendiente"),
            LecturasDelMes: SolicitudesMock.Count(s => s.TipoOrigen == "LECTURA" && s.Estado == "Pendiente"),
            CompletadasHoy: SolicitudesMock.Count(s => s.Estado == "Completada" && s.FechaSolicitud.Date == DateTime.Today));

        return Task.FromResult(new SolicitudesResponseDto(resumen, filtradas));
    }

    public Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id) =>
        Task.FromResult(SolicitudesMock.FirstOrDefault(s => s.Id == id));
}

public class MockAuthRepository : IAuthRepository
{
    private static readonly List<Usuario> Usuarios =
    [
        new() { Id = 1, CodPersonaCorporativa = 1001, NombreUsuario = "tecnico1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 1, Nombre = "tecnico" } },
        new() { Id = 2, CodPersonaCorporativa = 1002, NombreUsuario = "asignador1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 2, Nombre = "asignador" } },
        new() { Id = 3, CodPersonaCorporativa = 1003, NombreUsuario = "admin", HashPassword = "admin123", Activo = true,
                Rol = new RolApp { IdRol = 3, Nombre = "administrador" } },
        new() { Id = 4, CodPersonaCorporativa = 1004, NombreUsuario = "tecnico2", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 1, Nombre = "tecnico" } },
        new() { Id = 5, CodPersonaCorporativa = null, NombreUsuario = "mecanico1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 4, Nombre = "mecanico" } }
    ];

    private static readonly IReadOnlyDictionary<string, string> Nombres =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["tecnico1"] = "Juan Perez Garcia",
            ["asignador1"] = "Pedro Encargado Lopez",
            ["admin"] = "Administrador COSAALT",
            ["tecnico2"] = "Luis Mamani Condori",
            ["mecanico1"] = "Mecanico COSAALT"
        };

    public Task<LoginResponseDto?> LoginAsync(string usuario, string contrasena)
    {
        var user = Usuarios.FirstOrDefault(u =>
            u.NombreUsuario.Equals(usuario, StringComparison.OrdinalIgnoreCase) &&
            u.HashPassword == contrasena && u.Activo);

        if (user is null) return Task.FromResult<LoginResponseDto?>(null);

        var token = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));
        var nombre = Nombres.TryGetValue(user.NombreUsuario, out var n) ? n : user.NombreUsuario;
        return Task.FromResult<LoginResponseDto?>(new LoginResponseDto(user.Id, nombre, user.Rol.Nombre, token));
    }
}

public class MockCatalogoRepository : ICatalogoRepository
{
    private static readonly object Sync = new();
    private static readonly List<MotivoCambioDto> Motivos =
    [
        new(1, "Reparacion", "Cambio por reparacion del medidor", true),
        new(2, "Mantenimiento", "Cambio por mantenimiento preventivo o correctivo", true),
        new(3, "Fuga", "Cambio asociado a fuga detectada", true),
        new(4, "Motivo inactivo de ejemplo", "Registro de demostracion", false)
    ];

    private static readonly List<MarcaMedidorDto> Marcas =
    [
        new(1, "SAG", "SAG"), new(2, "Elster", "ELS"), new(3, "LAO", "LAO"), new(4, "Itron", "ITR")
    ];

    public Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync(bool incluirInactivos = false)
    {
        lock (Sync)
        {
            IReadOnlyList<MotivoCambioDto> result = Motivos
                .Where(m => incluirInactivos || m.Activo)
                .OrderBy(m => m.Id)
                .ToList();
            return Task.FromResult(result);
        }
    }

    public Task<MotivoCambioDto> CrearMotivoAsync(GuardarMotivoCambioRequestDto request)
    {
        lock (Sync)
        {
            if (Motivos.Any(m => string.Equals(m.Descripcion, request.Nombre.Trim(), StringComparison.OrdinalIgnoreCase)))
                throw new InvalidOperationException("Ya existe un motivo con ese nombre.");
            var next = Motivos.Count == 0 ? 1 : Motivos.Max(m => m.Id) + 1;
            var item = new MotivoCambioDto(next, request.Nombre.Trim(), request.Descripcion?.Trim(), request.Activo);
            Motivos.Add(item);
            return Task.FromResult(item);
        }
    }

    public Task<MotivoCambioDto?> ActualizarMotivoAsync(int id, GuardarMotivoCambioRequestDto request)
    {
        lock (Sync)
        {
            var index = Motivos.FindIndex(m => m.Id == id);
            if (index < 0) return Task.FromResult<MotivoCambioDto?>(null);
            if (Motivos.Any(m => m.Id != id && string.Equals(m.Descripcion, request.Nombre.Trim(), StringComparison.OrdinalIgnoreCase)))
                throw new InvalidOperationException("Ya existe otro motivo con ese nombre.");
            var item = new MotivoCambioDto(id, request.Nombre.Trim(), request.Descripcion?.Trim(), request.Activo);
            Motivos[index] = item;
            return Task.FromResult<MotivoCambioDto?>(item);
        }
    }

    public Task<MotivoCambioDto?> CambiarEstadoMotivoAsync(int id, bool activo)
    {
        lock (Sync)
        {
            var index = Motivos.FindIndex(m => m.Id == id);
            if (index < 0) return Task.FromResult<MotivoCambioDto?>(null);
            var current = Motivos[index];
            var item = current with { Activo = activo };
            Motivos[index] = item;
            return Task.FromResult<MotivoCambioDto?>(item);
        }
    }

    public Task<IReadOnlyList<MarcaMedidorDto>> ObtenerMarcasAsync(bool incluirInactivos = true) =>
        Task.FromResult<IReadOnlyList<MarcaMedidorDto>>(incluirInactivos ? Marcas : Marcas.Where(x => x.Activo).ToList());

    public Task<MarcaMedidorDto> CrearMarcaAsync(GuardarMarcaMedidorRequestDto request)
    {
        var next = Marcas.Count == 0 ? 1 : Marcas.Max(x => x.Id) + 1;
        var item = new MarcaMedidorDto(next, request.Nombre.Trim(), request.Alias?.Trim(), request.Activo, request.Codigo.Trim().ToUpperInvariant());
        Marcas.Add(item);
        return Task.FromResult(item);
    }

    public Task<MarcaMedidorDto?> ActualizarMarcaAsync(int id, GuardarMarcaMedidorRequestDto request)
    {
        var index = Marcas.FindIndex(x => x.Id == id);
        if (index < 0) return Task.FromResult<MarcaMedidorDto?>(null);
        var item = new MarcaMedidorDto(id, request.Nombre.Trim(), request.Alias?.Trim(), request.Activo, request.Codigo.Trim().ToUpperInvariant());
        Marcas[index] = item;
        return Task.FromResult<MarcaMedidorDto?>(item);
    }

    public Task<MarcaMedidorDto?> CambiarEstadoMarcaAsync(int id, bool activo)
    {
        var index = Marcas.FindIndex(x => x.Id == id);
        if (index < 0) return Task.FromResult<MarcaMedidorDto?>(null);
        var current = Marcas[index];
        var item = current with { Activo = activo };
        Marcas[index] = item;
        return Task.FromResult<MarcaMedidorDto?>(item);
    }

    public Task<IReadOnlyList<MedidorDisponibleDto>> ObtenerMedidoresDisponiblesAsync(string? buscar = null, int limite = 100)
    {
        IReadOnlyList<MedidorDisponibleDto> items = new[]
        {
            new MedidorDisponibleDto(90001, "TEST001", "HDM", "Velocimetro Mag.", "3M3", "1/2\"", 5, "PERFECTO", "L"),
            new MedidorDisponibleDto(90002, "TEST002", "LAO", "Velocimetro Mag.", "3M3", "1/2\"", 5, "PERFECTO", "L")
        };
        if (!string.IsNullOrWhiteSpace(buscar))
            items = items.Where(x => x.Serie.Contains(buscar, StringComparison.OrdinalIgnoreCase) || x.Marca.Contains(buscar, StringComparison.OrdinalIgnoreCase)).ToList();
        return Task.FromResult<IReadOnlyList<MedidorDisponibleDto>>(items.Take(limite).ToList());
    }
}

public class MockEjecucionRepository : IEjecucionRepository
{
    private static int _nextId = 5000;

    public Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request)
    {
        var id = Interlocked.Increment(ref _nextId);
        return Task.FromResult(new EjecucionCambioResponseDto(id, "Ejecución registrada.", true));
    }

    public Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null, int? idUsuarioApp = null)
    {
        var historial = new List<EjecucionHistorialDto>
        {
            new(
                IdEjecucion: 5001,
                TipoOrigen: "ODECO",
                IdOrigen: "2001",
                SolicitudId: "ODECO-2001",
                FechaHoraEjecucion: DateTime.Today.AddHours(-2),
                CodCon: 42,
                NombreCliente: "Juan Pérez García",
                Direccion: "Av. Las Palmeras N° 120, Zona Sud",
                NumeroMedidorRetirado: "14079823",
                MarcaRetirado: "Elster",
                LecturaRetiro: 8124.5m,
                NumeroMedidorInstalado: "14208771",
                MarcaInstalado: "Itrón",
                Observaciones: "Estado: Instalado",
                NombreTecnico: "Luis Mamani Condori",
                MotivoDescripcion: "Empañado",
                Evidencias:
                [
                    new EvidenciaHistorialDto("MedidorRetirado", "/uploads/2001/retirado.jpg"),
                    new EvidenciaHistorialDto("MedidorNuevo", "/uploads/2001/nuevo.jpg")
                ]),
            new(
                IdEjecucion: 5002,
                TipoOrigen: "LECTURA",
                IdOrigen: "1001",
                SolicitudId: "LEC-1001",
                FechaHoraEjecucion: DateTime.Today.AddHours(-1),
                CodCon: 17,
                NombreCliente: "María Condori Vaca",
                Direccion: "Calle Cochabamba N° 456",
                NumeroMedidorRetirado: "90541236",
                MarcaRetirado: "Actaris",
                LecturaRetiro: 4210m,
                NumeroMedidorInstalado: "91887720",
                MarcaInstalado: "Elster",
                Observaciones: "Estado: Nuevo",
                NombreTecnico: "Carlos Rojas Mendoza",
                MotivoDescripcion: "Destrozado",
                Evidencias:
                [
                    new EvidenciaHistorialDto("MedidorRetirado", "/uploads/1001/retirado.jpg")
                ])
        };

        if (codCon is int conexion)
        {
            historial = historial.Where(h => h.CodCon == conexion).ToList();
        }

        // Los datos mock representan tecnico1 (Id=1). Mantener el mismo
        // contrato que SQL evita que el historial de un usuario muestre
        // ejecuciones ajenas durante las pruebas sin base de datos.
        if (idUsuarioApp.HasValue && idUsuarioApp.Value != 1)
            historial = [];

        return Task.FromResult<IReadOnlyList<EjecucionHistorialDto>>(historial);
    }
}

public class MockUsuarioRepository : IUsuarioRepository
{
    private static int _nextId = 5;

    private static readonly List<RolDto> Roles =
    [
        new(1, "tecnico", "Tecnico de campo", true),
        new(2, "asignador", "Asignador de rutas", true),
        new(3, "administrador", "Administrador", true),
        new(4, "mecanico", "Mecanico de medidores", true)
    ];

    private static readonly List<UsuarioDto> Usuarios =
    [
        new(1, "Juan Perez Garcia", "tecnico1", "tecnico", 1, true, 1001, DateTime.Today.AddDays(-30)),
        new(4, "Luis Mamani Condori", "tecnico2", "tecnico", 1, true, 1002, DateTime.Today.AddDays(-20)),
        new(2, "Pedro Encargado Lopez", "asignador1", "asignador", 2, true, null, DateTime.Today.AddDays(-15)),
        new(3, "Administrador COSAALT", "admin", "administrador", 3, true, null, DateTime.Today.AddDays(-10)),
        new(5, "Mecanico COSAALT", "mecanico1", "mecanico", 4, true, null, DateTime.Today.AddDays(-5))
    ];

    private static readonly List<FuncionarioDto> Funcionarios =
    [
        new(125, "Jorge Vides Ortega", "JOVIOR", true),
        new(126, "Luis Gualberto Pecas Calla", "LGPECA", true),
        new(130, "Willan Mario Alfaro Tejerina", "WMALTE", true)
    ];

    public Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync()
    {
        var tecnicos = Usuarios.Where(u => u.Rol == "tecnico")
            .Select(u => new TecnicoDto(u.Id, u.NombreCompleto, u.Rol, u.Activo, false))
            .ToList();
        return Task.FromResult<IReadOnlyList<TecnicoDto>>(tecnicos);
    }

    public Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync() =>
        Task.FromResult<IReadOnlyList<UsuarioDto>>(Usuarios.ToList());

    public Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosActivosAsync() =>
        Task.FromResult<IReadOnlyList<FuncionarioDto>>(Funcionarios.ToList());

    public Task<IReadOnlyList<RolDto>> ObtenerRolesAsync() =>
        Task.FromResult<IReadOnlyList<RolDto>>(Roles.ToList());

    public Task<UsuarioDto> CrearAsync(CrearUsuarioRequestDto request)
    {
        if (Usuarios.Any(u => u.NombreUsuario.Equals(request.NombreUsuario, StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException("Ya existe un usuario con ese nombre de usuario.");
        var rol = Roles.First(r => r.Id == request.IdRol);
        var funcionario = Funcionarios.FirstOrDefault(f => f.CodFun == request.CodFunCorporativo);
        var dto = new UsuarioDto(
            Interlocked.Increment(ref _nextId),
            funcionario?.NombreCompleto ?? request.NombreUsuario,
            request.NombreUsuario.Trim(), rol.Nombre, rol.Id, request.Activo,
            request.CodFunCorporativo, DateTime.Now);
        Usuarios.Add(dto);
        return Task.FromResult(dto);
    }

    public Task<UsuarioDto?> ActualizarAsync(int id, ActualizarUsuarioRequestDto request)
    {
        var index = Usuarios.FindIndex(u => u.Id == id);
        if (index < 0) return Task.FromResult<UsuarioDto?>(null);
        if (Usuarios.Any(u => u.Id != id && u.NombreUsuario.Equals(request.NombreUsuario, StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException("Ya existe un usuario con ese nombre de usuario.");
        var anterior = Usuarios[index];
        var rol = Roles.First(r => r.Id == request.IdRol);
        var funcionario = Funcionarios.FirstOrDefault(f => f.CodFun == request.CodFunCorporativo);
        var actualizado = anterior with
        {
            NombreCompleto = funcionario?.NombreCompleto ?? request.NombreUsuario,
            NombreUsuario = request.NombreUsuario.Trim(),
            Rol = rol.Nombre,
            IdRol = rol.Id,
            Activo = request.Activo,
            CodFunCorporativo = request.CodFunCorporativo
        };
        Usuarios[index] = actualizado;
        return Task.FromResult<UsuarioDto?>(actualizado);
    }
}


public class MockVerificacionRepository : IVerificacionRepository
{
    public Task<IReadOnlyList<SolicitudVerificacionDto>> ObtenerSolicitudesAsync() =>
        Task.FromResult<IReadOnlyList<SolicitudVerificacionDto>>(Array.Empty<SolicitudVerificacionDto>());

    public Task<TomarVerificacionResponseDto> TomarAsync(TomarVerificacionRequestDto request) =>
        throw new InvalidOperationException("El modulo de verificaciones mecanicas usa SQL real. Cambia RepositoryMode a Sql para probarlo.");

    public Task<IReadOnlyList<VerificacionDto>> ObtenerVerificacionesAsync(int idMecanico) =>
        Task.FromResult<IReadOnlyList<VerificacionDto>>(Array.Empty<VerificacionDto>());

    public Task<VerificacionDto?> ObtenerVerificacionAsync(int id) =>
        Task.FromResult<VerificacionDto?>(null);

    public Task<DatosSocioMedidorDto?> ObtenerDatosSocioMedidorAsync(int idVerificacion) =>
        Task.FromResult<DatosSocioMedidorDto?>(null);

    public Task<VerificacionDto?> GuardarEnsayoAsync(
        int idVerificacion,
        decimal? volumenRegistrado,
        decimal? error,
        GuardarEnsayoRequestDto request) =>
        Task.FromResult<VerificacionDto?>(null);
}

public class MockParametroNormativoRepository : IParametroNormativoRepository
{
    private static int _nextId = 2;
    private static readonly List<ParametroNormativoDto> Items =
    [
        new(1, "NB-ISO4064-Q2", "Regla de demostracion para caudal de transicion", 2.0m, 15m, 120m, new DateTime(2026, 1, 1), null, true),
        new(2, "NB-ISO4064-Q3", "Regla de demostracion para caudal permanente", 2.0m, 120.01m, 1000m, new DateTime(2026, 1, 1), null, true)
    ];

    public Task<IReadOnlyList<ParametroNormativoDto>> ObtenerTodosAsync() => Task.FromResult<IReadOnlyList<ParametroNormativoDto>>(Items.ToList());
    public Task<ParametroNormativoDto?> ObtenerPorIdAsync(int id) => Task.FromResult(Items.FirstOrDefault(p => p.Id == id));
    public Task<ParametroNormativoDto?> ObtenerVigenteAsync(decimal caudal, DateTime fecha) => Task.FromResult(Items.FirstOrDefault(p => p.Activo && (!p.CaudalMin.HasValue || p.CaudalMin <= caudal) && (!p.CaudalMax.HasValue || p.CaudalMax >= caudal) && (!p.VigenciaInicio.HasValue || p.VigenciaInicio <= fecha) && (!p.VigenciaFin.HasValue || p.VigenciaFin >= fecha)));
    public Task<ParametroNormativoDto> CrearAsync(GuardarParametroNormativoRequestDto r)
    {
        var item = new ParametroNormativoDto(Interlocked.Increment(ref _nextId), r.Codigo, r.Descripcion, r.ErrorMaxPermitido, r.CaudalMin, r.CaudalMax, r.VigenciaInicio, r.VigenciaFin, r.Activo);
        Items.Add(item);
        return Task.FromResult(item);
    }
    public Task<ParametroNormativoDto?> ActualizarAsync(int id, GuardarParametroNormativoRequestDto r)
    {
        var i = Items.FindIndex(p => p.Id == id); if (i < 0) return Task.FromResult<ParametroNormativoDto?>(null);
        var item = new ParametroNormativoDto(id, r.Codigo, r.Descripcion, r.ErrorMaxPermitido, r.CaudalMin, r.CaudalMax, r.VigenciaInicio, r.VigenciaFin, r.Activo);
        Items[i] = item; return Task.FromResult<ParametroNormativoDto?>(item);
    }
    public Task<ParametroNormativoDto?> CambiarEstadoAsync(int id, bool activo)
    {
        var i = Items.FindIndex(p => p.Id == id); if (i < 0) return Task.FromResult<ParametroNormativoDto?>(null);
        Items[i] = Items[i] with { Activo = activo }; return Task.FromResult<ParametroNormativoDto?>(Items[i]);
    }
}

public class MockRutaRepository : IRutaRepository
{
    private static readonly List<RutaAsignadaResponseDto> Rutas = [];
    private static int _nextAsignacion = 100;

    public Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request)
    {
        var id = Interlocked.Increment(ref _nextAsignacion);
        var nombreTecnico = request.IdUsuarioTecnico switch
        {
            1 => "Juan Pérez García",
            2 => "Pedro Encargado López",
            4 => "Luis Mamani Condori",
            _ => $"Técnico #{request.IdUsuarioTecnico}"
        };

        var detalles = request.Detalles.Select((d, i) => new DetalleRutaResponseDto(
            Id: id * 100 + i + 1,
            SolicitudId: d.SolicitudId,
            TipoOrigen: d.TipoOrigen,
            OrdenVisita: d.OrdenVisita,
            Estado: "Pendiente",
            NombreCliente: d.NombreCliente,
            Direccion: d.Direccion,
            Latitud: d.Latitud,
            Longitud: d.Longitud,
            EsUrgente: d.TipoOrigen == "ODECO",
            CodCon: 100 + i,
            NumeroMedidor: $"1420{i:0000}")).ToList();

        var ruta = new RutaAsignadaResponseDto(
            IdAsignacion: id,
            IdUsuarioTecnico: request.IdUsuarioTecnico,
            NombreTecnico: nombreTecnico,
            FechaAsignacion: request.FechaAsignacion,
            Estado: "Planificado",
            TotalParadas: detalles.Count,
            Detalles: detalles);

        Rutas.Add(ruta);
        return Task.FromResult(ruta);
    }

    public Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(int idTecnico, DateTime? fecha = null)
    {
        var fechaFiltro = fecha?.Date ?? DateTime.Today;
        var delTecnico = Rutas
            .Where(r => r.IdUsuarioTecnico == idTecnico && r.FechaAsignacion.Date == fechaFiltro)
            .ToList();
        return Task.FromResult(new RutasTecnicoResponseDto(delTecnico));
    }

    public Task<RutaAsignadaResponseDto?> ObtenerActualPorTecnicoAsync(int idTecnico)
    {
        var hoy = DateTime.Today;
        var actual = Rutas
            .Where(r => r.IdUsuarioTecnico == idTecnico
                        && r.FechaAsignacion.Date == hoy
                        && !string.Equals(r.Estado, "Cancelado", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(r => r.IdAsignacion)
            .FirstOrDefault();

        actual ??= Rutas
            .Where(r => r.IdUsuarioTecnico == idTecnico
                        && !string.Equals(r.Estado, "Finalizado", StringComparison.OrdinalIgnoreCase)
                        && !string.Equals(r.Estado, "Cancelado", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(r => r.FechaAsignacion)
            .ThenByDescending(r => r.IdAsignacion)
            .FirstOrDefault();

        return Task.FromResult(actual);
    }

    public Task<RutasTecnicoResponseDto> ObtenerActivasAsync(DateTime? fecha = null)
    {
        var dia = (fecha ?? DateTime.Today).Date;
        var activas = Rutas
            .Where(r => r.FechaAsignacion.Date == dia
                        && !string.Equals(r.Estado, "Cancelado", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(r => r.IdAsignacion)
            .ToList();
        return Task.FromResult(new RutasTecnicoResponseDto(activas));
    }

    public Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(int idAsignacion) =>
        Task.FromResult(Rutas.FirstOrDefault(r => r.IdAsignacion == idAsignacion));
}

public class MockSincronizacionRepository : ISincronizacionRepository
{
    public Task<SincronizacionResponseDto> ProcesarCambiosAsync(SincronizacionRequestDto request)
    {
        var ids = new List<int>();
        var errores = 0;
        foreach (var ej in request.Ejecuciones)
        {
            try
            {
                ids.Add(Random.Shared.Next(6000, 9999));
            }
            catch { errores++; }
        }

        var resultados = request.Ejecuciones.Select((ej, index) => new SincronizacionItemResultadoDto(
            ej.TipoOrigen, ej.IdOrigen, true, index < ids.Count ? ids[index] : null, false, null)).ToList();

        return Task.FromResult(new SincronizacionResponseDto(
            TotalRecibidos: request.Ejecuciones.Count,
            ProcesadosOk: request.Ejecuciones.Count - errores,
            Errores: errores,
            IdsEjecucion: ids,
            Mensaje: $"{ids.Count} ejecuciones sincronizadas correctamente.",
            Resultados: resultados));
    }
}


public sealed class MockAdminRepository : IAdminRepository
{
    private static readonly DateTime Today = DateTime.Today;

    private static readonly List<AdminSolicitudDto> Solicitudes =
    [
        new("ODECO-1042", "ODECO", Today.AddHours(8), Today.AddHours(20), false, 0, 100234, "Maria Elena Vargas", "Av. Las Americas #452", "Fuga interna no visible", "Alta", "Asignada", 1, "Juan Perez Garcia", "M-789012", "SAG", null, null, null, null, false),
        new("ODECO-1043", "ODECO", Today.AddDays(-2).AddHours(9), Today.AddDays(-1).AddHours(9), true, 2, 100567, "Carlos Mendoza Rios", "Calle Junin #890", "Medidor destrozado", "Alta", "Pendiente", null, null, "M-456789", "Elster", null, null, null, null, false),
        new("LEC-201", "LECTURA", Today.AddDays(-5), new DateTime(Today.Year, Today.Month, 1).AddMonths(1), false, 5, 100891, "Ana Lucia Fernandez", "Pasaje Los Olivos #23", "Posible fuga despues del medidor", "Normal", "En proceso", 4, "Luis Mamani Condori", "M-123456", "SAG", 890.3m, 1250.7m, 360.4m, null, false),
        new("LEC-203", "LECTURA", Today.AddDays(-1), new DateTime(Today.Year, Today.Month, 1).AddMonths(1), false, 1, 101200, "Roberto Sanchez Perez", "Av. Heroinas #1567", "Medidor empanado", "Normal", "Completada", 1, "Juan Perez Garcia", "M-334455", "SAG", 456.2m, 458.1m, 1.9m, Today.AddHours(10), true)
    ];

    private static readonly List<AdminRutaDto> Rutas =
    [
        new(1247, 1, "Juan Perez Garcia", Today.AddHours(8), "EnCurso", 4, 2, 2, 50m, Today.AddHours(10),
        [
            new(1, 1, "ODECO-1042", "ODECO", "Maria Elena Vargas", "Av. Las Americas #452", -21.53, -64.72, "Completada", true, Today.AddHours(9)),
            new(2, 2, "LEC-203", "LECTURA", "Roberto Sanchez Perez", "Av. Heroinas #1567", -21.54, -64.73, "Completada", true, Today.AddHours(10)),
            new(3, 3, "ODECO-1043", "ODECO", "Carlos Mendoza Rios", "Calle Junin #890", null, null, "Pendiente", false, null),
            new(4, 4, "LEC-201", "LECTURA", "Ana Lucia Fernandez", "Pasaje Los Olivos #23", null, null, "Pendiente", false, null)
        ]),
        new(1248, 4, "Luis Mamani Condori", Today.AddHours(8.5), "Planificado", 3, 0, 3, 0m, null,
        [
            new(5, 1, "LEC-210", "LECTURA", "Cliente Demo 1", "Zona Norte", null, null, "Pendiente", false, null),
            new(6, 2, "LEC-211", "LECTURA", "Cliente Demo 2", "Zona Norte", null, null, "Pendiente", false, null),
            new(7, 3, "ODECO-1050", "ODECO", "Cliente Demo 3", "Zona Norte", null, null, "Pendiente", false, null)
        ])
    ];

    private static readonly List<AdminVerificacionResumenDto> Verificaciones =
    [
        new(45, "ODECO", "1042", 100234, "Maria Elena Vargas", "M-789012", Today.AddHours(9), 5, "Manuel Ortega Vega", "EnCurso", null, 0.4m, 120m, false, false, null, false),
        new(44, "ODECO", "1030", 100120, "Pedro Flores", "LAO-085399", Today.AddDays(-1).AddHours(11), 5, "Manuel Ortega Vega", "Completada", "CUMPLE", 0.4m, 120m, true, true, "INF-0044", true),
        new(43, "LECTURA", "198", 100110, "Maria Quispe", "SAG-554433", Today.AddDays(-2).AddHours(10), 5, "Manuel Ortega Vega", "Completada", "NO CUMPLE", 3.2m, 85m, false, true, "INF-0043", false)
    ];

    private static readonly List<AdminMovimientoDto> Movimientos =
    [
        new(5002, Today.AddHours(10), "LECTURA", "203", 101200, "Roberto Sanchez Perez", "Av. Heroinas #1567", "M-334455", "SAG", 458.1m, 1, "Reparacion", "M-998001", "Lao", "Cambio realizado sin novedad", "-21.53,-64.72", 1, "Juan Perez Garcia", true, 2,
        [new("MedidorRetirado", "/uploads/203/retirado.jpg"), new("MedidorNuevo", "/uploads/203/nuevo.jpg")]),
        new(5001, Today.AddDays(-1).AddHours(15), "ODECO", "1030", 100120, "Pedro Flores", "Calle Bolivar #100", "LAO-085399", "Lao", 3305.67m, 2, "Mantenimiento", "SAG-991100", "SAG", "Cambio por reclamo", null, 4, "Luis Mamani Condori", true, 1,
        [new("MedidorRetirado", "/uploads/1030/retirado.jpg")])
    ];


    private static readonly List<AdminMovimientoCorporativoDto> HistoricoCorporativo =
    [
        new(85108, 100234, "Maria Elena Vargas", "Av. Las Americas #452", "M-789012", "Lao", true, 1, "Reparacion", "Movimiento corporativo vigente de demostracion", 12045),
        new(74402, 100234, "Maria Elena Vargas", "Av. Las Americas #452", "M-445566", "Schlumberger", false, 2, "Mantenimiento", "Movimiento corporativo historico de demostracion", 9910),
        new(81221, 100120, "Pedro Flores", "Calle Bolivar #100", "LAO-085399", "Lao", true, 2, "Mantenimiento", null, null)
    ];
    public Task<AdminDashboardDto> ObtenerDashboardAsync(DateTime? desde = null, DateTime? hasta = null)
    {
        var sync = CrearSync();
        var dashboard = new AdminDashboardDto(
            SolicitudesPendientes: Solicitudes.Count(s => s.Estado != "Completada"),
            OdecoPendientes: Solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Estado != "Completada"),
            OdecoUrgentes: Solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Prioridad == "Alta" && s.Estado != "Completada"),
            OdecoVencidas: Solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Vencida && s.Estado != "Completada"),
            LecturaPendientes: Solicitudes.Count(s => s.TipoOrigen == "LECTURA" && s.Estado != "Completada"),
            RutasActivasHoy: Rutas.Count(r => r.Estado != "Completada"),
            TecnicosConRutaHoy: Rutas.Select(r => r.IdTecnico).Distinct().Count(),
            CambiosEjecutadosHoy: Movimientos.Count(m => m.FechaHora.Date == Today),
            CambiosSincronizadosHoy: Movimientos.Count(m => m.FechaHora.Date == Today && m.Sincronizado),
            VerificacionesPendientes: Verificaciones.Count(v => v.Estado == "Pendiente"),
            VerificacionesEnCurso: Verificaciones.Count(v => v.Estado == "EnCurso"),
            VerificacionesCompletadas: Verificaciones.Count(v => v.Estado == "Completada"),
            VerificacionesCumple: Verificaciones.Count(v => v.Resultado == "CUMPLE"),
            VerificacionesNoCumple: Verificaciones.Count(v => v.Resultado == "NO CUMPLE"),
            SolicitudesPorEstado: Solicitudes.GroupBy(s => s.Estado).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).ToList(),
            MotivosCambioFrecuentes: Movimientos.GroupBy(m => m.Motivo).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).ToList(),
            Tecnicos: sync.Select(s => new AdminTecnicoResumenDto(s.IdTecnico, s.NombreTecnico, s.Activo, s.RutasHoy, s.ParadasHoy, s.ParadasCompletadasHoy, s.ParadasHoy == 0 ? 0 : (decimal)s.ParadasCompletadasHoy * 100m / s.ParadasHoy, s.UltimaEjecucionRecibida, s.EstadoServidor)).ToList(),
            ActividadReciente:
            [
                new(Today.AddHours(10), "CAMBIO", "Cambio #5002", "LEC-203 por Juan Perez Garcia", "Sincronizado"),
                new(Today.AddHours(9), "VERIFICACION", "Verificacion #45", "CodCon 100234", "EnCurso")
            ],
            Alertas:
            [
                new("ODECO", "Critica", "ODECO vencidas", "Solicitudes que superaron el plazo.", 1)
            ]);
        return Task.FromResult(dashboard);
    }

    public Task<PagedResultDto<AdminSolicitudDto>> ObtenerSolicitudesAsync(AdminSolicitudFiltro filtro)
    {
        IEnumerable<AdminSolicitudDto> items = Solicitudes;
        if (filtro.Desde.HasValue) items = items.Where(x => x.FechaSolicitud >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue) items = items.Where(x => x.FechaSolicitud < filtro.Hasta.Value.Date.AddDays(1));
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && !filtro.Origen.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            items = items.Where(x => x.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            items = filtro.Estado.Equals("Vencida", StringComparison.OrdinalIgnoreCase)
                ? items.Where(x => x.Vencida && x.Estado != "Completada")
                : items.Where(x => x.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Prioridad) && !filtro.Prioridad.Equals("Todas", StringComparison.OrdinalIgnoreCase))
            items = items.Where(x => x.Prioridad.Equals(filtro.Prioridad, StringComparison.OrdinalIgnoreCase));
        if (filtro.TecnicoId.HasValue) items = items.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            items = items.Where(x =>
                x.Id.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.Direccion.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (x.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (x.Motivo?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false));
        }
        return Task.FromResult(Paginar(items.OrderByDescending(x => x.Vencida).ThenByDescending(x => x.FechaSolicitud).ToList(), filtro.Page, filtro.PageSize));
    }

    public Task<PagedResultDto<AdminRutaDto>> ObtenerRutasAsync(AdminRutaFiltro filtro)
    {
        IEnumerable<AdminRutaDto> items = Rutas;
        if (filtro.Fecha.HasValue) items = items.Where(x => x.FechaAsignacion.Date == filtro.Fecha.Value.Date);
        if (filtro.TecnicoId.HasValue) items = items.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            items = items.Where(x => x.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            items = items.Where(x =>
                x.IdAsignacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NombreTecnico.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.Detalles.Any(d => d.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) || d.Direccion.Contains(q, StringComparison.OrdinalIgnoreCase)));
        }
        return Task.FromResult(Paginar(items.OrderByDescending(x => x.FechaAsignacion).ToList(), filtro.Page, filtro.PageSize));
    }

    public Task<AdminRutaDto?> ObtenerRutaAsync(int idAsignacion) => Task.FromResult(Rutas.FirstOrDefault(x => x.IdAsignacion == idAsignacion));

    public Task<IReadOnlyList<AdminSincronizacionTecnicoDto>> ObtenerSincronizacionAsync(DateTime? fecha = null) => Task.FromResult<IReadOnlyList<AdminSincronizacionTecnicoDto>>(CrearSync());

    public Task<PagedResultDto<AdminVerificacionResumenDto>> ObtenerVerificacionesAsync(AdminVerificacionFiltro filtro)
    {
        IEnumerable<AdminVerificacionResumenDto> items = Verificaciones;
        if (filtro.Desde.HasValue) items = items.Where(x => x.Fecha >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue) items = items.Where(x => x.Fecha < filtro.Hasta.Value.Date.AddDays(1));
        if (filtro.MecanicoId.HasValue) items = items.Where(x => x.IdMecanico == filtro.MecanicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            items = items.Where(x => x.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Resultado) && !filtro.Resultado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            items = items.Where(x => string.Equals(x.Resultado, filtro.Resultado, StringComparison.OrdinalIgnoreCase));
        if (filtro.SoloConInforme == true) items = items.Where(x => x.TieneInforme);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            items = items.Where(x =>
                x.IdVerificacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (x.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                x.NombreMecanico.Contains(q, StringComparison.OrdinalIgnoreCase));
        }
        return Task.FromResult(Paginar(items.OrderByDescending(x => x.Fecha).ToList(), filtro.Page, filtro.PageSize));
    }

    public Task<IReadOnlyList<AdminVerificacionResumenDto>> ObtenerVerificacionesExportAsync(AdminVerificacionFiltro filtro, int maximo = 50000)
    {
        IEnumerable<AdminVerificacionResumenDto> items = Verificaciones;
        if (filtro.Desde.HasValue) items = items.Where(x => x.Fecha >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue) items = items.Where(x => x.Fecha < filtro.Hasta.Value.Date.AddDays(1));
        if (filtro.MecanicoId.HasValue) items = items.Where(x => x.IdMecanico == filtro.MecanicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && filtro.Estado != "Todos") items = items.Where(x => x.Estado == filtro.Estado);
        if (!string.IsNullOrWhiteSpace(filtro.Resultado) && filtro.Resultado != "Todos") items = items.Where(x => x.Resultado == filtro.Resultado);
        if (filtro.SoloConInforme == true) items = items.Where(x => x.TieneInforme);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            items = items.Where(x =>
                x.IdVerificacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (x.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                x.NombreMecanico.Contains(q, StringComparison.OrdinalIgnoreCase));
        }
        return Task.FromResult<IReadOnlyList<AdminVerificacionResumenDto>>(items.OrderByDescending(x => x.Fecha).Take(Math.Clamp(maximo, 1, 50000)).ToList());
    }

    public Task<AdminVerificacionDetalleDto?> ObtenerVerificacionDetalleAsync(int idVerificacion)
    {
        var r = Verificaciones.FirstOrDefault(x => x.IdVerificacion == idVerificacion);
        if (r is null) return Task.FromResult<AdminVerificacionDetalleDto?>(null);
        var detalle = new AdminVerificacionDetalleDto(
            r,
            new DatosSocioMedidorDto(r.CodCon, r.NombreCliente, "Direccion de demostracion", "Domestica", null, null, null, r.NumeroMedidor, "Lao", Today.AddYears(-5)),
            new EnsayoVerificacionDto(1, "Banco portatil 10 litros", 1000m, 1010m, 10m, r.Caudal, 10m, r.Error, r.Fugas, "Ensayo de demostracion"),
            [new ParticipanteVerificacionDto(1, r.NombreMecanico, "Mecanico", "Tecnico"), new ParticipanteVerificacionDto(2, r.NombreCliente, null, "Usuario")],
            r.TieneInforme ? [new AdminInformeVerificacionDto(1, r.NroInforme ?? "INF-DEMO", r.Fecha.AddMinutes(30), r.InformeFirmado ? r.Fecha.AddHours(1) : null, null, r.InformeFirmado, 0)] : []);
        return Task.FromResult<AdminVerificacionDetalleDto?>(detalle);
    }

    public Task<PagedResultDto<AdminMovimientoDto>> ObtenerMovimientosAsync(AdminMovimientoFiltro filtro)
    {
        var items = FiltrarMovimientos(filtro).ToList();
        return Task.FromResult(Paginar(items, filtro.Page, filtro.PageSize));
    }

    public Task<IReadOnlyList<AdminMovimientoDto>> ObtenerMovimientosExportAsync(AdminMovimientoFiltro filtro, int maximo = 50000) =>
        Task.FromResult<IReadOnlyList<AdminMovimientoDto>>(FiltrarMovimientos(filtro).Take(maximo).ToList());

    public Task<PagedResultDto<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoAsync(AdminMovimientoCorporativoFiltro filtro)
    {
        var items = FiltrarHistoricoCorporativo(filtro).ToList();
        return Task.FromResult(Paginar(items, filtro.Page, filtro.PageSize));
    }

    public Task<IReadOnlyList<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoExportAsync(AdminMovimientoCorporativoFiltro filtro, int maximo = 50000) =>
        Task.FromResult<IReadOnlyList<AdminMovimientoCorporativoDto>>(FiltrarHistoricoCorporativo(filtro).Take(Math.Clamp(maximo, 1, 50000)).ToList());

    public Task<AdminEstadisticasDto> ObtenerEstadisticasAsync(AdminEstadisticasFiltro filtro)
    {
        var desde = filtro.Desde?.Date ?? Today.AddDays(-30);
        var hastaExclusiva = (filtro.Hasta?.Date ?? Today).AddDays(1);

        IEnumerable<AdminMovimientoDto> movQuery = Movimientos.Where(m => m.FechaHora >= desde && m.FechaHora < hastaExclusiva);
        if (filtro.TecnicoId.HasValue) movQuery = movQuery.Where(m => m.IdTecnico == filtro.TecnicoId.Value);
        if (filtro.MotivoId.HasValue) movQuery = movQuery.Where(m => m.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && !filtro.Origen.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            movQuery = movQuery.Where(m => m.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Marca))
        {
            var marca = filtro.Marca.Trim();
            movQuery = movQuery.Where(m =>
                (m.MarcaRetirado?.Contains(marca, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (m.MarcaInstalado?.Contains(marca, StringComparison.OrdinalIgnoreCase) ?? false));
        }
        var movs = movQuery.ToList();

        IEnumerable<AdminVerificacionResumenDto> verQuery = Verificaciones.Where(v => v.Fecha >= desde && v.Fecha < hastaExclusiva);
        if (filtro.MecanicoId.HasValue) verQuery = verQuery.Where(v => v.IdMecanico == filtro.MecanicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && !filtro.Origen.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            verQuery = verQuery.Where(v => v.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        var vers = verQuery.ToList();

        var cumple = vers.Count(v => v.Resultado == "CUMPLE");
        var noCumple = vers.Count(v => v.Resultado == "NO CUMPLE");
        var conResultado = cumple + noCumple;
        var errores = vers.Where(v => v.Error.HasValue).Select(v => v.Error!.Value).ToList();

        var result = new AdminEstadisticasDto(
            movs.Count,
            vers.Count,
            cumple,
            noCumple,
            conResultado == 0 ? 0 : Math.Round((decimal)cumple * 100m / conResultado, 1),
            vers.Count(v => v.Fugas == true),
            errores.Count == 0 ? null : Math.Round(errores.Average(), 3),
            movs.Count == 0 ? null : 18.5m,
            movs.GroupBy(m => m.Motivo).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList(),
            movs.GroupBy(m => m.MarcaRetirado ?? "Sin marca").Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList(),
            movs.GroupBy(m => m.TipoOrigen).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList(),
            movs.GroupBy(m => m.FechaHora.Date).OrderBy(g => g.Key).Select(g => new AdminSerieTemporalDto(g.Key.ToString("yyyy-MM-dd"), g.Count())).ToList(),
            movs.GroupBy(m => new { m.IdTecnico, m.NombreTecnico }).Select(g => new AdminPersonaMetricaDto(g.Key.IdTecnico, g.Key.NombreTecnico, "tecnico", g.Count(), null, 0, 0)).OrderByDescending(x => x.Atenciones).ToList(),
            vers.GroupBy(v => new { v.IdMecanico, v.NombreMecanico }).Select(g =>
            {
                var errs = g.Where(v => v.Error.HasValue).Select(v => v.Error!.Value).ToList();
                return new AdminPersonaMetricaDto(
                    g.Key.IdMecanico,
                    g.Key.NombreMecanico,
                    "mecanico",
                    g.Count(),
                    errs.Count == 0 ? null : Math.Round(errs.Average(), 3),
                    g.Count(v => v.Resultado == "CUMPLE"),
                    g.Count(v => v.Resultado == "NO CUMPLE"));
            }).OrderByDescending(x => x.Atenciones).ToList());
        return Task.FromResult(result);
    }

    private static List<AdminSincronizacionTecnicoDto> CrearSync() =>
    [
        new(1, "Juan Perez Garcia", true, 1, 4, 2, 2, 2, 0, 0, 0, 0, Today.AddHours(10), "En curso", "Estado conocido por el servidor."),
        new(4, "Luis Mamani Condori", true, 1, 3, 0, 0, 0, 0, 0, 0, 0, null, "Sin actividad", "Estado conocido por el servidor.")
    ];

    private static IEnumerable<AdminMovimientoDto> FiltrarMovimientos(AdminMovimientoFiltro filtro)
    {
        IEnumerable<AdminMovimientoDto> items = Movimientos;
        if (filtro.Desde.HasValue) items = items.Where(x => x.FechaHora >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue) items = items.Where(x => x.FechaHora < filtro.Hasta.Value.Date.AddDays(1));
        if (filtro.TecnicoId.HasValue) items = items.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (filtro.MotivoId.HasValue) items = items.Where(x => x.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && filtro.Origen != "Todos") items = items.Where(x => x.TipoOrigen == filtro.Origen);
        if (!string.IsNullOrWhiteSpace(filtro.Marca)) items = items.Where(x => (x.MarcaRetirado?.Contains(filtro.Marca, StringComparison.OrdinalIgnoreCase) ?? false) || (x.MarcaInstalado?.Contains(filtro.Marca, StringComparison.OrdinalIgnoreCase) ?? false));
        if (filtro.Sincronizado.HasValue) items = items.Where(x => x.Sincronizado == filtro.Sincronizado.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar)) items = items.Where(x => x.NombreCliente.Contains(filtro.Buscar, StringComparison.OrdinalIgnoreCase) || x.CodCon.ToString().Contains(filtro.Buscar));
        return items.OrderByDescending(x => x.FechaHora);
    }

    private static IEnumerable<AdminMovimientoCorporativoDto> FiltrarHistoricoCorporativo(AdminMovimientoCorporativoFiltro filtro)
    {
        IEnumerable<AdminMovimientoCorporativoDto> items = HistoricoCorporativo;
        if (filtro.CodCon.HasValue) items = items.Where(x => x.CodCon == filtro.CodCon.Value);
        if (filtro.Vigente.HasValue) items = items.Where(x => x.Vigente == filtro.Vigente.Value);
        if (filtro.MotivoId.HasValue) items = items.Where(x => x.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Marca)) items = items.Where(x => x.Marca?.Contains(filtro.Marca, StringComparison.OrdinalIgnoreCase) == true);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            items = items.Where(x =>
                x.CodCaMe.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                x.NumeroMedidor.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (x.Marca?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (x.Motivo?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false));
        }
        return items.OrderByDescending(x => x.Vigente).ThenByDescending(x => x.CodCaMe);
    }

    private static PagedResultDto<T> Paginar<T>(IReadOnlyList<T> items, int page, int pageSize)
    {
        page = Math.Max(1, page); pageSize = Math.Clamp(pageSize, 5, 100);
        var total = items.Count;
        var data = items.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return new PagedResultDto<T>(data, page, pageSize, total, total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize));
    }
}
