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
        Version = "Sprint 2",
        Description = "API con rutas, sincronización, coordenadas para mapa y subida de evidencias."
    });
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

builder.Services.AddDbContext<CosaaltDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("CosaaltDb")));

var repositoryMode = builder.Configuration["RepositoryMode"] ?? "Mock";

if (repositoryMode.Equals("Sql", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddScoped<IAuthRepository, SqlAuthRepository>();
    builder.Services.AddScoped<ICatalogoRepository, SqlCatalogoRepository>();
    builder.Services.AddScoped<ISolicitudRepository, SqlSolicitudRepository>();
    builder.Services.AddScoped<IEjecucionRepository, SqlEjecucionRepository>();
    builder.Services.AddScoped<IRutaRepository, SqlRutaRepository>();               // antes: Mock
    builder.Services.AddScoped<ISincronizacionRepository, SqlSincronizacionRepository>(); // antes: Mock
    builder.Services.AddScoped<IUsuarioRepository, SqlUsuarioRepository>();         // antes: Mock
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
}

builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<CatalogoService>();
builder.Services.AddScoped<SolicitudService>();
builder.Services.AddScoped<EjecucionService>();
builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<RutaService>();
builder.Services.AddScoped<SincronizacionService>();
builder.Services.AddScoped<SolicitudVirtualService>();

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

// Sirve las fotos guardadas en wwwroot/uploads (ej: /uploads/1042/xxxx.jpg)
// necesario para que EvidenciasController sea accesible después de subir.
app.UseStaticFiles();

app.MapControllers();
app.MapGet("/", () => Results.Redirect("/swagger"));
app.Run();