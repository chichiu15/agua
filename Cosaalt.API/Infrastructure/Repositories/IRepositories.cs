using Cosaalt.API.Application.DTOs;

namespace Cosaalt.API.Infrastructure.Repositories;

public interface IAuthRepository
{
    Task<LoginResponseDto?> LoginAsync(string usuario, string contrasena);
}

public interface ICatalogoRepository
{
    Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync();
}

public interface ISolicitudRepository
{
    Task<SolicitudesResponseDto> ObtenerSolicitudesAsync(string? filtro = null);
    Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id);
}

public interface IEjecucionRepository
{
    Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request);
    Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null);
}

public interface IUsuarioRepository
{
    Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync();
    Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync();
    Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosActivosAsync();
}

public interface IRutaRepository
{
    Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request);
    Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(int idTecnico, DateTime? fecha = null);
    Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(int idAsignacion);
}

public interface ISincronizacionRepository
{
    Task<SincronizacionResponseDto> ProcesarCambiosAsync(SincronizacionRequestDto request);
}

public interface IVerificacionRepository
{
    Task<IReadOnlyList<SolicitudVerificacionDto>> ObtenerSolicitudesAsync();
    Task<TomarVerificacionResponseDto> TomarAsync(TomarVerificacionRequestDto request);
    Task<IReadOnlyList<VerificacionDto>> ObtenerVerificacionesAsync(int idMecanico);
    Task<VerificacionDto?> ObtenerVerificacionAsync(int id);
    Task<DatosSocioMedidorDto?> ObtenerDatosSocioMedidorAsync(int idVerificacion);
    Task<VerificacionDto?> GuardarEnsayoAsync(int idVerificacion, decimal? volumenRegistrado, decimal? error, GuardarEnsayoRequestDto request);
}
