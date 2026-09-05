using System.Data;
using Cosaalt.API.Application.DTOs;
using Microsoft.Data.SqlClient;

namespace Cosaalt.API.Infrastructure.Repositories;

public sealed class IntegrationPendingException : InvalidOperationException
{
    public IntegrationPendingException(string message) : base(message) { }
}

public sealed record SocioInstitucional(
    int RegSoc,
    string Nombre,
    string? Telefono,
    string? Documento,
    string? Ruc,
    string? Correo);

public sealed record MedidorInstitucional(
    int CodMedidor,
    string Marca,
    string Serie,
    DateTime? FechaRegistro,
    string? Tipo,
    string? Capacidad,
    string? Diametro,
    string? Clase,
    string? Descripcion,
    string? Disponibilidad,
    string? Observacion,
    int? CodigoEstado,
    string? Estado,
    int RegSoc);

public sealed record OdecoInstitucional(
    int CodRec,
    DateTime Fecha,
    int RegSoc,
    string NombreSocio,
    string Direccion,
    int? CodTipoReclamo,
    string? TipoReclamo,
    int? CodPrioridad,
    string? Prioridad,
    string? Observacion,
    int? EstadoRaw,
    int? CodMedidor,
    string? SerieMedidor,
    string? MarcaMedidor,
    decimal? LecturaAnterior,
    decimal? LecturaActual,
    decimal? Consumo,
    decimal? Latitud,
    decimal? Longitud);

public sealed record HistoricoMedidorInstitucional(
    int Id,
    DateTime? FechaInicio,
    DateTime? FechaRetiro,
    string? Marca,
    string? Serie,
    string? EstadoHistorico,
    string? Predio,
    string? NombreSocio,
    int RegSoc,
    bool CoincideConMedidorActual);

/// <summary>
/// Capa de lectura/escritura controlada de objetos institucionales dbo.
/// EF Core queda reservado al esquema medidores.*.
/// </summary>
public sealed class CosaaltInstitutionalReader
{
    private readonly string _connectionString;

    public CosaaltInstitutionalReader(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("CosaaltDb")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:CosaaltDb.");
    }

