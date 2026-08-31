using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Repositories;

namespace Cosaalt.API.Application.Services;

public class AuthService
{
    private readonly IAuthRepository _repository;

    public AuthService(IAuthRepository repository) => _repository = repository;

    public Task<LoginResponseDto?> LoginAsync(LoginRequestDto request) =>
        _repository.LoginAsync(request.Usuario, request.Contrasena);
}

public class CatalogoService
{
    private readonly ICatalogoRepository _repository;

    public CatalogoService(ICatalogoRepository repository) => _repository = repository;

    public async Task<CatalogoMotivosResponseDto> ObtenerMotivosAsync()
    {
        var motivos = await _repository.ObtenerMotivosAsync();
        return new CatalogoMotivosResponseDto(motivos);
    }

    public async Task<CatalogoMarcasResponseDto> ObtenerMarcasAsync()
    {
        var marcas = await _repository.ObtenerMarcasAsync();
        return new CatalogoMarcasResponseDto(marcas);
    }
}

public class SolicitudService
{
    private readonly ISolicitudRepository _repository;

    public SolicitudService(ISolicitudRepository repository) => _repository = repository;

    public Task<SolicitudesResponseDto> ObtenerSolicitudesAsync(string? filtro = null) =>
        _repository.ObtenerSolicitudesAsync(filtro);

    public Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id) =>
        _repository.ObtenerPorIdAsync(id);
}

public class EjecucionService
{
    private readonly IEjecucionRepository _repository;

    public EjecucionService(IEjecucionRepository repository) => _repository = repository;

    public Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request) =>
        _repository.RegistrarAsync(request);

    public Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null) =>
        _repository.ObtenerHistorialAsync(codCon);
}

public class UsuarioService
{
    private readonly IUsuarioRepository _repository;

    public UsuarioService(IUsuarioRepository repository) => _repository = repository;

    public Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosAsync() =>
        _repository.ObtenerTecnicosActivosAsync();

    public Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync() =>
        _repository.ObtenerUsuariosAsync();

    public Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosAsync() =>
        _repository.ObtenerFuncionariosActivosAsync();

    public Task<IReadOnlyList<RolDto>> ObtenerRolesAsync() =>
        _repository.ObtenerRolesAsync();

    public Task<UsuarioDto> CrearAsync(CrearUsuarioRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.NombreUsuario))
            throw new ArgumentException("El nombre de usuario es obligatorio.");
        if (string.IsNullOrWhiteSpace(request.Contrasena))
            throw new ArgumentException("La contrasena es obligatoria al crear un usuario.");
        return _repository.CrearAsync(request);
    }

    public Task<UsuarioDto?> ActualizarAsync(int id, ActualizarUsuarioRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.NombreUsuario))
            throw new ArgumentException("El nombre de usuario es obligatorio.");
        return _repository.ActualizarAsync(id, request);
    }
}

public class ParametroNormativoService
{
    private readonly IParametroNormativoRepository _repository;

    public ParametroNormativoService(IParametroNormativoRepository repository) => _repository = repository;

    public Task<IReadOnlyList<ParametroNormativoDto>> ObtenerTodosAsync() => _repository.ObtenerTodosAsync();
    public Task<ParametroNormativoDto?> ObtenerPorIdAsync(int id) => _repository.ObtenerPorIdAsync(id);
    public Task<ParametroNormativoDto?> ObtenerVigenteAsync(decimal caudal, DateTime? fecha = null)
    {
        if (caudal < 0) throw new ArgumentException("El caudal no puede ser negativo.");
        return _repository.ObtenerVigenteAsync(caudal, fecha ?? DateTime.Now);
    }

    public Task<ParametroNormativoDto> CrearAsync(GuardarParametroNormativoRequestDto request)
    {
        Validar(request);
        return _repository.CrearAsync(request);
    }

    public Task<ParametroNormativoDto?> ActualizarAsync(int id, GuardarParametroNormativoRequestDto request)
    {
        Validar(request);
        return _repository.ActualizarAsync(id, request);
    }

    public Task<ParametroNormativoDto?> CambiarEstadoAsync(int id, bool activo) =>
        _repository.CambiarEstadoAsync(id, activo);

