using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Seed;

public static class DatabaseSeeder
{
    private sealed class SeedWorkItem
    {
        public string TipoOrigen { get; init; } = string.Empty;
        public string IdOrigen { get; init; } = string.Empty;
        public string SolicitudId { get; init; } = string.Empty;

        public int RegistroSocio { get; init; }

        public string NombreCliente { get; init; } = string.Empty;
        public string Direccion { get; init; } = string.Empty;

        public double? Latitud { get; init; }
        public double? Longitud { get; init; }

        public DateTime FechaSolicitud { get; init; }
    }

    public static async Task SeedAsync(CosaaltDbContext context)
    {
        // ------------------------------------------------------------
        // IMPORTANTE
        // ------------------------------------------------------------
        // Este seeder está pensado para una BD de desarrollo/pruebas.
        //
        // Si ya existen socios o usuarios, NO vuelve a insertar todo
        // para evitar duplicados.
        //
        // Si quieres regenerar todo:
        //
        // dotnet ef database drop --force
        // dotnet ef database update
        // dotnet run
        // ------------------------------------------------------------

        if (await context.Socios.AnyAsync() ||
            await context.UsuariosApp.AnyAsync())
        {
            return;
        }

        var hoy = DateTime.Today;

        // ============================================================
        // 1. MOTIVOS DE CAMBIO
        // ============================================================

        var motivos = new List<MotivoCambioMedidor>
        {
            new() { Descripcion = "Empañado", Activo = true },
            new() { Descripcion = "Destrozado", Activo = true },
            new() { Descripcion = "Roto", Activo = true },
            new() { Descripcion = "Descalibrado", Activo = true },
            new() { Descripcion = "Antiguo", Activo = true },
            new() { Descripcion = "Parado", Activo = true },
            new() { Descripcion = "Otro", Activo = true }
        };

        context.MotivosCambio.AddRange(motivos);

        // ============================================================
        // 2. USUARIOS
        // 10 técnicos + 1 asignador
        //
        // Contraseñas provisionales porque el sistema actual todavía
        // trabaja con autenticación provisional.
        // ============================================================

        var usuarios = new List<UsuarioApp>
        {
            new()
            {
                NombreUsuario = "asignador1",
                ContrasenaHash = "123456",
                NombreCompleto = "Pedro Encargado López",
                Rol = "asignador",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico1",
                ContrasenaHash = "123456",
                NombreCompleto = "Juan Pérez García",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico2",
                ContrasenaHash = "123456",
                NombreCompleto = "Luis Mamani Condori",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico3",
                ContrasenaHash = "123456",
                NombreCompleto = "Carlos Rojas Mendoza",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico4",
                ContrasenaHash = "123456",
                NombreCompleto = "Miguel Ángel Torres",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico5",
                ContrasenaHash = "123456",
                NombreCompleto = "José Luis Flores",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico6",
                ContrasenaHash = "123456",
                NombreCompleto = "Roberto Vargas Romero",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico7",
                ContrasenaHash = "123456",
                NombreCompleto = "Daniel Gutiérrez Cruz",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico8",
                ContrasenaHash = "123456",
                NombreCompleto = "Fernando Martínez López",
                Rol = "tecnico",
                Activo = true
            },

            new()
            {
                NombreUsuario = "tecnico9",
                ContrasenaHash = "123456",
                NombreCompleto = "Ricardo Choque Salazar",
                Rol = "tecnico",
                Activo = true
            },

            // Técnico inactivo para probar filtros / disponibilidad.
            new()
            {
                NombreUsuario = "tecnico10",
                ContrasenaHash = "123456",
                NombreCompleto = "Marco Antonio Ruiz",
                Rol = "tecnico",
                Activo = false
            }
        };

        context.UsuariosApp.AddRange(usuarios);

        // ============================================================
        // 3. SOCIOS
        // 150 socios deterministas
        // ============================================================

        var nombres = new[]
        {
            "María Elena",
            "Carlos Alberto",
            "Ana Lucía",
            "Roberto",
            "Patricia",
            "Jorge Luis",
            "Daniela",
            "Miguel Ángel",
            "Verónica",
            "Fernando",
            "Gabriela",
            "José Antonio",
            "Andrea",
            "Luis Alberto",
            "Carmen Rosa"
        };

        var apellidos = new[]
        {
            "Vargas Mendoza",
            "Mamani Condori",
            "Rojas Flores",
            "Pérez García",
            "Torres Romero",
            "Gutiérrez Cruz",
            "Fernández López",
            "Choque Salazar",
            "Martínez Ruiz",
            "Sánchez Molina"
        };

        var vias = new[]
        {
            "Av. Las Américas",
            "Av. La Paz",
            "Av. Víctor Paz",
            "Av. Jaime Paz",
            "Av. Circunvalación",
            "Calle Bolívar",
            "Calle Sucre",
            "Calle Daniel Campos",
            "Calle Colón",
            "Calle Ingavi",
            "Calle Junín",
            "Calle Virginio Lema",
            "Calle General Trigo",
            "Calle Alejandro del Carpio",
            "Calle Cochabamba"
        };

        var zonas = new[]
        {
            "Centro",
            "San Roque",
            "Senac",
            "Tabladita",
            "Morros Blancos",
            "Juan XXIII",
            "Villa Avaroa",
            "Luis Espinal",
            "Las Panosas",
            "El Molino"
        };

        var categorias = new[]
        {
            "Doméstica",
            "Doméstica",
            "Doméstica",
            "Comercial",
            "Industrial"
        };

        var socios = new List<Socio>();

        for (var i = 0; i < 150; i++)
        {
            var registro = 900001 + i;

            var nombre =
                $"{nombres[i % nombres.Length]} " +
                $"{apellidos[i % apellidos.Length]}";

            var direccion =
                $"{vias[i % vias.Length]} #{100 + i * 7}, " +
                $"Zona {zonas[i % zonas.Length]}";

            socios.Add(
                new Socio
                {
                    RegistroSocio = registro,
                    CodigoCatastral = $"CAT-{registro}",
                    Nombre = nombre,
                    Direccion = direccion,
                    Categoria = categorias[i % categorias.Length],
                    Ruta = $"R-{(i % 15) + 1:00}",
                    Recorrido = (i % 40) + 1,
                    Ci = $"{5000000 + i}",
                    Telefono = $"7{1000000 + i:0000000}",
                    Sexo = i % 2 == 0 ? "F" : "M"
                });
        }

        context.Socios.AddRange(socios);

        // ============================================================
        // 4. MEDIDORES
        //
        // Cada socio comienza con EXACTAMENTE UN medidor Activo.
        //
        // Los primeros 50 socios además tienen un medidor histórico
        // Retirado.
        //
        // Más adelante, al crear ejecuciones completadas, otros 50
        // socios recibirán un nuevo medidor Activo y el anterior pasará
        // a Retirado.
        // ============================================================

        var marcas = new[]
        {
            "SAG",
            "Elster",
            "Itron",
            "Zenner",
            "Sensus",
            "Actaris"
        };

        var medidoresActivos = new Dictionary<int, Medidor>();

        for (var i = 0; i < socios.Count; i++)
        {
            var socio = socios[i];

            // Grid alrededor de Tarija.
            var fila = i / 15;
            var columna = i % 15;

            var latitud =
                -21.5350 +
                ((fila - 5) * 0.0022) +
                ((columna % 3) * 0.0003);

            var longitud =
                -64.7280 +
                ((columna - 7) * 0.0020) +
                ((fila % 3) * 0.0003);

            // --------------------------------------------------------
            // Historial previo para 50 socios
            // --------------------------------------------------------

            if (i < 50)
            {
                var historico = new Medidor
                {
                    NumeroMedidor = $"OLD-{socio.RegistroSocio}",
                    Marca = marcas[(i + 1) % marcas.Length],
                    RegistroSocio = socio.RegistroSocio,

                    FechaInstalacion =
                        hoy
                            .AddYears(-8)
                            .AddDays(-(i % 700)),

                    Estado = "Retirado",
                    Latitud = latitud,
                    Longitud = longitud
                };

                context.Medidores.Add(historico);
            }

            // --------------------------------------------------------
            // Medidor actualmente activo
            // --------------------------------------------------------

            var activo = new Medidor
            {
                NumeroMedidor = $"M-{socio.RegistroSocio}",
                Marca = marcas[i % marcas.Length],
                RegistroSocio = socio.RegistroSocio,

                FechaInstalacion =
                    hoy
                        .AddYears(-3)
                        .AddDays(-(i % 500)),

                Estado = "Activo",
                Latitud = latitud,
                Longitud = longitud
            };

            medidoresActivos[socio.RegistroSocio] = activo;

            context.Medidores.Add(activo);
        }

        // ============================================================
        // 5. SOLICITUDES LECTURA
        //
        // 20 hojas x 5 detalles = 100 solicitudes.
        //
        // Grupo 1: 25 recientes pendientes
        // Grupo 2: 25 vencidas pendientes
        // Grupo 3: 25 asignadas
        // Grupo 4: 25 destinadas a trabajos completados
        // ============================================================

        var solicitudesLectura = new List<SolicitudLectura>();
        var detallesLectura = new List<DetalleSolicitudLectura>();

        var lecturaPendienteReciente =
            new List<DetalleSolicitudLectura>();

        var lecturaPendienteVencida =
            new List<DetalleSolicitudLectura>();

        var lecturaAsignada =
            new List<DetalleSolicitudLectura>();

        var lecturaCompletada =
            new List<DetalleSolicitudLectura>();

        var indiceSocioLectura = 0;

        for (var hojaIndex = 0; hojaIndex < 20; hojaIndex++)
        {
            DateTime fechaEmision;

            // 0 - 4 = 25 recientes
            if (hojaIndex < 5)
            {
                fechaEmision =
                    hoy.AddDays(-(2 + hojaIndex * 3));
            }
            // 5 - 9 = 25 vencidas (> 1 mes)
            else if (hojaIndex < 10)
            {
                fechaEmision =
                    hoy.AddDays(-(40 + (hojaIndex - 5) * 6));
            }
            // 10 - 14 = 25 asignadas
            else if (hojaIndex < 15)
            {
                fechaEmision =
                    hoy.AddDays(-(3 + (hojaIndex - 10) * 2));
            }
            // 15 - 19 = 25 completadas
            else
            {
                fechaEmision =
                    hoy.AddDays(-(8 + (hojaIndex - 15) * 4));
            }

            var numeroHoja =
                $"HL-{fechaEmision:yyyyMM}-{hojaIndex + 1:000}";

            var solicitud = new SolicitudLectura
            {
                NumeroHoja = numeroHoja,
                AnioMes = fechaEmision.ToString("yyyyMM"),
                FechaEmision = fechaEmision,
                HoraEmision = new TimeSpan(8 + hojaIndex % 3, 30, 0),
                ElaboradoPor = "Oficina Comercial COSAALT",
                CodigoObservacion = 14,

                DescripcionObservacion =
                    (hojaIndex % 3) switch
                    {
                        0 => "14 - Posible fuga después del medidor",
                        1 => "14 - Alto consumo",
                        _ => "14 - Lectura irregular"
                    }
            };

            solicitudesLectura.Add(solicitud);

            for (var detalleIndex = 0; detalleIndex < 5; detalleIndex++)
            {
                var socio =
                    socios[indiceSocioLectura % 100];

                indiceSocioLectura++;

                var lecturaAnterior =
                    500m +
                    (indiceSocioLectura * 17.35m);

                var consumo =
                    4m +
                    (indiceSocioLectura % 75);

                var lecturaActual =
                    lecturaAnterior + consumo;

                var detalle = new DetalleSolicitudLectura
                {
                    // Id_detalle está configurado con ValueGeneratedNever(),
                    // por lo que EF/SQL NO lo autogenera. Debe ser único.
                    Id = 1001 + detallesLectura.Count,
                    NumeroHoja = numeroHoja,
                    RegistroSocio = socio.RegistroSocio,

                    LecturaAnterior =
                        decimal.Round(
                            lecturaAnterior,
                            2),

                    LecturaActual =
                        decimal.Round(
                            lecturaActual,
                            2),

                    Consumo =
                        decimal.Round(
                            consumo,
                            2)
                };

                detallesLectura.Add(detalle);

                if (hojaIndex < 5)
                {
                    lecturaPendienteReciente.Add(detalle);
                }
                else if (hojaIndex < 10)
                {
                    lecturaPendienteVencida.Add(detalle);
                }
                else if (hojaIndex < 15)
                {
                    lecturaAsignada.Add(detalle);
                }
                else
                {
                    lecturaCompletada.Add(detalle);
                }
            }
        }

        context.SolicitudesLectura.AddRange(solicitudesLectura);
        context.DetallesSolicitudLectura.AddRange(detallesLectura);

        // ============================================================
        // 6. ODECO
        //
        // 100 reclamos:
        //
        // 25 recientes pendientes
        // 25 vencidos pendientes
        // 25 asignados
        // 25 destinados a completados
        //
        // Todos con conclusión CAMBIAR MEDIDOR.
        // ============================================================

        var odecoPendienteReciente =
            new List<ReclamoOdeco>();

        var odecoPendienteVencida =
            new List<ReclamoOdeco>();

        var odecoAsignada =
            new List<ReclamoOdeco>();

        var odecoCompletada =
            new List<ReclamoOdeco>();

        var reclamosOdeco = new List<ReclamoOdeco>();

        var motivosOdeco = new[]
        {
            "Medidor parado",
            "Medidor empañado",
            "Medidor destrozado",
            "Lectura irregular",
            "Posible descalibración",
            "Consumo excesivo",
            "Daño físico del medidor"
        };

        for (var i = 0; i < 100; i++)
        {
            // Los ODECO usan socios 50..149.
            var socio = socios[50 + i];

            DateTime fechaReclamo;

            if (i < 25)
            {
                // Recientes: dentro de las últimas 24 horas.
                fechaReclamo =
                    DateTime.Now.AddHours(-(2 + (i % 18)));
            }
            else if (i < 50)
            {
                // Vencidos: claramente > 24h.
                fechaReclamo =
                    hoy.AddDays(-(2 + (i % 8))).AddHours(8);
            }
            else if (i < 75)
            {
                // Asignados.
                fechaReclamo =
                    hoy.AddDays(-(1 + (i % 4))).AddHours(9);
            }
            else
            {
                // Completados.
                fechaReclamo =
                    hoy.AddDays(-(3 + (i % 12))).AddHours(10);
            }

            var lecturaAnterior =
                1000m + (i * 23.45m);

            var diferencia =
                i % 6 == 0
                    ? 0m
                    : 5m + (i % 40);

            var lecturaActual =
                lecturaAnterior + diferencia;

            var reclamo = new ReclamoOdeco
            {
                Folio = 2001 + i,

                FechaReclamo = fechaReclamo,

                RegistroSocio =
                    socio.RegistroSocio,

                NombreSolicitante =
                    socio.Nombre,

                CiSolicitante =
                    socio.Ci,

                TelefonoSolicitante =
                    socio.Telefono,

                TipoVisita =
                    "Inspección de medidor",

                MotivoReclamo =
                    motivosOdeco[i % motivosOdeco.Length],

                FechaEstimadaRespuesta =
                    fechaReclamo.AddHours(24),

                RespuestaAtencion =
                    i < 75
                        ? "Pendiente de atención técnica"
                        : "Cambio de medidor ejecutado",

                LecturaAnteriorAnalisis =
                    decimal.Round(
                        lecturaAnterior,
                        2),

                LecturaActualAnalisis =
                    decimal.Round(
                        lecturaActual,
                        2),

                ConsumoAnalisis =
                    decimal.Round(
                        diferencia,
                        2),

                Grifos =
                    i % 2 == 0
                        ? "Sin fuga visible"
                        : "Revisados",

                LlavePaso =
                    "Operativa",

                MedidorParado =
                    i % 6 == 0,

                Inspeccion =
                    "Inspección realizada en predio",

                Diagnostico =
                    motivosOdeco[i % motivosOdeco.Length],

                Comentarios =
                    "Registro generado para pruebas del sistema COSAALT.",

                TipoReclamo =
                    "Medidor",

                FechaInspeccion =
                    fechaReclamo.AddHours(2),

                Conclusion =
                    "CAMBIAR MEDIDOR",

                PrioridadNota =
                    "URGENTE"
            };

            reclamosOdeco.Add(reclamo);

            if (i < 25)
            {
                odecoPendienteReciente.Add(reclamo);
            }
            else if (i < 50)
            {
                odecoPendienteVencida.Add(reclamo);
            }
            else if (i < 75)
            {
                odecoAsignada.Add(reclamo);
            }
            else
            {
                odecoCompletada.Add(reclamo);
            }
        }

        context.ReclamosOdeco.AddRange(reclamosOdeco);

        // ============================================================
        // PRIMER SAVE
        //
        // Necesitamos que SQL genere:
        // - Id de usuarios
        // - Id de motivos
        //
        // DetalleSolicitudLectura NO es Identity:
        // su Id se asignó manualmente desde 1001 porque la configuración
        // usa ValueGeneratedNever().
        //
        // Guardamos antes de construir rutas y ejecuciones para disponer
        // de los Id generados de usuarios y motivos.
        // ============================================================

        await context.SaveChangesAsync();

        // ============================================================
        // 7. CONVERTIR SOLICITUDES EN WORK ITEMS
        // ============================================================

        var pendientesAsignados =
            new List<SeedWorkItem>();

        var completados =
            new List<SeedWorkItem>();

        foreach (var detalle in lecturaAsignada)
        {
            var socio =
                socios.Single(
                    s =>
                        s.RegistroSocio ==
                        detalle.RegistroSocio);

            var medidor =
                medidoresActivos[socio.RegistroSocio];

            pendientesAsignados.Add(
                new SeedWorkItem
                {
                    TipoOrigen = "LECTURA",
                    IdOrigen = detalle.Id.ToString(),
                    SolicitudId = $"LEC-{detalle.Id}",
                    RegistroSocio = socio.RegistroSocio,
                    NombreCliente = socio.Nombre,
                    Direccion = socio.Direccion,
                    Latitud = medidor.Latitud,
                    Longitud = medidor.Longitud,

                    FechaSolicitud =
                        solicitudesLectura
                            .Single(
                                x =>
                                    x.NumeroHoja ==
                                    detalle.NumeroHoja)
                            .FechaEmision
                });
        }

        foreach (var reclamo in odecoAsignada)
        {
            var socio =
                socios.Single(
                    s =>
                        s.RegistroSocio ==
                        reclamo.RegistroSocio);

            var medidor =
                medidoresActivos[socio.RegistroSocio];

            pendientesAsignados.Add(
                new SeedWorkItem
                {
                    TipoOrigen = "ODECO",
                    IdOrigen = reclamo.Folio.ToString(),
                    SolicitudId = $"ODECO-{reclamo.Folio}",
                    RegistroSocio = socio.RegistroSocio,
                    NombreCliente = socio.Nombre,
                    Direccion = socio.Direccion,
                    Latitud = medidor.Latitud,
                    Longitud = medidor.Longitud,
                    FechaSolicitud = reclamo.FechaReclamo
                });
        }

        foreach (var detalle in lecturaCompletada)
        {
            var socio =
                socios.Single(
                    s =>
                        s.RegistroSocio ==
                        detalle.RegistroSocio);

            var medidor =
                medidoresActivos[socio.RegistroSocio];

            completados.Add(
                new SeedWorkItem
                {
                    TipoOrigen = "LECTURA",
                    IdOrigen = detalle.Id.ToString(),
                    SolicitudId = $"LEC-{detalle.Id}",
                    RegistroSocio = socio.RegistroSocio,
                    NombreCliente = socio.Nombre,
                    Direccion = socio.Direccion,
                    Latitud = medidor.Latitud,
                    Longitud = medidor.Longitud,

                    FechaSolicitud =
                        solicitudesLectura
                            .Single(
                                x =>
                                    x.NumeroHoja ==
                                    detalle.NumeroHoja)
                            .FechaEmision
                });
        }

        foreach (var reclamo in odecoCompletada)
        {
            var socio =
                socios.Single(
                    s =>
                        s.RegistroSocio ==
                        reclamo.RegistroSocio);

            var medidor =
                medidoresActivos[socio.RegistroSocio];

            completados.Add(
                new SeedWorkItem
                {
                    TipoOrigen = "ODECO",
                    IdOrigen = reclamo.Folio.ToString(),
                    SolicitudId = $"ODECO-{reclamo.Folio}",
                    RegistroSocio = socio.RegistroSocio,
                    NombreCliente = socio.Nombre,
                    Direccion = socio.Direccion,
                    Latitud = medidor.Latitud,
                    Longitud = medidor.Longitud,
                    FechaSolicitud = reclamo.FechaReclamo
                });
        }

        // ============================================================
        // 8. RUTAS
        //
        // Tenemos:
        // 50 solicitudes asignadas pendientes
        // 50 solicitudes completadas
        //
        // Las primeras 20 completadas se mezclan en rutas EnCurso
        // para tener porcentajes reales de avance.
        //
        // Las otras 30 forman rutas Finalizadas.
        // ============================================================

        var asignador =
            usuarios.Single(
                u => u.NombreUsuario == "asignador1");

        var tecnicosActivos =
            usuarios
                .Where(
                    u =>
                        u.Rol == "tecnico" &&
                        u.Activo)
                .ToList();

        // Patrón de completadas por ruta:
        //
        // Ruta 1  => 0 completas + 5 pendientes = 0%
        // Ruta 2  => 1 completa  + 5 pendientes
        // Ruta 3  => 2 completas + 5 pendientes
        // Ruta 4  => 3 completas + 5 pendientes
        // Ruta 5  => 4 completas + 5 pendientes
        //
        // Se repite.
        //
        // Así Monitoreo tendrá bastante variedad.
        var completadasPorRuta =
            new[]
            {
                0, 1, 2, 3, 4,
                0, 1, 2, 3, 4
            };

        var indicePendiente = 0;
        var indiceCompletado = 0;

        var detallesCompletadosParaEjecucion =
            new List<(SeedWorkItem Item, DateTime FechaEjecucion, int UsuarioId)>();

        // ------------------------------------------------------------
        // 10 rutas activas
        // ------------------------------------------------------------

        for (var rutaIndex = 0; rutaIndex < 10; rutaIndex++)
        {
            UsuarioApp responsable;

            if (rutaIndex == 9)
            {
                // La última ruta activa se la asigna el asignador
                // a sí mismo.
                responsable = asignador;
            }
            else
            {
                responsable =
                    tecnicosActivos[
                        rutaIndex %
                        tecnicosActivos.Count];
            }

            var cantidadCompletadas =
                completadasPorRuta[rutaIndex];

            var ruta = new AsignacionRuta
            {
                IdUsuarioApp = responsable.Id,
                FechaAsignacion =
                    hoy.AddHours(7).AddMinutes(rutaIndex * 5),

                Estado =
                    cantidadCompletadas == 0
                        ? "Planificado"
                        : "EnCurso"
            };

            var orden = 1;

            // Cada ruta tiene 5 pendientes.
            for (var j = 0; j < 5; j++)
            {
                var item =
                    pendientesAsignados[indicePendiente++];

                ruta.Detalles.Add(
                    new DetalleRuta
                    {
                        TipoOrigen = item.TipoOrigen,
                        IdOrigen = item.IdOrigen,
                        OrdenVisita = orden++,
                        Estado = "Pendiente",
                        SolicitudId = item.SolicitudId,
                        NombreCliente = item.NombreCliente,
                        Direccion = item.Direccion,
                        Latitud = item.Latitud,
                        Longitud = item.Longitud
                    });
            }

            // Añadimos algunos completados para generar progreso.
            for (var j = 0; j < cantidadCompletadas; j++)
            {
                var item =
                    completados[indiceCompletado++];

                ruta.Detalles.Add(
                    new DetalleRuta
                    {
                        TipoOrigen = item.TipoOrigen,
                        IdOrigen = item.IdOrigen,
                        OrdenVisita = orden++,
                        Estado = "Completada",
                        SolicitudId = item.SolicitudId,
                        NombreCliente = item.NombreCliente,
                        Direccion = item.Direccion,
                        Latitud = item.Latitud,
                        Longitud = item.Longitud
                    });

                var fechaEjecucion =
                    hoy
                        .AddHours(8)
                        .AddMinutes(
                            rutaIndex * 15 + j * 5);

                detallesCompletadosParaEjecucion.Add(
                    (
                        item,
                        fechaEjecucion,
                        responsable.Id
                    ));
            }

            context.AsignacionesRuta.Add(ruta);
        }

        // ------------------------------------------------------------
        // 6 rutas finalizadas
        //
        // 5 detalles cada una = 30 trabajos completados.
        // ------------------------------------------------------------

        for (var rutaIndex = 0; rutaIndex < 6; rutaIndex++)
        {
            var responsable =
                rutaIndex == 5
                    ? asignador
                    : tecnicosActivos[
                        rutaIndex %
                        tecnicosActivos.Count];

            DateTime fechaRuta;

            // Dos rutas finalizadas HOY.
            if (rutaIndex < 2)
            {
                fechaRuta =
                    hoy.AddHours(6)
                        .AddMinutes(rutaIndex * 20);
            }
            else
            {
                fechaRuta =
                    hoy
                        .AddDays(-(rutaIndex - 1))
                        .AddHours(7);
            }

            var ruta = new AsignacionRuta
            {
                IdUsuarioApp = responsable.Id,
                FechaAsignacion = fechaRuta,
                Estado = "Finalizado"
            };

            for (var j = 0; j < 5; j++)
            {
                var item =
                    completados[indiceCompletado++];

                ruta.Detalles.Add(
                    new DetalleRuta
                    {
                        TipoOrigen = item.TipoOrigen,
                        IdOrigen = item.IdOrigen,
                        OrdenVisita = j + 1,
                        Estado = "Completada",
                        SolicitudId = item.SolicitudId,
                        NombreCliente = item.NombreCliente,
                        Direccion = item.Direccion,
                        Latitud = item.Latitud,
                        Longitud = item.Longitud
                    });

                var fechaEjecucion =
                    fechaRuta
                        .AddHours(2)
                        .AddMinutes(j * 20);

                detallesCompletadosParaEjecucion.Add(
                    (
                        item,
                        fechaEjecucion,
                        responsable.Id
                    ));
            }

            context.AsignacionesRuta.Add(ruta);
        }

        await context.SaveChangesAsync();

        // ============================================================
        // 9. EJECUCIONES DE CAMBIO
        //
        // Cada DetalleRuta Completada tendrá:
        //
        // EjecucionCambio
        // +
        // medidor viejo -> Retirado
        // +
        // medidor nuevo -> Activo
        //
        // Así realmente probamos Socio 1:N Medidores.
        // ============================================================

        var ejecuciones =
            new List<EjecucionCambio>();

        var contadorNuevoMedidor = 1;

        foreach (var trabajo in detallesCompletadosParaEjecucion)
        {
            var item = trabajo.Item;

            var medidorAnterior =
                medidoresActivos[
                    item.RegistroSocio];

            // El que estaba activo pasa a ser histórico.
            medidorAnterior.Estado = "Retirado";

            var numeroNuevo =
                $"NEW-{item.RegistroSocio}-{contadorNuevoMedidor:000}";

            var marcaNueva =
                marcas[
                    contadorNuevoMedidor %
                    marcas.Length];

            var nuevoMedidor =
                new Medidor
                {
                    NumeroMedidor = numeroNuevo,
                    Marca = marcaNueva,

                    RegistroSocio =
                        item.RegistroSocio,

                    FechaInstalacion =
                        trabajo.FechaEjecucion,

                    Estado = "Activo",

                    // Conservamos la ubicación física.
                    Latitud =
                        medidorAnterior.Latitud,

                    Longitud =
                        medidorAnterior.Longitud
                };

            context.Medidores.Add(nuevoMedidor);

            // El nuevo pasa a ser el activo actual.
            medidoresActivos[
                item.RegistroSocio] =
                nuevoMedidor;

            var motivo =
                motivos[
                    contadorNuevoMedidor %
                    motivos.Count];

            var lecturaRetiro =
                1000m +
                contadorNuevoMedidor * 37.55m;

            var ejecucion =
                new EjecucionCambio
                {
                    TipoOrigen =
                        item.TipoOrigen,

                    IdOrigen =
                        item.IdOrigen,

                    IdUsuarioApp =
                        trabajo.UsuarioId,

                    FechaHoraEjecucion =
                        trabajo.FechaEjecucion,

                    NumeroMedidorRetirado =
                        medidorAnterior.NumeroMedidor,

                    MarcaRetirado =
                        medidorAnterior.Marca,

                    LecturaRetiro =
                        decimal.Round(
                            lecturaRetiro,
                            2),

                    IdMotivo =
                        motivo.Id,

                    NumeroMedidorInstalado =
                        numeroNuevo,

                    MarcaInstalado =
                        marcaNueva,

                    ObservacionesInstalacion =
                        contadorNuevoMedidor % 4 == 0
                            ? "Medidor medio uso en buen estado"
                            : "Medidor nuevo",

                    LatLong =
                        medidorAnterior.Latitud.HasValue &&
                        medidorAnterior.Longitud.HasValue
                            ? $"{medidorAnterior.Latitud.Value:F6},{medidorAnterior.Longitud.Value:F6}"
                            : null,

                    Sincronizado = true
                };

            ejecuciones.Add(ejecucion);

            contadorNuevoMedidor++;
        }

        context.EjecucionesCambio.AddRange(ejecuciones);

        // Necesitamos los IdEjecucion generados por SQL.
        await context.SaveChangesAsync();

        // ============================================================
        // 10. EVIDENCIAS
        //
        // Dos por ejecución:
        //
        // MedidorRetirado
        // MedidorNuevo
        //
        // Son rutas ficticias. No crean archivos físicos.
        // Sirven para que la tabla tenga datos relacionados.
        // ============================================================

        var evidencias =
            new List<EvidenciaFotografica>();

        foreach (var ejecucion in ejecuciones)
        {
            evidencias.Add(
                new EvidenciaFotografica
                {
                    IdEjecucion =
                        ejecucion.Id,

                    TipoFoto =
                        "MedidorRetirado",

                    RutaArchivo =
                        $"seed/evidencias/ejecucion-{ejecucion.Id}-retirado.jpg"
                });

            evidencias.Add(
                new EvidenciaFotografica
                {
                    IdEjecucion =
                        ejecucion.Id,

                    TipoFoto =
                        "MedidorNuevo",

                    RutaArchivo =
                        $"seed/evidencias/ejecucion-{ejecucion.Id}-nuevo.jpg"
                });
        }

        context.EvidenciasFotograficas.AddRange(evidencias);

        await context.SaveChangesAsync();
    }
}