    private async Task<SqlConnection> OpenAsync(CancellationToken ct = default)
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(ct);
        return connection;
    }

    public async Task<bool> TableExistsAsync(string schema, string table, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        await using var cmd = new SqlCommand("SELECT CASE WHEN OBJECT_ID(@obj, 'U') IS NULL THEN 0 ELSE 1 END", cn);
        cmd.Parameters.Add(new SqlParameter("@obj", SqlDbType.NVarChar, 260) { Value = $"{schema}.{table}" });
        return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct)) == 1;
    }

    private async Task<bool> ColumnExistsAsync(string schema, string table, string column, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM sys.columns c
                WHERE c.object_id = OBJECT_ID(@obj)
                  AND c.name = @column
            ) THEN 1 ELSE 0 END;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add(new SqlParameter("@obj", SqlDbType.NVarChar, 260) { Value = $"{schema}.{table}" });
        cmd.Parameters.Add(new SqlParameter("@column", SqlDbType.NVarChar, 128) { Value = column });
        return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct)) == 1;
    }

    public async Task<IReadOnlyList<FuncionarioDto>> ObtenerPersonasAsync(string? buscar = null, int limite = 300, CancellationToken ct = default)
    {
        limite = Math.Clamp(limite, 1, 1000);
        var list = new List<FuncionarioDto>();
        await using var cn = await OpenAsync(ct);

        // dbo.PERSONAS fue auditada en la base cosaalt. Se usan solamente
        // columnas confirmadas y una consulta deliberadamente simple para
        // evitar incompatibilidades con expresiones antiguas de SQL Server.
        var sql = $"""
            SELECT TOP ({limite})
                TRY_CONVERT(int, p.CodPer) AS CodPer,
                LTRIM(RTRIM(COALESCE(p.NomPer, ''))) AS Nombre,
                LTRIM(RTRIM(COALESCE(p.PriApePer, ''))) AS PrimerApellido,
                LTRIM(RTRIM(COALESCE(p.SegApePer, ''))) AS SegundoApellido
            FROM dbo.PERSONAS p
            WHERE (@buscar IS NULL
                OR CONVERT(varchar(30), p.CodPer) LIKE '%' + @buscar + '%'
                OR p.NomPer LIKE '%' + @buscar + '%'
                OR p.PriApePer LIKE '%' + @buscar + '%'
                OR p.SegApePer LIKE '%' + @buscar + '%')
            ORDER BY p.CodPer;
            """;

        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 60 };
        cmd.Parameters.Add(new SqlParameter("@buscar", SqlDbType.VarChar, 100)
        {
            Value = string.IsNullOrWhiteSpace(buscar) ? DBNull.Value : buscar.Trim()
        });

        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            if (rd.IsDBNull(0)) continue;
            var id = rd.GetInt32(0);
            var partes = new[]
            {
                rd.IsDBNull(1) ? null : rd.GetString(1).Trim(),
                rd.IsDBNull(2) ? null : rd.GetString(2).Trim(),
                rd.IsDBNull(3) ? null : rd.GetString(3).Trim()
            }.Where(x => !string.IsNullOrWhiteSpace(x));
            var nombre = string.Join(" ", partes);
            list.Add(new FuncionarioDto(id, string.IsNullOrWhiteSpace(nombre) ? $"Persona {id}" : nombre, null, true));
        }
        return list;
    }

    public async Task<string?> ObtenerNombrePersonaAsync(long? codPer, CancellationToken ct = default)
    {
        if (!codPer.HasValue) return null;
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                LTRIM(RTRIM(CONCAT(
                    NULLIF(RTRIM(p.NomPer), ''), ' ',
                    NULLIF(RTRIM(p.PriApePer), ''), ' ',
                    NULLIF(RTRIM(p.SegApePer), '')
                )))
            FROM dbo.PERSONAS p
            WHERE p.CodPer = @codPer;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add(new SqlParameter("@codPer", SqlDbType.Decimal) { Precision = 18, Scale = 0, Value = codPer.Value });
        var result = await cmd.ExecuteScalarAsync(ct);
        return result is null or DBNull ? null : Convert.ToString(result)?.Trim();
    }

    public async Task<bool> PersonaExisteAsync(long codPer, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        await using var cmd = new SqlCommand("SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.PERSONAS WHERE CodPer=@id) THEN 1 ELSE 0 END", cn);
        cmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Decimal) { Precision = 18, Scale = 0, Value = codPer });
        return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct)) == 1;
    }

    public async Task<SocioInstitucional?> ObtenerSocioAsync(int regSoc, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, s.Reg_Soc),
                NULLIF(LTRIM(RTRIM(s.Nom_Soc)), ''),
                NULLIF(LTRIM(RTRIM(s.Tel_Soc)), ''),
                NULLIF(LTRIM(RTRIM(s.Doc_Soc)), ''),
                NULLIF(LTRIM(RTRIM(s.Ruc_Soc)), '')
            FROM dbo.SOCIO s
            WHERE s.Reg_Soc = @regSoc;
            """;
        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 30 };
        cmd.Parameters.Add(new SqlParameter("@regSoc", SqlDbType.Decimal) { Precision = 6, Scale = 0, Value = regSoc });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        if (!await rd.ReadAsync(ct)) return null;
        return new SocioInstitucional(
            rd.IsDBNull(0) ? regSoc : rd.GetInt32(0),
            rd.IsDBNull(1) ? $"Socio {regSoc}" : rd.GetString(1).Trim(),
            rd.IsDBNull(2) ? null : rd.GetString(2).Trim(),
            rd.IsDBNull(3) ? null : rd.GetString(3).Trim(),
            rd.IsDBNull(4) ? null : rd.GetString(4).Trim(),
            null);
    }

    public async Task<MedidorInstitucional?> ObtenerMedidorActualAsync(int regSoc, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, m.Cod_Med),
                RTRIM(m.Mar_Med), RTRIM(m.Ser_Med), m.Fis_Med,
                RTRIM(m.Tip_Med), RTRIM(m.Cap_Med), RTRIM(m.Dia_Med), RTRIM(m.Cla_Med),
                RTRIM(m.Des_Med), RTRIM(m.dis_med), RTRIM(m.obs_med),
                TRY_CONVERT(int, m.cod_est), RTRIM(em.nom_est), TRY_CONVERT(int, m.reg_soc)
            FROM dbo.Medidor m
            LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
            WHERE m.reg_soc = @regSoc
            ORDER BY
                m.Fis_Med DESC,
                m.Cod_Med DESC;
            """;
        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 60 };
        cmd.Parameters.Add(new SqlParameter("@regSoc", SqlDbType.Decimal) { Precision = 6, Scale = 0, Value = regSoc });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        return await rd.ReadAsync(ct) ? ReadMedidor(rd) : null;
    }

    public async Task<MedidorInstitucional?> ObtenerMedidorPorCodigoAsync(int codMedidor, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, m.Cod_Med),
                RTRIM(m.Mar_Med), RTRIM(m.Ser_Med), m.Fis_Med,
                RTRIM(m.Tip_Med), RTRIM(m.Cap_Med), RTRIM(m.Dia_Med), RTRIM(m.Cla_Med),
                RTRIM(m.Des_Med), RTRIM(m.dis_med), RTRIM(m.obs_med),
                TRY_CONVERT(int, m.cod_est), RTRIM(em.nom_est), TRY_CONVERT(int, m.reg_soc)
            FROM dbo.Medidor m
            LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
            WHERE m.Cod_Med = @cod;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add(new SqlParameter("@cod", SqlDbType.Decimal) { Precision = 6, Scale = 0, Value = codMedidor });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        return await rd.ReadAsync(ct) ? ReadMedidor(rd) : null;
    }

    public async Task<MedidorInstitucional?> ObtenerMedidorPorSerieAsync(string serie, int? regSoc = null, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(serie)) return null;
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, m.Cod_Med),
                RTRIM(m.Mar_Med), RTRIM(m.Ser_Med), m.Fis_Med,
                RTRIM(m.Tip_Med), RTRIM(m.Cap_Med), RTRIM(m.Dia_Med), RTRIM(m.Cla_Med),
                RTRIM(m.Des_Med), RTRIM(m.dis_med), RTRIM(m.obs_med),
                TRY_CONVERT(int, m.cod_est), RTRIM(em.nom_est), TRY_CONVERT(int, m.reg_soc)
            FROM dbo.Medidor m
            LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
            WHERE RTRIM(m.Ser_Med) = @serie
              AND (@regSoc IS NULL OR m.reg_soc = @regSoc)
            ORDER BY m.Fis_Med DESC, m.Cod_Med DESC;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add(new SqlParameter("@serie", SqlDbType.VarChar, 30) { Value = serie.Trim() });
        cmd.Parameters.Add(new SqlParameter("@regSoc", SqlDbType.Decimal) { Precision = 6, Scale = 0, Value = regSoc.HasValue ? regSoc.Value : DBNull.Value });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        return await rd.ReadAsync(ct) ? ReadMedidor(rd) : null;
    }

    public async Task<MedidorInstitucional?> ObtenerMedidorDisponiblePorSerieAsync(string serie, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(serie)) return null;
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, m.Cod_Med),
                RTRIM(m.Mar_Med), RTRIM(m.Ser_Med), m.Fis_Med,
                RTRIM(m.Tip_Med), RTRIM(m.Cap_Med), RTRIM(m.Dia_Med), RTRIM(m.Cla_Med),
                RTRIM(m.Des_Med), RTRIM(m.dis_med), RTRIM(m.obs_med),
                TRY_CONVERT(int, m.cod_est), RTRIM(em.nom_est), TRY_CONVERT(int, m.reg_soc)
            FROM dbo.Medidor m
            LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
            WHERE RTRIM(m.Ser_Med) = @serie
              AND m.cod_est = 5
              AND RTRIM(m.dis_med) = 'L'
              AND m.reg_soc = 0
            ORDER BY RTRIM(m.Ser_Med), RTRIM(m.Mar_Med), m.Cod_Med;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add(new SqlParameter("@serie", SqlDbType.VarChar, 30) { Value = serie.Trim() });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        return await rd.ReadAsync(ct) ? ReadMedidor(rd) : null;
    }

    public async Task<IReadOnlyList<MedidorDisponibleDto>> ObtenerMedidoresDisponiblesAsync(string? buscar = null, int limite = 100, CancellationToken ct = default)
    {
        limite = Math.Clamp(limite, 1, 500);
        var list = new List<MedidorDisponibleDto>();
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (@limite)
                TRY_CONVERT(int, m.Cod_Med), RTRIM(m.Ser_Med), RTRIM(m.Mar_Med),
                RTRIM(m.Tip_Med), RTRIM(m.Cap_Med), RTRIM(m.Dia_Med),
                TRY_CONVERT(int, m.cod_est), RTRIM(em.nom_est), RTRIM(m.dis_med)
            FROM dbo.Medidor m
            LEFT JOIN dbo.Estado_medidor em ON em.cod_est = m.cod_est
            WHERE m.cod_est = 5
              AND RTRIM(m.dis_med) = 'L'
              AND m.reg_soc = 0
              AND (@buscar IS NULL
                   OR RTRIM(m.Ser_Med) LIKE '%' + @buscar + '%'
                   OR RTRIM(m.Mar_Med) LIKE '%' + @buscar + '%'
                   OR CONVERT(varchar(20), m.Cod_Med) LIKE '%' + @buscar + '%')
            ORDER BY RTRIM(m.Ser_Med), RTRIM(m.Mar_Med), m.Cod_Med;
            """;
        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 60 };
        cmd.Parameters.Add(new SqlParameter("@limite", SqlDbType.Int) { Value = limite });
        cmd.Parameters.Add(new SqlParameter("@buscar", SqlDbType.VarChar, 100) { Value = string.IsNullOrWhiteSpace(buscar) ? DBNull.Value : buscar.Trim() });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            list.Add(new MedidorDisponibleDto(
                rd.GetInt32(0), rd.IsDBNull(1) ? "" : rd.GetString(1).Trim(), rd.IsDBNull(2) ? "" : rd.GetString(2).Trim(),
                rd.IsDBNull(3) ? null : rd.GetString(3).Trim(), rd.IsDBNull(4) ? null : rd.GetString(4).Trim(), rd.IsDBNull(5) ? null : rd.GetString(5).Trim(),
                rd.IsDBNull(6) ? null : rd.GetInt32(6), rd.IsDBNull(7) ? null : rd.GetString(7).Trim(), rd.IsDBNull(8) ? "" : rd.GetString(8).Trim()));
        }
        return list;
    }

    public async Task<IReadOnlyList<MarcaMedidorDto>> ObtenerMarcasAsync(bool incluirInactivos = true, CancellationToken ct = default)
    {
        // La base cosaalt no contiene un catalogo corporativo separado de marcas;
        // dbo.Medidor conserva el codigo corto en Mar_Med. La aplicacion administra
        // nombre/alias/estado en medidores.MarcasMedidor sin alterar dbo.Medidor.
        if (!await TableExistsAsync("medidores", "MarcasMedidor", ct))
        {
            var fallback = new List<MarcaMedidorDto>();
            await using var cnFallback = await OpenAsync(ct);
            const string fallbackSql = """
                SELECT ROW_NUMBER() OVER (ORDER BY Marca) AS Id, Marca
                FROM (
                    SELECT DISTINCT RTRIM(Mar_Med) AS Marca
                    FROM dbo.Medidor
                    WHERE Mar_Med IS NOT NULL AND RTRIM(Mar_Med) <> ''
                ) x
                ORDER BY Marca;
                """;
            await using var cmdFallback = new SqlCommand(fallbackSql, cnFallback) { CommandTimeout = 60 };
            await using var rdFallback = await cmdFallback.ExecuteReaderAsync(ct);
            while (await rdFallback.ReadAsync(ct))
            {
                var code = rdFallback.GetString(1).Trim();
                fallback.Add(new MarcaMedidorDto(Convert.ToInt32(rdFallback.GetInt64(0)), code, code, true, code));
            }
            return fallback;
        }

        await using var cn = await OpenAsync(ct);
        // Sincroniza codigos institucionales que aparezcan en dbo.Medidor.
        const string syncSql = """
            INSERT INTO medidores.MarcasMedidor (Codigo, Nombre, Alias, Activo, FechaCreacion)
            SELECT x.Codigo, x.Codigo, NULL, 1, SYSDATETIME()
            FROM (
                SELECT DISTINCT UPPER(RTRIM(Mar_Med)) AS Codigo
                FROM dbo.Medidor
                WHERE Mar_Med IS NOT NULL AND RTRIM(Mar_Med) <> ''
            ) x
            WHERE NOT EXISTS (
                SELECT 1 FROM medidores.MarcasMedidor m WHERE UPPER(RTRIM(m.Codigo)) = x.Codigo
            );
            """;
        await using (var sync = new SqlCommand(syncSql, cn) { CommandTimeout = 60 })
            await sync.ExecuteNonQueryAsync(ct);

        var sql = """
            SELECT IdMarca, RTRIM(Nombre), NULLIF(RTRIM(Alias), ''), Activo, RTRIM(Codigo)
            FROM medidores.MarcasMedidor
            WHERE (@incluir = 1 OR Activo = 1)
            ORDER BY Nombre, Codigo;
            """;
        var list = new List<MarcaMedidorDto>();
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.AddWithValue("@incluir", incluirInactivos);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
            list.Add(new MarcaMedidorDto(rd.GetInt32(0), rd.GetString(1).Trim(), rd.IsDBNull(2) ? null : rd.GetString(2).Trim(), rd.GetBoolean(3), rd.GetString(4).Trim()));
        return list;
    }

    public async Task<MarcaMedidorDto> CrearMarcaAsync(GuardarMarcaMedidorRequestDto request, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MarcasMedidor", ct);
        await using var cn = await OpenAsync(ct);
        const string sql = """
            INSERT INTO medidores.MarcasMedidor (Codigo, Nombre, Alias, Activo, FechaCreacion)
            OUTPUT INSERTED.IdMarca
            VALUES (UPPER(@codigo), @nombre, @alias, @activo, SYSDATETIME());
            """;
        try
        {
            await using var cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@codigo", request.Codigo.Trim());
            cmd.Parameters.AddWithValue("@nombre", request.Nombre.Trim());
            cmd.Parameters.AddWithValue("@alias", string.IsNullOrWhiteSpace(request.Alias) ? DBNull.Value : request.Alias.Trim());
            cmd.Parameters.AddWithValue("@activo", request.Activo);
            var id = Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
            return new MarcaMedidorDto(id, request.Nombre.Trim(), string.IsNullOrWhiteSpace(request.Alias) ? null : request.Alias.Trim(), request.Activo, request.Codigo.Trim().ToUpperInvariant());
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new InvalidOperationException("Ya existe una marca con ese codigo.");
        }
    }

    public async Task<MarcaMedidorDto?> ActualizarMarcaAsync(int id, GuardarMarcaMedidorRequestDto request, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MarcasMedidor", ct);
        await using var cn = await OpenAsync(ct);
        const string sql = """
            UPDATE medidores.MarcasMedidor
            SET Codigo=UPPER(@codigo), Nombre=@nombre, Alias=@alias, Activo=@activo, FechaActualizacion=SYSDATETIME()
            WHERE IdMarca=@id;
            """;
        try
        {
            await using var cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@codigo", request.Codigo.Trim());
            cmd.Parameters.AddWithValue("@nombre", request.Nombre.Trim());
            cmd.Parameters.AddWithValue("@alias", string.IsNullOrWhiteSpace(request.Alias) ? DBNull.Value : request.Alias.Trim());
            cmd.Parameters.AddWithValue("@activo", request.Activo);
            if (await cmd.ExecuteNonQueryAsync(ct) == 0) return null;
            return new MarcaMedidorDto(id, request.Nombre.Trim(), string.IsNullOrWhiteSpace(request.Alias) ? null : request.Alias.Trim(), request.Activo, request.Codigo.Trim().ToUpperInvariant());
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new InvalidOperationException("Ya existe otra marca con ese codigo.");
        }
    }

    public async Task<MarcaMedidorDto?> CambiarEstadoMarcaAsync(int id, bool activo, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MarcasMedidor", ct);
        await using var cn = await OpenAsync(ct);
        await using var cmd = new SqlCommand("UPDATE medidores.MarcasMedidor SET Activo=@activo, FechaActualizacion=SYSDATETIME() WHERE IdMarca=@id", cn);
        cmd.Parameters.AddWithValue("@id", id);
        cmd.Parameters.AddWithValue("@activo", activo);
        if (await cmd.ExecuteNonQueryAsync(ct) == 0) return null;
        var all = await ObtenerMarcasAsync(true, ct);
        return all.FirstOrDefault(x => x.Id == id);
    }

    public async Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync(bool incluirInactivos, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MotivosCambio", ct);
        var list = new List<MotivoCambioDto>();
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT IdMotivo, RTRIM(Nombre), NULLIF(RTRIM(Descripcion), ''), Activo
            FROM medidores.MotivosCambio
            WHERE (@incluir = 1 OR Activo = 1)
            ORDER BY Nombre, IdMotivo;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.AddWithValue("@incluir", incluirInactivos);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
            list.Add(new MotivoCambioDto(rd.GetInt32(0), rd.GetString(1).Trim(), rd.IsDBNull(2) ? null : rd.GetString(2).Trim(), rd.GetBoolean(3)));
        return list;
    }

    public async Task<MotivoCambioDto?> ObtenerMotivoAsync(int id, CancellationToken ct = default)
    {
        var all = await ObtenerMotivosAsync(true, ct);
        return all.FirstOrDefault(x => x.Id == id);
    }

    public async Task<MotivoCambioDto> CrearMotivoAsync(GuardarMotivoCambioRequestDto request, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MotivosCambio", ct);
        await using var cn = await OpenAsync(ct);
        const string sql = """
            INSERT INTO medidores.MotivosCambio (Nombre, Descripcion, Activo, FechaCreacion)
            OUTPUT INSERTED.IdMotivo
            VALUES (@nombre, @descripcion, @activo, SYSDATETIME());
            """;
        try
        {
            await using var cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@nombre", request.Nombre.Trim());
            cmd.Parameters.AddWithValue("@descripcion", string.IsNullOrWhiteSpace(request.Descripcion) ? DBNull.Value : request.Descripcion.Trim());
            cmd.Parameters.AddWithValue("@activo", request.Activo);
            var id = Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
            return new MotivoCambioDto(id, request.Nombre.Trim(), string.IsNullOrWhiteSpace(request.Descripcion) ? null : request.Descripcion.Trim(), request.Activo);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new InvalidOperationException("Ya existe un motivo con ese nombre.");
        }
    }

    public async Task<MotivoCambioDto?> ActualizarMotivoAsync(int id, GuardarMotivoCambioRequestDto request, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MotivosCambio", ct);
        await using var cn = await OpenAsync(ct);
        const string sql = """
            UPDATE medidores.MotivosCambio
            SET Nombre=@nombre, Descripcion=@descripcion, Activo=@activo, FechaActualizacion=SYSDATETIME()
            WHERE IdMotivo=@id;
            """;
        try
        {
            await using var cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@nombre", request.Nombre.Trim());
            cmd.Parameters.AddWithValue("@descripcion", string.IsNullOrWhiteSpace(request.Descripcion) ? DBNull.Value : request.Descripcion.Trim());
            cmd.Parameters.AddWithValue("@activo", request.Activo);
            return await cmd.ExecuteNonQueryAsync(ct) == 0 ? null : new MotivoCambioDto(id, request.Nombre.Trim(), string.IsNullOrWhiteSpace(request.Descripcion) ? null : request.Descripcion.Trim(), request.Activo);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new InvalidOperationException("Ya existe otro motivo con ese nombre.");
        }
    }

    public async Task<MotivoCambioDto?> CambiarEstadoMotivoAsync(int id, bool activo, CancellationToken ct = default)
    {
        await EnsureCatalogTableAsync("MotivosCambio", ct);
        await using var cn = await OpenAsync(ct);
        await using var cmd = new SqlCommand("UPDATE medidores.MotivosCambio SET Activo=@activo, FechaActualizacion=SYSDATETIME() WHERE IdMotivo=@id", cn);
        cmd.Parameters.AddWithValue("@id", id);
        cmd.Parameters.AddWithValue("@activo", activo);
        if (await cmd.ExecuteNonQueryAsync(ct) == 0) return null;
        return await ObtenerMotivoAsync(id, ct);
    }

    private async Task EnsureCatalogTableAsync(string table, CancellationToken ct)
    {
        if (!await TableExistsAsync("medidores", table, ct))
            throw new IntegrationPendingException($"Falta medidores.{table}. Ejecute el script 06_ACTUALIZAR_CATALOGOS_APP.sql incluido con esta version.");
    }

    public async Task<IReadOnlyList<OdecoInstitucional>> ObtenerOdecosAsync(IReadOnlyCollection<int>? tiposPermitidos, int limite = 1000, CancellationToken ct = default)
    {
        // COSAALT confirmo que el cambio de medidor no nace automaticamente de un
        // CodTipRec. Mientras no exista una regla institucional cerrada, el filtro
        // por tipos es opcional y la bandeja se mantiene para seleccion/validacion manual.
        limite = Math.Clamp(limite, 1, 2000);
        var list = new List<OdecoInstitucional>();
        await using var cn = await OpenAsync(ct);

        var tipos = tiposPermitidos?.Where(x => x > 0).Distinct().ToArray() ?? [];
        var filtroTipos = tipos.Length == 0 ? string.Empty : $" AND r.CodTipRec IN ({string.Join(',', tipos.Select((_, i) => $"@tipo{i}"))})";

        var sql = $"""
            SELECT TOP ({limite})
                TRY_CONVERT(int, r.CodRec) AS CodRec,
                r.FecHorRec,
                TRY_CONVERT(int, r.Reg_Soc) AS RegSoc,
                NULLIF(LTRIM(RTRIM(s.Nom_Soc)), '') AS NombreSocio,
                NULLIF(LTRIM(RTRIM(COALESCE(NULLIF(r.RefDirRec,''), NULLIF(r.Cal1Rec,''), NULLIF(r.Cal2Rec,''), ''))), '') AS Direccion,
                TRY_CONVERT(int, r.CodTipRec) AS CodTipRec,
                NULLIF(LTRIM(RTRIM(tr.NomTipRec)), '') AS TipoReclamo,
                TRY_CONVERT(int, r.CodTipPri) AS CodTipPri,
                NULLIF(LTRIM(RTRIM(tp.NomTipPri)), '') AS Prioridad,
                NULLIF(LTRIM(RTRIM(r.ObsRec)), '') AS Observacion,
                TRY_CONVERT(int, r.EstRec) AS EstadoRaw,
                med.CodMedidor,
                med.Serie,
                med.Marca,
                lec.LecturaAnterior,
                lec.LecturaActual,
                lec.Consumo,
                lec.Latitud,
                lec.Longitud
            FROM dbo.RECLAMOS r
            LEFT JOIN dbo.SOCIO s ON s.Reg_Soc = r.Reg_Soc
            LEFT JOIN dbo.TIPOSRECLAMOS tr ON tr.CodTipRec = r.CodTipRec
            LEFT JOIN dbo.TIPOSPRIORIDADES tp ON tp.CodTipPri = r.CodTipPri
            OUTER APPLY (
                SELECT TOP (1)
                    TRY_CONVERT(int, m.Cod_Med) AS CodMedidor,
                    NULLIF(LTRIM(RTRIM(m.Ser_Med)), '') AS Serie,
                    NULLIF(LTRIM(RTRIM(m.Mar_Med)), '') AS Marca
                FROM dbo.Medidor m
                WHERE m.reg_soc = r.Reg_Soc
                ORDER BY m.Fis_Med DESC, m.Cod_Med DESC
            ) med
            OUTER APPLY (
                SELECT TOP (1)
                    TRY_CONVERT(decimal(18,2), l.Lan_Lec) AS LecturaAnterior,
                    TRY_CONVERT(decimal(18,2), l.Lac_Lec) AS LecturaActual,
                    TRY_CONVERT(decimal(18,2), l.Con_Lec) AS Consumo,
                    TRY_CONVERT(decimal(18,12), l.LatLec) AS Latitud,
                    TRY_CONVERT(decimal(18,12), l.LonLec) AS Longitud
                FROM dbo.Lectura l
                WHERE l.reg_soc = r.Reg_Soc
                  AND l.LatLec IS NOT NULL AND l.LonLec IS NOT NULL
                  AND TRY_CONVERT(decimal(18,12), l.LatLec) BETWEEN -90 AND 90
                  AND TRY_CONVERT(decimal(18,12), l.LonLec) BETWEEN -180 AND 180
                  AND TRY_CONVERT(decimal(18,12), l.LatLec) <> 0
                  AND TRY_CONVERT(decimal(18,12), l.LonLec) <> 0
                ORDER BY l.Cod_Lec DESC
            ) lec
            WHERE r.Reg_Soc IS NOT NULL {filtroTipos}
            ORDER BY r.CodRec DESC;
            """;

        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 90 };
        for (var i = 0; i < tipos.Length; i++)
            cmd.Parameters.Add(new SqlParameter($"@tipo{i}", SqlDbType.Decimal) { Precision = 5, Scale = 0, Value = tipos[i] });

        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            if (rd.IsDBNull(0) || rd.IsDBNull(2)) continue;
            list.Add(new OdecoInstitucional(
                rd.GetInt32(0),
                rd.IsDBNull(1) ? DateTime.MinValue : rd.GetDateTime(1),
                rd.GetInt32(2),
                rd.IsDBNull(3) ? $"Socio {rd.GetInt32(2)}" : rd.GetString(3).Trim(),
                rd.IsDBNull(4) ? string.Empty : rd.GetString(4).Trim(),
                rd.IsDBNull(5) ? null : rd.GetInt32(5),
                rd.IsDBNull(6) ? null : rd.GetString(6).Trim(),
                rd.IsDBNull(7) ? null : rd.GetInt32(7),
                rd.IsDBNull(8) ? null : rd.GetString(8).Trim(),
                rd.IsDBNull(9) ? null : rd.GetString(9).Trim(),
                rd.IsDBNull(10) ? null : rd.GetInt32(10),
                rd.IsDBNull(11) ? null : rd.GetInt32(11),
                rd.IsDBNull(12) ? null : rd.GetString(12).Trim(),
                rd.IsDBNull(13) ? null : rd.GetString(13).Trim(),
                rd.IsDBNull(14) ? null : rd.GetDecimal(14),
                rd.IsDBNull(15) ? null : rd.GetDecimal(15),
                rd.IsDBNull(16) ? null : rd.GetDecimal(16),
                rd.IsDBNull(17) ? null : rd.GetDecimal(17),
                rd.IsDBNull(18) ? null : rd.GetDecimal(18)));
        }
        return list;
    }

    public async Task<OdecoInstitucional?> ObtenerOdecoAsync(int codRec, CancellationToken ct = default)
    {
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (1)
                TRY_CONVERT(int, r.CodRec),
                r.FecHorRec,
                TRY_CONVERT(int, r.Reg_Soc),
                NULLIF(LTRIM(RTRIM(s.Nom_Soc)), ''),
                NULLIF(LTRIM(RTRIM(COALESCE(NULLIF(r.RefDirRec,''), NULLIF(r.Cal1Rec,''), NULLIF(r.Cal2Rec,''), ''))), ''),
                TRY_CONVERT(int, r.CodTipRec),
                NULLIF(LTRIM(RTRIM(tr.NomTipRec)), ''),
                TRY_CONVERT(int, r.CodTipPri),
                NULLIF(LTRIM(RTRIM(tp.NomTipPri)), ''),
                NULLIF(LTRIM(RTRIM(r.ObsRec)), ''),
                TRY_CONVERT(int, r.EstRec),
                med.CodMedidor, med.Serie, med.Marca,
                lec.LecturaAnterior, lec.LecturaActual, lec.Consumo, lec.Latitud, lec.Longitud
            FROM dbo.RECLAMOS r
            LEFT JOIN dbo.SOCIO s ON s.Reg_Soc = r.Reg_Soc
            LEFT JOIN dbo.TIPOSRECLAMOS tr ON tr.CodTipRec = r.CodTipRec
            LEFT JOIN dbo.TIPOSPRIORIDADES tp ON tp.CodTipPri = r.CodTipPri
            OUTER APPLY (
                SELECT TOP (1)
                    TRY_CONVERT(int, m.Cod_Med) AS CodMedidor,
                    NULLIF(LTRIM(RTRIM(m.Ser_Med)), '') AS Serie,
                    NULLIF(LTRIM(RTRIM(m.Mar_Med)), '') AS Marca
                FROM dbo.Medidor m
                WHERE m.reg_soc = r.Reg_Soc
                ORDER BY m.Fis_Med DESC, m.Cod_Med DESC
            ) med
            OUTER APPLY (
                SELECT TOP (1)
                    TRY_CONVERT(decimal(18,2), l.Lan_Lec) AS LecturaAnterior,
                    TRY_CONVERT(decimal(18,2), l.Lac_Lec) AS LecturaActual,
                    TRY_CONVERT(decimal(18,2), l.Con_Lec) AS Consumo,
                    TRY_CONVERT(decimal(18,12), l.LatLec) AS Latitud,
                    TRY_CONVERT(decimal(18,12), l.LonLec) AS Longitud
                FROM dbo.Lectura l
                WHERE l.reg_soc = r.Reg_Soc
                  AND l.LatLec IS NOT NULL AND l.LonLec IS NOT NULL
                  AND TRY_CONVERT(decimal(18,12), l.LatLec) BETWEEN -90 AND 90
                  AND TRY_CONVERT(decimal(18,12), l.LonLec) BETWEEN -180 AND 180
                  AND TRY_CONVERT(decimal(18,12), l.LatLec) <> 0
                  AND TRY_CONVERT(decimal(18,12), l.LonLec) <> 0
                ORDER BY l.Cod_Lec DESC
            ) lec
            WHERE r.CodRec = @codRec AND r.Reg_Soc IS NOT NULL;
            """;
        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 60 };
        cmd.Parameters.Add(new SqlParameter("@codRec", SqlDbType.Decimal) { Precision = 18, Scale = 0, Value = codRec });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        if (!await rd.ReadAsync(ct) || rd.IsDBNull(0) || rd.IsDBNull(2)) return null;
        return new OdecoInstitucional(
            rd.GetInt32(0), rd.IsDBNull(1) ? DateTime.MinValue : rd.GetDateTime(1), rd.GetInt32(2),
            rd.IsDBNull(3) ? $"Socio {rd.GetInt32(2)}" : rd.GetString(3).Trim(),
            rd.IsDBNull(4) ? string.Empty : rd.GetString(4).Trim(),
            rd.IsDBNull(5) ? null : rd.GetInt32(5), rd.IsDBNull(6) ? null : rd.GetString(6).Trim(),
            rd.IsDBNull(7) ? null : rd.GetInt32(7), rd.IsDBNull(8) ? null : rd.GetString(8).Trim(),
            rd.IsDBNull(9) ? null : rd.GetString(9).Trim(), rd.IsDBNull(10) ? null : rd.GetInt32(10),
            rd.IsDBNull(11) ? null : rd.GetInt32(11), rd.IsDBNull(12) ? null : rd.GetString(12).Trim(), rd.IsDBNull(13) ? null : rd.GetString(13).Trim(),
            rd.IsDBNull(14) ? null : rd.GetDecimal(14), rd.IsDBNull(15) ? null : rd.GetDecimal(15), rd.IsDBNull(16) ? null : rd.GetDecimal(16),
            rd.IsDBNull(17) ? null : rd.GetDecimal(17), rd.IsDBNull(18) ? null : rd.GetDecimal(18));
    }

    public async Task<IReadOnlyList<SolicitudBandejaDto>> ObtenerSolicitudesPruebaAsync(CancellationToken ct = default)
    {
        if (!await TableExistsAsync("medidores", "SolicitudPruebaE2E", ct)) return [];
        var list = new List<SolicitudBandejaDto>();
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT SolicitudId, TipoOrigen, Estado, EsUrgente, TRY_CONVERT(int,RegSoc),
                   NombreCliente, Direccion, Categoria, NumeroMedidor, MarcaMedidor,
                   MotivoObservacion, FechaSolicitud, Latitud, Longitud
            FROM medidores.SolicitudPruebaE2E
            ORDER BY OrdenPrueba, SolicitudId;
            """;
        await using var cmd = new SqlCommand(sql, cn);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            if (rd.IsDBNull(4)) continue;
            list.Add(new SolicitudBandejaDto(
                rd.GetString(0).Trim(), rd.GetString(1).Trim(), rd.GetString(2).Trim(), rd.GetBoolean(3), rd.GetInt32(4),
                rd.GetString(5).Trim(), rd.GetString(6).Trim(), rd.IsDBNull(7) ? "QA E2E" : rd.GetString(7).Trim(),
                "QA", null, rd.IsDBNull(8) ? null : rd.GetString(8).Trim(), rd.IsDBNull(9) ? null : rd.GetString(9).Trim(),
                null, null, null, rd.IsDBNull(10) ? null : rd.GetString(10).Trim(), rd.GetDateTime(11), null, null,
                rd.IsDBNull(12) ? null : Convert.ToDouble(rd.GetDecimal(12)), rd.IsDBNull(13) ? null : Convert.ToDouble(rd.GetDecimal(13))));
        }
        return list;
    }

    public async Task<SolicitudBandejaDto?> ObtenerSolicitudPruebaAsync(string solicitudId, CancellationToken ct = default)
    {
        if (!await TableExistsAsync("medidores", "SolicitudPruebaE2E", ct)) return null;
        var all = await ObtenerSolicitudesPruebaAsync(ct);
        return all.FirstOrDefault(x => x.Id.Equals(solicitudId, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<IReadOnlyList<HistoricoMedidorInstitucional>> ObtenerHistoricoMedidoresAsync(int? regSoc = null, int limite = 5000, CancellationToken ct = default)
    {
        limite = Math.Clamp(limite, 1, 20000);
        var list = new List<HistoricoMedidorInstitucional>();
        await using var cn = await OpenAsync(ct);
        const string sql = """
            SELECT TOP (@limite)
                TRY_CONVERT(int,h.cod_pme), h.fec_pme, h.fec_rme,
                NULLIF(RTRIM(h.mar_med),''), NULLIF(RTRIM(h.ser_med),''), NULLIF(RTRIM(h.est_med),''),
                NULLIF(RTRIM(h.cub_pre),''), NULLIF(RTRIM(h.nom_soc),''), TRY_CONVERT(int,h.reg_soc),
                CASE WHEN EXISTS (
                    SELECT 1 FROM dbo.Medidor m
                    WHERE m.reg_soc = h.reg_soc
                      AND RTRIM(m.Mar_Med) = RTRIM(h.mar_med)
                      AND RTRIM(m.Ser_Med) = RTRIM(h.ser_med)
                ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
            FROM dbo.hist_pred_med h
            WHERE (@regSoc IS NULL OR h.reg_soc=@regSoc)
            ORDER BY h.cod_pme DESC;
            """;
        await using var cmd = new SqlCommand(sql, cn) { CommandTimeout = 90 };
        cmd.Parameters.Add(new SqlParameter("@limite", SqlDbType.Int) { Value = limite });
        cmd.Parameters.Add(new SqlParameter("@regSoc", SqlDbType.Decimal) { Precision = 6, Scale = 0, Value = regSoc.HasValue ? regSoc.Value : DBNull.Value });
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            if (rd.IsDBNull(0) || rd.IsDBNull(8)) continue;
            list.Add(new HistoricoMedidorInstitucional(
                rd.GetInt32(0), rd.IsDBNull(1) ? null : rd.GetDateTime(1), rd.IsDBNull(2) ? null : rd.GetDateTime(2),
                rd.IsDBNull(3) ? null : rd.GetString(3).Trim(), rd.IsDBNull(4) ? null : rd.GetString(4).Trim(), rd.IsDBNull(5) ? null : rd.GetString(5).Trim(),
                rd.IsDBNull(6) ? null : rd.GetString(6).Trim(), rd.IsDBNull(7) ? null : rd.GetString(7).Trim(), rd.GetInt32(8), !rd.IsDBNull(9) && rd.GetBoolean(9)));
        }
        return list;
    }

    private static MedidorInstitucional ReadMedidor(SqlDataReader rd) => new(
        rd.GetInt32(0), rd.IsDBNull(1) ? "" : rd.GetString(1).Trim(), rd.IsDBNull(2) ? "" : rd.GetString(2).Trim(),
        rd.IsDBNull(3) ? null : rd.GetDateTime(3), rd.IsDBNull(4) ? null : rd.GetString(4).Trim(), rd.IsDBNull(5) ? null : rd.GetString(5).Trim(),
        rd.IsDBNull(6) ? null : rd.GetString(6).Trim(), rd.IsDBNull(7) ? null : rd.GetString(7).Trim(), rd.IsDBNull(8) ? null : rd.GetString(8).Trim(),
        rd.IsDBNull(9) ? null : rd.GetString(9).Trim(), rd.IsDBNull(10) ? null : rd.GetString(10).Trim(), rd.IsDBNull(11) ? null : rd.GetInt32(11),
        rd.IsDBNull(12) ? null : rd.GetString(12).Trim(), rd.IsDBNull(13) ? 0 : rd.GetInt32(13));
}