    private static void Validar(GuardarParametroNormativoRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo))
            throw new ArgumentException("El codigo es obligatorio.");
        if (request.ErrorMaxPermitido < 0)
            throw new ArgumentException("El error maximo permitido no puede ser negativo.");
        if (request.CaudalMin.HasValue && request.CaudalMin < 0)
            throw new ArgumentException("El caudal minimo no puede ser negativo.");
        if (request.CaudalMax.HasValue && request.CaudalMax < 0)
            throw new ArgumentException("El caudal maximo no puede ser negativo.");
        if (request.CaudalMin.HasValue && request.CaudalMax.HasValue && request.CaudalMin > request.CaudalMax)
            throw new ArgumentException("El caudal minimo no puede ser mayor al caudal maximo.");
        if (request.VigenciaInicio.HasValue && request.VigenciaFin.HasValue && request.VigenciaInicio > request.VigenciaFin)
            throw new ArgumentException("La fecha de inicio no puede ser posterior a la fecha de fin.");
    }
}

public class RutaService
{
    private readonly IRutaRepository _repository;

    public RutaService(IRutaRepository repository) => _repository = repository;

    public Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request) =>
        _repository.AsignarAsync(request);

    public Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(int idTecnico, DateTime? fecha = null) =>
        _repository.ObtenerPorTecnicoAsync(idTecnico, fecha);

    public Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(int id) =>
        _repository.ObtenerPorIdAsync(id);
}

public class SincronizacionService
{
    private readonly ISincronizacionRepository _repository;

    public SincronizacionService(ISincronizacionRepository repository) => _repository = repository;

    public Task<SincronizacionResponseDto> ProcesarCambiosAsync(SincronizacionRequestDto request) =>
        _repository.ProcesarCambiosAsync(request);
}

public class VerificacionService
{
    private readonly IVerificacionRepository _repository;

    public VerificacionService(IVerificacionRepository repository) => _repository = repository;

    public Task<IReadOnlyList<SolicitudVerificacionDto>> ObtenerSolicitudesAsync() =>
        _repository.ObtenerSolicitudesAsync();

    public Task<TomarVerificacionResponseDto> TomarAsync(TomarVerificacionRequestDto request) =>
        _repository.TomarAsync(request);

    public Task<IReadOnlyList<VerificacionDto>> ObtenerVerificacionesAsync(int idMecanico) =>
        _repository.ObtenerVerificacionesAsync(idMecanico);

    public Task<VerificacionDto?> ObtenerVerificacionAsync(int id) =>
        _repository.ObtenerVerificacionAsync(id);

    public Task<DatosSocioMedidorDto?> ObtenerDatosSocioMedidorAsync(int idVerificacion) =>
        _repository.ObtenerDatosSocioMedidorAsync(idVerificacion);

    public async Task<EnsayoGuardadoResponseDto> GuardarEnsayoAsync(
        int idVerificacion,
        GuardarEnsayoRequestDto request)
    {
        var volumenRegistrado = CalcularVolumen(request);
        var error = CalcularError(request, volumenRegistrado);

        var actualizada = await _repository.GuardarEnsayoAsync(
            idVerificacion, volumenRegistrado, error, request);

        return new EnsayoGuardadoResponseDto(
            IdVerificacion: idVerificacion,
            IdEnsayo: actualizada?.Ensayo?.Id,
            VolumenRegistrado: volumenRegistrado,
            Error: error,
            Mensaje: "Ensayo guardado correctamente.");
    }

    private static decimal? CalcularVolumen(GuardarEnsayoRequestDto request)
    {
        if (request.LecturaInicial is null || request.LecturaFinal is null)
            return null;
        return request.LecturaFinal.Value - request.LecturaInicial.Value;
    }

    private static decimal? CalcularError(GuardarEnsayoRequestDto request, decimal? volumenRegistrado)
    {
        if (volumenRegistrado is null
            || request.VolumenPatron is null
            || request.VolumenPatron.Value == 0)
            return null;

        // |volumen medido - volumen patrón| / volumen patrón * 100
        var diff = Math.Abs(volumenRegistrado.Value - request.VolumenPatron.Value);
        return diff / request.VolumenPatron.Value * 100m;
    }
}
