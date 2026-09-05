using Cosaalt.API.Application.Services;
using Cosaalt.API.Infrastructure.Context;
using Cosaalt.API.Infrastructure.Repositories;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "COSAALT API - Gestion y Cambio de Medidores",
        Version = "2026.09",
        Description = "API integrada con la base institucional cosaalt y el esquema propio medidores."
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var connectionString = builder.Configuration.GetConnectionString("CosaaltDb");
// Si existe una cadena de conexion y no se indico modo explicitamente,
// usamos SQL. Esto evita levantar accidentalmente los repositorios Mock
// mientras se cree que la API esta trabajando contra la base cosaalt.
var repositoryMode = builder.Configuration["RepositoryMode"]
    ?? (!string.IsNullOrWhiteSpace(connectionString) ? "Sql" : "Mock");

if (repositoryMode.Equals("Sql", StringComparison.OrdinalIgnoreCase))
{
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        throw new InvalidOperationException(
            "RepositoryMode=Sql, pero no existe ConnectionStrings:CosaaltDb. " +
            "Configure localmente la cadena de conexion hacia la base cosaalt antes de iniciar.");
    }

    builder.Services.AddDbContext<CosaaltDbContext>(options =>
        options.UseSqlServer(connectionString, sql =>
        {
            sql.CommandTimeout(90);
            // La base institucional se alcanza por VPN. Tolera cortes muy
            // breves sin convertirlos inmediatamente en un error al usuario.
            sql.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(2),
                errorNumbersToAdd: null);
        }));

    builder.Services.AddScoped<CosaaltInstitutionalReader>();
    builder.Services.AddScoped<IAuthRepository, SqlAuthRepository>();
    builder.Services.AddScoped<ICatalogoRepository, SqlCatalogoRepository>();
    builder.Services.AddScoped<ISolicitudRepository, SqlSolicitudRepository>();
    builder.Services.AddScoped<IEjecucionRepository, SqlEjecucionRepository>();
    builder.Services.AddScoped<IRutaRepository, SqlRutaRepository>();
    builder.Services.AddScoped<ISincronizacionRepository, SqlSincronizacionRepository>();
    builder.Services.AddScoped<IUsuarioRepository, SqlUsuarioRepository>();
    builder.Services.AddScoped<IVerificacionRepository, SqlVerificacionRepository>();
    builder.Services.AddScoped<IParametroNormativoRepository, SqlParametroNormativoRepository>();
    builder.Services.AddScoped<IAdminRepository, SqlAdminRepository>();
}
else
{
    builder.Services.AddSingleton<IAuthRepository, MockAuthRepository>();
    builder.Services.AddSingleton<ICatalogoRepository, MockCatalogoRepository>();
    builder.Services.AddSingleton<ISolicitudRepository, MockSolicitudRepository>();
    builder.Services.AddSingleton<IEjecucionRepository, MockEjecucionRepository>();
    builder.Services.AddSingleton<IRutaRepository, MockRutaRepository>();
    builder.Services.AddSingleton<ISincronizacionRepository, MockSincronizacionRepository>();
    builder.Services.AddSingleton<IUsuarioRepository, MockUsuarioRepository>();
    builder.Services.AddSingleton<IVerificacionRepository, MockVerificacionRepository>();
    builder.Services.AddSingleton<IParametroNormativoRepository, MockParametroNormativoRepository>();
    builder.Services.AddSingleton<IAdminRepository, MockAdminRepository>();
}

builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<CatalogoService>();
builder.Services.AddScoped<SolicitudService>();
builder.Services.AddScoped<EjecucionService>();
builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<RutaService>();
builder.Services.AddScoped<SincronizacionService>();
builder.Services.AddScoped<VerificacionService>();
builder.Services.AddScoped<ParametroNormativoService>();
builder.Services.AddScoped<AdminService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "COSAALT API v1");
        options.RoutePrefix = "swagger";
        options.DocumentTitle = "COSAALT API - Swagger";
    });
}

app.UseCors("AllowAll");

// No se exponen excepciones SQL/EF al frontend. Los detalles quedan en consola/log del backend.
app.Use(async (httpContext, next) =>
{
    try
    {
        await next();
    }
    catch (IntegrationPendingException ex)
    {
        app.Logger.LogWarning(ex, "Integracion institucional pendiente");
        httpContext.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        await httpContext.Response.WriteAsJsonAsync(new
        {
            codigo = "INTEGRACION_PENDIENTE",
            mensaje = ex.Message
        });
    }
    catch (ArgumentException ex)
    {
        app.Logger.LogWarning(ex, "Solicitud invalida");
        httpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
        await httpContext.Response.WriteAsJsonAsync(new { mensaje = ex.Message });
    }
    catch (Exception ex) when (EsFallaConexionSql(ex))
    {
        app.Logger.LogError(ex, "Conexion con SQL Server no disponible");
        httpContext.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        await httpContext.Response.WriteAsJsonAsync(new
        {
            codigo = "BASE_DATOS_NO_DISPONIBLE",
            mensaje = "No hay conexión con la base de datos institucional. Verifique la VPN y vuelva a intentar; los trabajos guardados en el dispositivo no se perderán."
        });
    }
    catch (InvalidOperationException ex)
    {
        app.Logger.LogWarning(ex, "Operacion no permitida");
        httpContext.Response.StatusCode = StatusCodes.Status409Conflict;
        await httpContext.Response.WriteAsJsonAsync(new { mensaje = ex.Message });
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Error no controlado en la API");
        httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await httpContext.Response.WriteAsJsonAsync(new
        {
            mensaje = "No se pudo completar la operacion en el servidor. Intente nuevamente o contacte al area de Informatica."
        });
    }
});

app.UseStaticFiles();
app.MapControllers();
app.MapGet("/api/health", () => Results.Ok(new
{
    estado = "ok",
    servicio = "COSAALT Medidores API",
    modoRepositorio = repositoryMode,
    fechaUtc = DateTime.UtcNow
}));
app.MapGet("/", () => Results.Redirect("/swagger"));
app.Run();

static bool EsFallaConexionSql(Exception ex)
{
    for (Exception? actual = ex; actual is not null; actual = actual.InnerException)
    {
        if (actual is SqlException sql &&
            (sql.Class >= 20 || sql.Number is -2 or 20 or 40 or 53 or 64 or 121 or 233 or 258 or 10053 or 10054 or 10060))
            return true;
    }
    return false;
}
