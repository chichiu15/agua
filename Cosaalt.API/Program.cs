using Cosaalt.API.Application.Services;
using Cosaalt.API.Infrastructure.Context;
using Cosaalt.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "COSAALT API — Gestión y Cambio de Medidores",
        Version = "R1-R14",
        Description = "API de gestión de medidores, administración R1-R14 y verificación."
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var repositoryMode = builder.Configuration["RepositoryMode"] ?? "Mock";
var connectionString = builder.Configuration.GetConnectionString("CosaaltDb");

if (repositoryMode.Equals("Sql", StringComparison.OrdinalIgnoreCase))
{
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        throw new InvalidOperationException(
            "RepositoryMode=Sql, pero no existe ConnectionStrings:CosaaltDb. " +
            "Configure la cadena de conexión mediante appsettings.Development.json, " +
            "variables de entorno o dotnet user-secrets antes de iniciar en modo SQL.");
    }

    builder.Services.AddDbContext<CosaaltDbContext>(options =>
        options.UseSqlServer(
            connectionString,
            sqlOptions => sqlOptions.UseCompatibilityLevel(110)));

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
    builder.Services.AddScoped<SolicitudVirtualService>();
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
        options.DocumentTitle = "COSAALT API — Swagger";
    });
}

app.UseCors("AllowAll");
app.UseHttpsRedirection();
app.UseStaticFiles();
app.MapControllers();
app.MapGet("/", () => Results.Redirect("/swagger"));
app.Run();
