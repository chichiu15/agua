namespace Cosaalt.API.Application.DTOs;

public record MotivoCambioDto(int Id, string Descripcion);

public record CatalogoMotivosResponseDto(IReadOnlyList<MotivoCambioDto> Motivos);
