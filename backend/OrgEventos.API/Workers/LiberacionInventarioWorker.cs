using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OrgEventos.API.Models;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace TuProyecto.Workers // Ajusta tu namespace
{
    public class LiberacionInventarioWorker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;

        public LiberacionInventarioWorker(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Este ciclo se ejecuta indefinidamente mientras el servidor esté encendido
            while (!stoppingToken.IsCancellationRequested)
            {
                using (var scope = _serviceProvider.CreateScope())
                {
                    // Obtenemos el contexto de la base de datos
                    var context = scope.ServiceProvider.GetRequiredService<GestionEventosContext>();

                    // Calculamos la fecha límite (48 horas atrás desde este momento)
                    var limiteCaducidad = DateTime.Now.AddHours(-48);

                    // Buscamos Contratos en estado "Pendiente" que se crearon hace más de 48 hrs
                    var contratosVencidos = await context.Contratos
                        .Include(c => c.IdEventoNavigation)
                        .Where(c => c.Estado == "Pendiente" && c.FechaContrato <= limiteCaducidad)
                        .ToListAsync(stoppingToken);

                    foreach (var contrato in contratosVencidos)
                    {
                        // Cancelamos el contrato
                        contrato.Estado = "Cancelado";

                        // Cancelamos el evento vinculado para liberar los servicios internos
                        if (contrato.IdEventoNavigation != null)
                        {
                            contrato.IdEventoNavigation.Estado = "Cancelado";
                        }
                    }

                    // Guardamos los cambios en bloque si se encontró alguno
                    if (contratosVencidos.Any())
                    {
                        await context.SaveChangesAsync(stoppingToken);
                        Console.WriteLine($"[SISTEMA] Se liberaron {contratosVencidos.Count} eventos por falta de pago.");
                    }
                }

                // El proceso "duerme" 1 hora y luego vuelve a escanear la base de datos
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            }
        }
    }
}