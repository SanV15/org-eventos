using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.Hubs;
using OrgEventos.API.Models;

namespace OrgEventos.API.Workers
{
    public class CanceladorTareasWorker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<CanceladorTareasWorker> _logger;

        public CanceladorTareasWorker(IServiceProvider serviceProvider, ILogger<CanceladorTareasWorker> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Ejecutar cada 5 minutos
            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Worker de Cancelación revisando tareas vencidas...");

                using (var scope = _serviceProvider.CreateScope())
                {
                    var context = scope.ServiceProvider.GetRequiredService<GestionEventosContext>();
                    var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<EventosHub>>();

                    var ahora = DateTime.Now;
                    // Buscar tareas Pendientes o En Progreso que hayan pasado su fecha límite por más de 1 hora
                    var limiteTolerancia = ahora.AddHours(-1);

                    var tareasVencidas = await context.Tareas
                        .Where(t => (t.Estado == "Pendiente" || t.Estado == "En proceso")
                                    && t.FechaLimite != null
                                    && t.FechaLimite < limiteTolerancia)
                        .ToListAsync(stoppingToken);

                    if (tareasVencidas.Any())
                    {
                        foreach (var tarea in tareasVencidas)
                        {
                            tarea.Estado = "Cancelada";

                            // Registrar la incidencia de cancelación automática
                            context.IncidenciaTareas.Add(new IncidenciaTarea
                            {
                                IdTarea = tarea.IdTarea,
                                Observacion = "Cancelada automáticamente por sistema: Excedió el tiempo límite de tolerancia (1 hora).",
                                FechaHora = ahora
                            });

                            _logger.LogInformation($"Tarea {tarea.IdTarea} cancelada automáticamente.");

                            // Emitir a SignalR para que todos los dispositivos lo vean al instante
                            await hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("TareaEstadoActualizada", new
                            {
                                idTarea = tarea.IdTarea,
                                idEvento = tarea.IdEvento,
                                nuevoEstado = "Cancelada"
                            }, stoppingToken);
                        }

                        await context.SaveChangesAsync(stoppingToken);
                    }
                }

                // Esperar 5 minutos antes de volver a revisar
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }
    }
}