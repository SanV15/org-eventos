using Amazon;
using Amazon.S3;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using OrgEventos.API.Hubs;
using OrgEventos.API.Models;
using OrgEventos.API.Services;
using System.Text;

namespace OrgEventos.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // 1. Leer variables del appsettings.json para JWT
            var jwtIssuer = builder.Configuration["JwtSettings:Issuer"];
            var jwtAudience = builder.Configuration["JwtSettings:Audience"];
            var jwtSecretKey = builder.Configuration["JwtSettings:SecretKey"];

            // 2. Configurar el esquema de autenticación JWT (Soporta API y SignalR)
            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = jwtIssuer,
                        ValidAudience = jwtAudience,
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey!))
                    };

                    // OBLIGATORIO PARA SIGNALR: Extraer el token de la query string en WebSockets
                    options.Events = new JwtBearerEvents
                    {
                        OnMessageReceived = context =>
                        {
                            var accessToken = context.Request.Query["access_token"];
                            var path = context.HttpContext.Request.Path;
                            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                            {
                                context.Token = accessToken;
                            }
                            return Task.CompletedTask;
                        }
                    };
                });

            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();

            // Configuración Swagger
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "OrgEventos API", Version = "v1" });

                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "Ingresa 'Bearer [tu-token-jwt]'",
                    Name = "Authorization",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = "Bearer"
                });

                c.AddSecurityRequirement(new OpenApiSecurityRequirement()
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            },
                            Scheme = "oauth2",
                            Name = "Bearer",
                            In = ParameterLocation.Header,
                        },
                        new List<string>()
                    }
                });
            });

            // Configurar DbContext
            builder.Services.AddDbContext<GestionEventosContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            // Inyección de dependencias de servicios
            builder.Services.AddScoped<IClienteService, ClienteService>();
            builder.Services.AddScoped<IEmailService, EmailService>();
            builder.Services.AddScoped<ICategoriaService, CategoriaService>();
            builder.Services.AddScoped<IProveedorService, ProveedorService>();
            builder.Services.AddScoped<IServicioProveedorService, ServicioProveedorService>();
            builder.Services.AddScoped<IServicioService, ServicioService>();
            builder.Services.AddScoped<ICotizacionService, CotizacionService>();
            builder.Services.AddScoped<IFinanzasService, FinanzasService>();
            builder.Services.AddScoped<IUsuariosService, UsuariosService>();
            builder.Services.AddHostedService<TuProyecto.Workers.LiberacionInventarioWorker>();

            builder.Services.AddHostedService<OrgEventos.API.Workers.CanceladorTareasWorker>();

            // Agrega esta línea en tu Program.cs junto a las demás inyecciones de servicios
            builder.Services.AddHostedService<OrgEventos.API.Workers.CobroCuotasBackgroundService>();

            // 3. Registrar SignalR
            builder.Services.AddSignalR();

            // 4. REGISTRAR UNA ÚNICA POLÍTICA CORS (Válida para HTTP normal y WebSockets de SignalR)
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAllOriginsWithSignalR", policy =>
                {
                    policy.WithOrigins(
                            "http://localhost:4200",
                            "https://localhost:4200"
                          )
                          .AllowAnyHeader()
                          .AllowAnyMethod()
                          .AllowCredentials(); // Habilita credenciales requeridas por SignalR
                });
            });

            Stripe.StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"];

            builder.Services.AddSingleton<GoogleCalendarService>();

            builder.Services.AddSingleton<IAmazonS3>(sp =>
            {
                var config = sp.GetRequiredService<IConfiguration>();
                var accessKey = config["AWS:AccessKey"];
                var secretKey = config["AWS:SecretKey"];
                var region = RegionEndpoint.GetBySystemName(config["AWS:Region"] ?? "us-west-2");

                return new AmazonS3Client(accessKey, secretKey, region);
            });

            var app = builder.Build();

            // Configuración del pipeline de middlewares (EL ORDEN IMPORTA)
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            // CORS DEBE IR AQUÍ: Inmediatamente después de UseRouting y antes de Authentication
            app.UseCors("AllowAllOriginsWithSignalR");

            app.UseAuthentication();
            app.UseAuthorization();

            // Mapeo de Controladores y Hubs
            app.MapControllers();
            app.MapHub<EventosHub>("/hubs/eventos");

            app.Run();
        }
    }
}