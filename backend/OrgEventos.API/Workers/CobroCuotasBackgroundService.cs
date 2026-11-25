using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.Models;
using Stripe;

namespace OrgEventos.API.Workers
{
    public class CobroCuotasBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<CobroCuotasBackgroundService> _logger;

        public CobroCuotasBackgroundService(IServiceProvider serviceProvider, ILogger<CobroCuotasBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Background Worker de cobros automáticos iniciado.");

            // Ciclo que se ejecuta continuamente en segundo plano
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await ProcesarCuotasVencidasAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Ocurrió un error al procesar los cobros automáticos.");
                }

                // Esperar 24 horas antes de la siguiente verificación automática
                await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
            }
        }

        private async Task ProcesarCuotasVencidasAsync()
        {
            // Creamos un scope manual para usar el DbContext dentro del BackgroundService
            using (var scope = _serviceProvider.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<GestionEventosContext>();
                var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

                var secretKey = configuration["Stripe:SecretKey"];
                if (string.IsNullOrEmpty(secretKey)) return;
                StripeConfiguration.ApiKey = secretKey;

                var hoy = DateOnly.FromDateTime(DateTime.Today);

                // Buscar cuotas pendientes cuya fecha límite sea hoy o anterior
                var cuotasPendientes = await context.Cuota
                    .Include(c => c.IdPlanPagoNavigation)
                        .ThenInclude(pp => pp.IdContratoNavigation)
                            .ThenInclude(co => co.IdEventoNavigation)
                                .ThenInclude(e => e.IdClienteNavigation)
                    .Where(c => c.Estado == "Pendiente" && c.FechaLimite <= hoy)
                    .ToListAsync();

                foreach (var cuota in cuotasPendientes)
                {
                    try
                    {
                        var cliente = cuota.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.IdClienteNavigation;
                        if (string.IsNullOrEmpty(cliente.StripeCustomerId)) continue;

                        // Obtener el método de pago predeterminado del cliente en Stripe
                        var customerService = new CustomerService();
                        var stripeCustomer = await customerService.GetAsync(cliente.StripeCustomerId);
                        string paymentMethodId = stripeCustomer.InvoiceSettings?.DefaultPaymentMethodId;

                        if (string.IsNullOrEmpty(paymentMethodId))
                        {
                            var pmService = new PaymentMethodService();
                            var paymentMethods = await pmService.ListAsync(new PaymentMethodListOptions
                            {
                                Customer = cliente.StripeCustomerId,
                                Type = "card"
                            });
                            paymentMethodId = paymentMethods.Data.FirstOrDefault()?.Id;
                        }

                        if (string.IsNullOrEmpty(paymentMethodId)) continue;

                        // Ejecutar el cobro automático (Off-Session)
                        var options = new PaymentIntentCreateOptions
                        {
                            Amount = (long)(cuota.Monto * 100), // Convertir a centavos
                            Currency = "mxn",
                            Customer = cliente.StripeCustomerId,
                            PaymentMethod = paymentMethodId,
                            OffSession = true,
                            Confirm = true,
                        };

                        var service = new PaymentIntentService();
                        var paymentIntent = await service.CreateAsync(options);

                        if (paymentIntent.Status == "succeeded")
                        {
                            // Registrar pago exitoso en la BD
                            var pago = new PagoCliente
                            {
                                IdCuota = cuota.IdCuota,
                                FechaPago = DateTime.Now,
                                Monto = cuota.Monto,
                                MetodoPago = "Tarjeta Automática (Stripe)",
                                Estado = "Completado"
                            };

                            context.PagoClientes.Add(pago);
                            cuota.Estado = "Pagada";
                            await context.SaveChangesAsync();

                            _logger.LogInformation($"[COBRO AUTOMÁTICO] Cuota #{cuota.IdCuota} pagada exitosamente por ${cuota.Monto}.");
                        }
                    }
                    catch (StripeException ex)
                    {
                        _logger.LogWarning($"[FALLO COBRO AUTOMÁTICO] No se pudo cobrar la cuota #{cuota.IdCuota}: {ex.Message}");
                    }
                }
            }
        }
    }
}