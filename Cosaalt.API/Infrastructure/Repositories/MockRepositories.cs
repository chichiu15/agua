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
                    Persona = new Persona { NomPer = "Luis", PriApePer = "Mamani", SegApePer = "Condori" } } }
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
        new(1,"Empañado"), new(2,"Destrozado"), new(3,"Roto"), new(4,"Descalibrado"),
        new(5,"Antiguo"), new(6,"Parado"), new(7,"Otro")
    ];

    public Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync() =>
        Task.FromResult<IReadOnlyList<MotivoCambioDto>>(Motivos);
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
    private static readonly List<TecnicoDto> Tecnicos =
    [
        new(1, "Juan Pérez García", "tecnico", true, false),
        new(2, "Luis Mamani Condori", "tecnico", true, false),
        new(3, "Carlos Rojas Mendoza", "tecnico", false, true),
        new(4, "Miguel Ángel Torres", "tecnico", true, false)
    ];

    public Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync() =>
        Task.FromResult<IReadOnlyList<TecnicoDto>>(Tecnicos);

    public Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync()
    {
        UsuarioDto[] usuarios =
        [
            new(1, "Juan Pérez García", "tecnico", true, null),
            new(2, "Luis Mamani Condori", "tecnico", true, null),
            new(3, "Carlos Rojas Mendoza", "tecnico", false, null),
            new(4, "Miguel Ángel Torres", "tecnico", true, null),
            new(5, "Ana Soliz Rueda", "asignador", true, null),
            new(6, "Rocío Flores Medina", "administrador", true, null),
            new(7, "Manuel Ortega Vega", "mecanico", true, null)
        ];
        return Task.FromResult<IReadOnlyList<UsuarioDto>>(usuarios);
    }

    public Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosActivosAsync()
    {
        FuncionarioDto[] funcionarios =
        [
            new(125, "Jorge Vides Ortega", "JOVIOR", true),
            new(126, "Luis Gualberto Pecas Calla", "LGPECA", true),
            new(130, "Willan Mario Alfaro Tejerina", "WMALTE", false)
        ];
        return Task.FromResult<IReadOnlyList<FuncionarioDto>>(funcionarios);
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

