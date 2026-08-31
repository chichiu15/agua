using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlParametroNormativoRepository : IParametroNormativoRepository
{
    private readonly CosaaltDbContext _context;

    public SqlParametroNormativoRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<ParametroNormativoDto>> ObtenerTodosAsync()
    {
        var items = await _context.ParametrosNormativos.AsNoTracking()
            .OrderByDescending(p => p.Activo)
            .ThenBy(p => p.CaudalMin)
            .ThenBy(p => p.Codigo)
            .ToListAsync();
        return items.Select(Map).ToList();
    }

    public async Task<ParametroNormativoDto?> ObtenerPorIdAsync(int id)
    {
        var item = await _context.ParametrosNormativos.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
        return item is null ? null : Map(item);
    }

    public async Task<ParametroNormativoDto?> ObtenerVigenteAsync(decimal caudal, DateTime fecha)
    {
        var item = await _context.ParametrosNormativos.AsNoTracking()
            .Where(p => p.Activo
                && (p.VigenciaInicio == null || p.VigenciaInicio <= fecha)
                && (p.VigenciaFin == null || p.VigenciaFin >= fecha)
                && (p.CaudalMin == null || p.CaudalMin <= caudal)
                && (p.CaudalMax == null || p.CaudalMax >= caudal))
            .OrderByDescending(p => p.VigenciaInicio)
            .ThenByDescending(p => p.CaudalMin)
            .FirstOrDefaultAsync();
        return item is null ? null : Map(item);
    }

    public async Task<ParametroNormativoDto> CrearAsync(GuardarParametroNormativoRequestDto request)
    {
        await ValidarCodigoAsync(request.Codigo, null);
        var entity = new ParametroNormativo();
        Aplicar(entity, request);
        _context.ParametrosNormativos.Add(entity);
        await _context.SaveChangesAsync();
        return Map(entity);
    }

    public async Task<ParametroNormativoDto?> ActualizarAsync(int id, GuardarParametroNormativoRequestDto request)
    {
        var entity = await _context.ParametrosNormativos.FirstOrDefaultAsync(p => p.Id == id);
        if (entity is null) return null;
        await ValidarCodigoAsync(request.Codigo, id);
        Aplicar(entity, request);
        await _context.SaveChangesAsync();
        return Map(entity);
    }

    public async Task<ParametroNormativoDto?> CambiarEstadoAsync(int id, bool activo)
    {
        var entity = await _context.ParametrosNormativos.FirstOrDefaultAsync(p => p.Id == id);
        if (entity is null) return null;
        entity.Activo = activo;
        await _context.SaveChangesAsync();
        return Map(entity);
    }

    private async Task ValidarCodigoAsync(string codigo, int? idActual)
    {
        var normalizado = codigo.Trim().ToLower();
        var existe = await _context.ParametrosNormativos.AnyAsync(p =>
            p.Codigo.ToLower() == normalizado && (!idActual.HasValue || p.Id != idActual.Value));
        if (existe) throw new InvalidOperationException("Ya existe un parametro normativo con ese codigo.");
    }

    private static void Aplicar(ParametroNormativo entity, GuardarParametroNormativoRequestDto request)
    {
        entity.Codigo = request.Codigo.Trim();
        entity.Descripcion = string.IsNullOrWhiteSpace(request.Descripcion) ? null : request.Descripcion.Trim();
        entity.ErrorMaxPermitido = request.ErrorMaxPermitido;
        entity.CaudalMin = request.CaudalMin;
        entity.CaudalMax = request.CaudalMax;
        entity.VigenciaInicio = request.VigenciaInicio;
        entity.VigenciaFin = request.VigenciaFin;
        entity.Activo = request.Activo;
    }

    private static ParametroNormativoDto Map(ParametroNormativo p) => new(
        p.Id, p.Codigo, p.Descripcion, p.ErrorMaxPermitido, p.CaudalMin, p.CaudalMax,
        p.VigenciaInicio, p.VigenciaFin, p.Activo);
}
