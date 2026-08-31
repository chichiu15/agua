namespace Cosaalt.API.Application.DTOs;

public record MotivoCambioDto(int Id, string Descripcion);
public record CatalogoMotivosResponseDto(IReadOnlyList<MotivoCambioDto> Motivos);

public record MarcaMedidorDto(int Id, string Nombre, string? Alias);
public record CatalogoMarcasResponseDto(IReadOnlyList<MarcaMedidorDto> Marcas);
