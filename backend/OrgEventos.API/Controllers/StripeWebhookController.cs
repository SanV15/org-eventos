using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.Models;
using Stripe;

namespace OrgEventos.API.Controllers
{
    [Route("api/webhooks")]
    [ApiController]
    public class StripeWebhookController : ControllerBase
    {
        private readonly GestionEventosContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeWebhookController> _logger;

        public StripeWebhookController(GestionEventosContext context, IConfiguration configuration, ILogger<StripeWebhookController> logger)
        {
            _context = context;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("stripe")]
        public async Task<IActionResult> ManejarWebhooksStripe()
        {
            var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();

            try
            {
                var stripeSignature = Request.Headers["Stripe-Signature"];
                var webhookSecret = _configuration["Stripe:WebhookSecret"];

                // 1. Validar la firma digital de Stripe de forma segura
                var stripeEvent = EventUtility.ConstructEvent(json, stripeSignature, webhookSecret, throwOnApiVersionMismatch: false);

                // 2. Evaluar si el evento es un pago exitoso
                if (stripeEvent.Type == "payment_intent.succeeded")
                {
                    var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
                    if (paymentIntent != null)
                    {
                        _logger.LogInformation($"[WEBHOOK] ¡Pago exitoso confirmado por Stripe! ID: {paymentIntent.Id}, Monto: {paymentIntent.AmountReceived / 100.0}");

                        int idCuota = 0;

                        // 3. Extraer el idCuota que mandamos oculto en los metadatos
                        if (paymentIntent.Metadata != null && paymentIntent.Metadata.ContainsKey("idCuota"))
                        {
                            int.TryParse(paymentIntent.Metadata["idCuota"], out idCuota);
                        }

                        // 4. Si encontramos el ID, actualizamos la base de datos automáticamente
                        if (idCuota > 0)
                        {
                            var cuota = await _context.Cuota.FindAsync(idCuota);

                            // Validar que la cuota exista y no esté ya pagada
                            if (cuota != null && cuota.Estado != "Pagada")
                            {
                                // Actualizar el estado de la cuota
                                cuota.Estado = "Pagada";

                                // Registrar el pago en la tabla PAGO_CLIENTE
                                var pago = new PagoCliente
                                {
                                    IdCuota = cuota.IdCuota,
                                    FechaPago = DateTime.Now,
                                    Monto = paymentIntent.AmountReceived / 100.0m, // Convertir centavos a pesos
                                    MetodoPago = "T. Automatica", // Texto corto para evitar truncamientos en SQL
                                    Estado = "Completado"
                                };

                                _context.PagoClientes.Add(pago);
                                await _context.SaveChangesAsync();

                                _logger.LogInformation($"[WEBHOOK] Éxito: Cuota #{idCuota} marcada como pagada y registrada en SQL Server.");
                            }
                            else
                            {
                                _logger.LogWarning($"[WEBHOOK] La cuota #{idCuota} ya estaba pagada o no fue encontrada.");
                            }
                        }
                        else
                        {
                            _logger.LogWarning("[WEBHOOK] El PaymentIntent exitoso no contenía el metadata 'idCuota'.");
                        }
                    }
                }
                // 5. Evaluar si el pago falló
                else if (stripeEvent.Type == "payment_intent.payment_failed")
                {
                    var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
                    _logger.LogWarning($"[WEBHOOK] El pago falló en Stripe para el PaymentIntent: {paymentIntent?.Id}");
                }

                return Ok();
            }
            catch (StripeException e)
            {
                _logger.LogError($"[WEBHOOK] Error de firma o validación de Stripe: {e.Message}");
                return BadRequest(new { mensaje = "Firma de webhook inválida." });
            }
            catch (Exception ex)
            {
                _logger.LogError($"[WEBHOOK] Error interno procesando el webhook: {ex.Message}");
                return StatusCode(500, new { mensaje = "Error del servidor al procesar webhook." });
            }
        }
    }
}