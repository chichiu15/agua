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
