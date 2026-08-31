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
        new() { Id = 1, CodFunCorporativo = 1001, NombreUsuario = "tecnico1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 1, Nombre = "tecnico" },
                Funcionario = new Funcionario { CodFun = 1001, CodPer = 1,
                    Persona = new Persona { NomPer = "Juan", PriApePer = "Pérez", SegApePer = "García" } } },
        new() { Id = 2, CodFunCorporativo = 1002, NombreUsuario = "asignador1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 2, Nombre = "asignador" },
                Funcionario = new Funcionario { CodFun = 1002, CodPer = 2,
                    Persona = new Persona { NomPer = "Pedro", PriApePer = "Encargado", SegApePer = "López" } } },
        new() { Id = 3, CodFunCorporativo = 1003, NombreUsuario = "admin", HashPassword = "admin123", Activo = true,
                Rol = new RolApp { IdRol = 3, Nombre = "administrador" },
                Funcionario = new Funcionario { CodFun = 1003, CodPer = 3,
                    Persona = new Persona { NomPer = "Administrador", PriApePer = "COSAALT" } } },
        new() { Id = 4, CodFunCorporativo = 1004, NombreUsuario = "tecnico2", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 1, Nombre = "tecnico" },
                Funcionario = new Funcionario { CodFun = 1004, CodPer = 4,
                    Persona = new Persona { NomPer = "Luis", PriApePer = "Mamani", SegApePer = "Condori" } } },
        new() { Id = 5, CodFunCorporativo = null, NombreUsuario = "mecanico1", HashPassword = "123456", Activo = true,
                Rol = new RolApp { IdRol = 4, Nombre = "mecanico" } }
    ];

    public Task<LoginResponseDto?> LoginAsync(string usuario, string contrasena)
    {
        var user = Usuarios.FirstOrDefault(u =>
            u.NombreUsuario.Equals(usuario, StringComparison.OrdinalIgnoreCase) &&
            u.HashPassword == contrasena && u.Activo);

        if (user is null) return Task.FromResult<LoginResponseDto?>(null);

        var token = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));
        return Task.FromResult<LoginResponseDto?>(new LoginResponseDto(user.Id, user.NombreCompleto, user.Rol.Nombre, token));
    }
}

public class MockCatalogoRepository : ICatalogoRepository
{
    private static readonly List<MotivoCambioDto> Motivos =
    [
        new(1, "Reparacion"), new(2, "Mantenimiento"), new(3, "Fuga")
    ];

    private static readonly List<MarcaMedidorDto> Marcas =
    [
        new(1, "SAG", "SAG"), new(2, "Elster", "ELS"), new(3, "LAO", "LAO"), new(4, "Itron", "ITR")
    ];

    public Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync() =>
        Task.FromResult<IReadOnlyList<MotivoCambioDto>>(Motivos);

    public Task<IReadOnlyList<MarcaMedidorDto>> ObtenerMarcasAsync() =>
        Task.FromResult<IReadOnlyList<MarcaMedidorDto>>(Marcas);
}

public class MockEjecucionRepository : IEjecucionRepository
{
    private static int _nextId = 5000;

    public Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request)
    {
        var id = Interlocked.Increment(ref _nextId);
        return Task.FromResult(new EjecucionCambioResponseDto(id, "Ejecución registrada.", true));
    }

    public Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null)
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

        return Task.FromResult<IReadOnlyList<EjecucionHistorialDto>>(historial);
    }
}

public class MockUsuarioRepository : IUsuarioRepository
{
    private static int _nextId = 7;

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
        new(2, "Luis Mamani Condori", "tecnico2", "tecnico", 1, true, 1002, DateTime.Today.AddDays(-20)),
        new(5, "Ana Soliz Rueda", "asignador1", "asignador", 2, true, null, DateTime.Today.AddDays(-15)),
        new(6, "Rocio Flores Medina", "admin", "administrador", 3, true, null, DateTime.Today.AddDays(-10)),
        new(7, "Manuel Ortega Vega", "mecanico1", "mecanico", 4, true, null, DateTime.Today.AddDays(-5))
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

        return Task.FromResult(new SincronizacionResponseDto(
            TotalRecibidos: request.Ejecuciones.Count,
            ProcesadosOk: request.Ejecuciones.Count - errores,
            Errores: errores,
            IdsEjecucion: ids,
            Mensaje: $"{ids.Count} ejecuciones sincronizadas correctamente."));
    }
}

