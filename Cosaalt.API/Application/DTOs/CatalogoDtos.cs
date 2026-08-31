namespace Cosaalt.API.Application.DTOs;

public record MotivoCambioDto(int Id, string Descripcion, string? Detalle, bool Activo);
public record CatalogoMotivosResponseDto(IReadOnlyList<MotivoCambioDto> Motivos);
public record GuardarMotivoCambioRequestDto(string Nombre, string? Descripcion, bool Activo = true);
public record CambiarEstadoMotivoRequestDto(bool Activo);

public record MarcaMedidorDto(int Id, string Nombre, string? Alias);
public record CatalogoMarcasResponseDto(IReadOnlyList<MarcaMedidorDto> Marcas);
