namespace Cosaalt.API.Application.DTOs;

public record LoginRequestDto(string Usuario, string Contrasena);

public record LoginResponseDto(
    int IdUsuario,
    string NombreCompleto,
    string Rol,
    string Token);
