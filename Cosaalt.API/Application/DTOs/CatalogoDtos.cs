namespace Cosaalt.API.Application.DTOs;

public record MotivoCambioDto(int Id, string Descripcion, string? Detalle, bool Activo);
public record CatalogoMotivosResponseDto(IReadOnlyList<MotivoCambioDto> Motivos);
public record GuardarMotivoCambioRequestDto(string Nombre, string? Descripcion, bool Activo = true);
public record CambiarEstadoMotivoRequestDto(bool Activo);

public record MarcaMedidorDto(int Id, string Nombre, string? Alias, bool Activo = true, string? Codigo = null);
public record CatalogoMarcasResponseDto(IReadOnlyList<MarcaMedidorDto> Marcas);
public record GuardarMarcaMedidorRequestDto(string Codigo, string Nombre, string? Alias, bool Activo = true);

public record MedidorDisponibleDto(
    int CodMedidor,
    string Serie,
    string Marca,
    string? Tipo,
    string? Capacidad,
    string? Diametro,
    int? CodigoEstado,
    string? Estado,
    string Disponibilidad);
