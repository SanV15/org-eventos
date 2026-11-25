using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs.Finanzas;
using OrgEventos.API.Services;
using OrgEventos.API.Models;
using System.Security.Claims;
using OrgEventos.API.DTOs.Finanzas;
using Stripe;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FinanzasController : ControllerBase
    {
        private readonly IFinanzasService _finanzasService;
        private readonly GestionEventosContext _context;
        private readonly IConfiguration _config;

        public FinanzasController(
            IFinanzasService finanzasService, 
            GestionEventosContext context,
            IConfiguration config)
        {
            _finanzasService = finanzasService;
            _context = context;
            _config = config;
        }

        [HttpPost("cliente")]
        public async Task<IActionResult> RegistrarPagoCliente([FromBody] RegistrarPagoClienteDTO dto)
        {
            try
            {
                var exito = await _finanzasService.RegistrarPagoClienteAsync(dto);
                if (!exito) return BadRequest(new { mensaje = "No se pudo registrar el pago." });
                return Ok(new { mensaje = "Pago registrado exitosamente." });
            }
            catch (Exception ex)
            {
                // ESTO EXTRAE EL ERROR VERDADERO DE SQL SERVER
                var errorReal = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { mensaje = "Error al registrar el pago", error = errorReal });
            }
        }

        [HttpPost("proveedor")]
        public async Task<IActionResult> RegistrarPagoProveedor([FromBody] RegistrarPagoProveedorDTO dto)
        {
            try
            {
                var resultado = await _finanzasService.RegistrarPagoProveedorAsync(dto);
                if (!resultado)
                    return BadRequest(new { mensaje = "No se encontró la asignación del proveedor." });

                return Ok(new { mensaje = "Egreso registrado exitosamente." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al registrar el pago", error = ex.Message });
            }
        }

        [HttpGet("resumen")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ObtenerResumenFinanciero()
        {
            try
            {
                // 1. Dinero total ingresado en caja (con protección por si la tabla está vacía)
                var totalCaja = await _context.PagoClientes
                    .Select(p => (decimal?)p.Monto)
                    .SumAsync() ?? 0m;

                // 2. Obtenemos las cuotas pendientes proyectando la subconsulta escalar en SELECT (SQL válido)
                // y ejecutamos ToListAsync() antes de calcular la suma total en C#.
                var cuotasPendientes = await _context.Contratos
                    .Where(c => (c.Estado == "Activo" || c.Estado == "Pendiente") && c.PlanPago != null)
                    .SelectMany(c => c.PlanPago.Cuota)
                    .Where(cu => cu.Estado == "Pendiente")
                    .Select(cu => new
                    {
                        MontoCuota = cu.Monto,
                        Abonado = cu.PagoClientes.Sum(p => (decimal?)p.Monto) ?? 0m
                    })
                    .ToListAsync();

                var cuentasPorCobrar = cuotasPendientes.Sum(c => c.MontoCuota - c.Abonado);

                // 3. Egresos totales a proveedores
                var egresos = await _context.PagoProveedors
                    .Select(p => (decimal?)p.Monto)
                    .SumAsync() ?? 0m;

                return Ok(new ResumenFinancieroDTO
                {
                    TotalEnCaja = totalCaja,
                    CuentasPorCobrar = cuentasPorCobrar,
                    EgresosTotales = egresos
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al calcular el resumen financiero.", detalle = ex.Message });
            }
        }

        [HttpGet("cobranza-activa")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ObtenerCobranzaActiva()
        {
            try
            {
                var cobranza = await _context.Contratos
                    .Include(c => c.IdEventoNavigation)
                        .ThenInclude(e => e.IdClienteNavigation)
                    .Include(c => c.PlanPago)
                        .ThenInclude(p => p.Cuota)
                    .Where(c => (c.Estado == "Activo" || c.Estado == "Pendiente") && c.PlanPago != null)
                    .Select(c => new CobranzaActivaDTO
                    {
                        IdContrato = c.IdContrato,
                        IdCliente = c.IdEventoNavigation.IdCliente,
                        Cliente = c.IdEventoNavigation.IdClienteNavigation.Nombre + " " + c.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno,
                        NombreEvento = c.IdEventoNavigation.Nombre,
                        TotalContrato = c.MontoAcordado,
                        SaldoPendiente = c.PlanPago.Cuota
                            .Where(cu => cu.Estado == "Pendiente")
                            .Sum(cu => cu.Monto),
                        ProximoVencimiento = c.PlanPago.Cuota
                            .Where(cu => cu.Estado == "Pendiente")
                            .OrderBy(cu => cu.FechaLimite)
                            .Select(cu => (DateTime?)new DateTime(cu.FechaLimite.Year, cu.FechaLimite.Month, cu.FechaLimite.Day))
                            .FirstOrDefault()
                    })
                    .ToListAsync();

                foreach (var cobro in cobranza)
                {
                    if (cobro.ProximoVencimiento.HasValue)
                    {
                        var diasRestantes = (cobro.ProximoVencimiento.Value.Date - DateTime.Now.Date).TotalDays;
                        cobro.EstadoMorosidad = diasRestantes < 0 ? "Atrasado" : (diasRestantes == 0 ? "Vence hoy" : "Al día");
                    }
                    else
                    {
                        cobro.EstadoMorosidad = "Sin cuotas pendientes";
                    }
                }

                return Ok(cobranza.Where(c => c.SaldoPendiente > 0).OrderBy(c => c.ProximoVencimiento));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener la cobranza activa.", detalle = ex.Message });
            }
        }

        [HttpGet("flujo-caja")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ObtenerFlujoCaja()
        {
            try
            {
                // 1. Ingresos registrados
                var ingresos = await _context.PagoClientes
                    .Include(p => p.IdCuotaNavigation)
                        .ThenInclude(cu => cu.IdPlanPagoNavigation)
                            .ThenInclude(pp => pp.IdContratoNavigation)
                                .ThenInclude(c => c.IdEventoNavigation)
                                    .ThenInclude(e => e.IdClienteNavigation)
                    .Select(p => new TransaccionDTO
                    {
                        Fecha = p.FechaPago,
                        Tipo = "Ingreso",
                        Entidad = p.IdCuotaNavigation.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.IdClienteNavigation.Nombre + " " +
                                  p.IdCuotaNavigation.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno,
                        Concepto = $"Cuota #{p.IdCuotaNavigation.NumeroCuota} - {p.IdCuotaNavigation.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.Nombre} ({p.MetodoPago})",
                        Monto = p.Monto
                    })
                    .ToListAsync();

                // 2. Egresos registrados
                var egresos = await _context.PagoProveedors
                    .Include(p => p.IdEventoProveedorNavigation)
                        .ThenInclude(ep => ep.IdServicioProveedorNavigation)
                            .ThenInclude(sp => sp.IdProveedorNavigation)
                    .Include(p => p.IdEventoProveedorNavigation)
                        .ThenInclude(ep => ep.IdEventoNavigation)
                    .Select(p => new TransaccionDTO
                    {
                        Fecha = p.FechaPago,
                        Tipo = "Egreso",
                        Entidad = p.IdEventoProveedorNavigation.IdServicioProveedorNavigation.IdProveedorNavigation.Nombre,
                        Concepto = $"Pago proveedor - {p.IdEventoProveedorNavigation.IdEventoNavigation.Nombre} ({p.MetodoPago})",
                        Monto = p.Monto
                    })
                    .ToListAsync();

                // 3. Unir y ordenar cronológicamente (más recientes primero)
                var transacciones = ingresos.Concat(egresos)
                    .OrderByDescending(t => t.Fecha)
                    .ToList();

                return Ok(transacciones);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener el flujo de caja.", detalle = ex.Message });
            }
        }

        [HttpGet("contrato/{idContrato}/estado-cuenta")]
        [Authorize] // <-- Exige que haya un token válido
        public async Task<IActionResult> ObtenerEstadoCuenta(int idContrato)
        {
            try
            {
                // 1. Obtenemos el Rol y el IdUsuario del token de quien inició sesión
                var rolActivo = User.FindFirst(ClaimTypes.Role)?.Value;
                var idUsuarioString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                      ?? User.FindFirst("id")?.Value; // Dependiendo de cómo lo llamaste en tu AuthController

                _ = int.TryParse(idUsuarioString, out int idUsuarioActivo);

                // 2. Traemos los datos financieros
                var resultado = await _finanzasService.ObtenerEstadoCuentaAsync(idContrato);

                if (resultado == null)
                    return NotFound(new { mensaje = "No se encontró el contrato o no tiene un plan de pagos." });

                // 3. LA LÓGICA DE PRIVACIDAD
                if (rolActivo == "Cliente")
                {
                    // Necesitamos verificar que este contrato le pertenezca al cliente logueado.
                    // Vamos a consultar rápidamente a la BD si el evento de este contrato le pertenece a este usuario
                    var esDuenio = await _context.Contratos
                        .Include(c => c.IdEventoNavigation)
                            .ThenInclude(e => e.IdClienteNavigation)
                        .AnyAsync(c => c.IdContrato == idContrato && c.IdEventoNavigation.IdClienteNavigation.IdUsuario == idUsuarioActivo);

                    if (!esDuenio)
                    {
                        // Si intenta ver el contrato de otro, le bloqueamos el paso (403 Forbidden)
                        return StatusCode(403, new { mensaje = "Acceso denegado. Este contrato no te pertenece." });
                    }
                }

                // Si es Admin, Coordinador o el dueño legítimo, le mandamos los datos
                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener el estado de cuenta", error = ex.Message });
            }
        }

        [HttpGet("cliente/{idCliente}/estado-cuenta")]
        [Authorize]
        public async Task<IActionResult> ObtenerEstadoCuentaPorCliente(int idCliente)
        {
            try
            {
                // 1. Privacidad: Validar quién hace la petición
                var rolActivo = User.FindFirst(ClaimTypes.Role)?.Value;
                var idUsuarioString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                      ?? User.FindFirst("id")?.Value;

                _ = int.TryParse(idUsuarioString, out int idUsuarioActivo);

                if (rolActivo == "Cliente")
                {
                    // Si es un cliente, verificamos que no intente espiar el idCliente de otro
                    var clienteSolicitado = await _context.Clientes.FindAsync(idCliente);
                    if (clienteSolicitado == null || clienteSolicitado.IdUsuario != idUsuarioActivo)
                    {
                        return StatusCode(403, new { mensaje = "Acceso denegado. No puedes ver finanzas de otras personas." });
                    }
                }

                // 2. Traer los datos
                var resultado = await _finanzasService.ObtenerEstadoCuentaPorClienteAsync(idCliente);

                if (resultado == null)
                    return NotFound(new { mensaje = "El cliente aún no tiene un contrato activo." });

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener el estado de cuenta", error = ex.Message });
            }
        }

        [HttpGet("contratos")]
        [Authorize(Roles = "Administrador,Recepcionista,Coordinador")] // Protección estricta
        public async Task<IActionResult> ObtenerTodosLosContratos()
        {
            try
            {
                var contratos = await _finanzasService.ObtenerTodosLosContratosAsync();
                return Ok(contratos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener la lista de contratos globales.", detalle = ex.Message });
            }
        }
        //Proveedores.
        [HttpGet("proveedores-pendientes")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ObtenerProveedoresPendientes()
        {
            try
            {
                var pendientes = await _context.EventoProveedors
                    .Include(ep => ep.IdEventoNavigation)
                    .Include(ep => ep.IdServicioProveedorNavigation)
                        .ThenInclude(sp => sp.IdProveedorNavigation)
                    .Include(ep => ep.PagoProveedors)
                    .Select(ep => new PagoProveedorPendienteDTO
                    {
                        IdEventoProveedor = ep.IdEventoProveedor,
                        Proveedor = ep.IdServicioProveedorNavigation.IdProveedorNavigation.Nombre,
                        Servicio = ep.IdServicioProveedorNavigation.NombreServicio,
                        Evento = ep.IdEventoNavigation.Nombre,
                        CostoAcordado = ep.CostoAcordado,
                        MontoPagado = ep.PagoProveedors.Sum(p => p.Monto),
                        SaldoPendiente = ep.CostoAcordado - ep.PagoProveedors.Sum(p => p.Monto),
                        Estado = (ep.CostoAcordado - ep.PagoProveedors.Sum(p => p.Monto)) <= 0 ? "Liquidado" : "Pendiente",

                        // --- MAPEA LOS DATOS BANCARIOS AQUí ---
                        Banco = ep.IdServicioProveedorNavigation.IdProveedorNavigation.Banco,
                        ClabeInterbancaria = ep.IdServicioProveedorNavigation.IdProveedorNavigation.ClabeInterbancaria,
                        TitularCuenta = ep.IdServicioProveedorNavigation.IdProveedorNavigation.TitularCuenta
                    })
                    .Where(p => p.SaldoPendiente > 0)
                    .ToListAsync();

                return Ok(pendientes);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener egresos pendientes.", detalle = ex.Message });
            }
        }

        [HttpPost("crear-intent-pago")]
        [Authorize]
        public async Task<IActionResult> CrearIntentPago([FromBody] MontoRequestDTO request)
        {
            try
            {
                //Stripe.StripeConfiguration.ApiKey = secretKey;

                var secretKey = _config["Stripe:SecretKey"];
                if (string.IsNullOrEmpty(secretKey))
                    return BadRequest(new { mensaje = "La llave secreta de Stripe no está configurada." });

                Stripe.StripeConfiguration.ApiKey = secretKey;
                /////

                var idUsuarioStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                    ?? User.FindFirst("id")?.Value;

                if (!int.TryParse(idUsuarioStr, out int idUsuario))
                    return Unauthorized(new { mensaje = "Token no válido." });

                var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.IdUsuario == idUsuario);
                if (cliente == null)
                    return NotFound(new { mensaje = "Cliente no encontrado en la base de datos." });

                // 1. BUSCAR LA CUOTA PENDIENTE ACTUAL DEL CLIENTE AUTOMÁTICAMENTE
                var cuotaPendiente = await _context.Cuota
                    .Include(c => c.IdPlanPagoNavigation)
                        .ThenInclude(p => p.IdContratoNavigation)
                            .ThenInclude(co => co.IdEventoNavigation)
                    .Where(c => c.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.IdCliente == cliente.IdCliente
                                && c.Estado == "Pendiente")
                    .OrderBy(c => c.NumeroCuota)
                    .FirstOrDefaultAsync();

                if (cuotaPendiente == null)
                    return BadRequest(new { mensaje = "No tienes cuotas pendientes por pagar." });

                string customerId = cliente.StripeCustomerId;

                if (string.IsNullOrEmpty(customerId))
                {
                    var customerOptions = new Stripe.CustomerCreateOptions
                    {
                        Name = $"{cliente.Nombre} {cliente.ApellidoPaterno}",
                        Email = cliente.Correo,
                        Phone = cliente.Telefono
                    };
                    var customerService = new Stripe.CustomerService();
                    var stripeCustomer = await customerService.CreateAsync(customerOptions);

                    customerId = stripeCustomer.Id;
                    cliente.StripeCustomerId = customerId;
                    await _context.SaveChangesAsync();
                }

                // 2. CONFIGURAR EL PAYMENT INTENT AGREGANDO EL METADATA
                var options = new Stripe.PaymentIntentCreateOptions
                {
                    Amount = (long)(request.Monto * 100),
                    Currency = "mxn",
                    Customer = customerId,
                    SetupFutureUsage = "off_session",
                    AutomaticPaymentMethods = new Stripe.PaymentIntentAutomaticPaymentMethodsOptions
                    {
                        Enabled = true,
                    },
                    Metadata = new Dictionary<string, string>
            {
                { "idCuota", cuotaPendiente.IdCuota.ToString() } // <-- Esto es lo que leerá el Webhook
            }
                };

                var service = new Stripe.PaymentIntentService();
                var paymentIntent = await service.CreateAsync(options);

                return Ok(new { clientSecret = paymentIntent.ClientSecret });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al procesar la pasarela de pago.", detalle = ex.Message });
            }
        }

        [HttpPost("crear-setup-intent")]
        [Authorize]
        public async Task<IActionResult> CrearSetupIntent()
        {
            try
            {
                // Asignar API Key explícitamente
                var secretKey = _config["Stripe:SecretKey"];
                if (string.IsNullOrEmpty(secretKey))
                    return BadRequest(new { mensaje = "La llave secreta de Stripe no está configurada." });

                Stripe.StripeConfiguration.ApiKey = secretKey;

                var idUsuarioStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                      ?? User.FindFirst("id")?.Value;

                if (!int.TryParse(idUsuarioStr, out int idUsuario))
                    return Unauthorized(new { mensaje = "Token no válido." });

                var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.IdUsuario == idUsuario);
                if (cliente == null || string.IsNullOrEmpty(cliente.StripeCustomerId))
                    return NotFound(new { mensaje = "Cliente o ID de Stripe no encontrado." });

                // 3. Crear el SetupIntent en Stripe para este cliente
                var options = new Stripe.SetupIntentCreateOptions
                {
                    Customer = cliente.StripeCustomerId,
                    AutomaticPaymentMethods = new Stripe.SetupIntentAutomaticPaymentMethodsOptions
                    {
                        Enabled = true,
                    },
                    Usage = "off_session" // Permite cobros futuros automáticos con esta tarjeta
                };

                var service = new Stripe.SetupIntentService();
                var setupIntent = await service.CreateAsync(options);

                return Ok(new { clientSecret = setupIntent.ClientSecret });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al configurar la pasarela.", detalle = ex.Message });
            }
        }

        [HttpGet("mis-eventos")]
        [Authorize(Roles = "Cliente")]
        public async Task<IActionResult> ObtenerMisEventos()
        {
            try
            {
                // 1. Extraer IdUsuario del token seguro
                var idUsuarioString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                      ?? User.FindFirst("id")?.Value;

                if (!int.TryParse(idUsuarioString, out int idUsuarioActivo))
                    return Unauthorized(new { mensaje = "Token inválido." });

                // 2. Consultar todos los contratos ligados al usuario
                var contratos = await _context.Contratos
                    .Include(c => c.IdEventoNavigation)
                        .ThenInclude(e => e.IdClienteNavigation)
                    .Include(c => c.PlanPago)
                        .ThenInclude(pp => pp.Cuota)
                            .ThenInclude(cu => cu.PagoClientes)
                    .Where(c => c.IdEventoNavigation.IdClienteNavigation.IdUsuario == idUsuarioActivo)
.Select(c => new MiEventoDTO
{
    IdContrato = c.IdContrato,
    IdEvento = c.IdEventoNavigation.IdEvento,
    NombreEvento = c.IdEventoNavigation.Nombre,
    // Conversión segura de DateOnly a DateTime para LINQ / EF Core
    FechaEvento = new DateTime(
        c.IdEventoNavigation.FechaEvento.Year,
        c.IdEventoNavigation.FechaEvento.Month,
        c.IdEventoNavigation.FechaEvento.Day),
    EstadoContrato = c.Estado,
    TotalContrato = c.MontoAcordado,
    MontoAbonado = c.PlanPago != null
        ? c.PlanPago.Cuota.SelectMany(cu => cu.PagoClientes).Sum(p => (decimal?)p.Monto) ?? 0m
        : 0m,
    SaldoRestante = c.PlanPago != null
        ? c.MontoAcordado - (c.PlanPago.Cuota.SelectMany(cu => cu.PagoClientes).Sum(p => (decimal?)p.Monto) ?? 0m)
        : c.MontoAcordado,
    Cuotas = c.PlanPago != null ? c.PlanPago.Cuota.Select(cu => new CuotaDTO
    {
        IdCuota = cu.IdCuota,
        NumeroCuota = cu.NumeroCuota,
        FechaLimite = new DateTime(cu.FechaLimite.Year, cu.FechaLimite.Month, cu.FechaLimite.Day),
        MontoTotal = cu.Monto,
        MontoAbonado = cu.PagoClientes.Sum(p => (decimal?)p.Monto) ?? 0m,
        SaldoRestante = cu.Monto - (cu.PagoClientes.Sum(p => (decimal?)p.Monto) ?? 0m),
        Estado = cu.Estado
    }).ToList() : new List<CuotaDTO>()
})
                    .ToListAsync();

                if (!contratos.Any())
                    return NotFound(new { mensaje = "Aún no tienes un contrato o evento activo asignado." });

                return Ok(contratos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener tus eventos.", detalle = ex.Message });
            }
        }

        [HttpPost("cobrar-cuota-automatica/{idCuota}")]
        [Authorize(Roles = "Administrador")] // O accesible por un worker programado
        public async Task<IActionResult> CobrarCuotaAutomatica(int idCuota)
        {
            try
            {
                // 1. Asignar la llave secreta de Stripe
                var secretKey = _config["Stripe:SecretKey"];
                if (string.IsNullOrEmpty(secretKey))
                    return BadRequest(new { mensaje = "La llave secreta de Stripe no está configurada." });

                Stripe.StripeConfiguration.ApiKey = secretKey;

                // 2. Buscar la cuota y los datos del cliente usando los nombres reales del Context
                var cuota = await _context.Cuota // Cambia a _context.Cuota si tu context usa ese nombre
                    .Include(c => c.IdPlanPagoNavigation)
                        .ThenInclude(pp => pp.IdContratoNavigation) // Nombre correcto de la navegación en PlanPago
                            .ThenInclude(co => co.IdEventoNavigation)
                                .ThenInclude(e => e.IdClienteNavigation)
                    .FirstOrDefaultAsync(c => c.IdCuota == idCuota);

                if (cuota == null || cuota.Estado == "Pagada")
                    return BadRequest(new { mensaje = "Cuota no encontrada o ya se encuentra pagada." });

                var cliente = cuota.IdPlanPagoNavigation.IdContratoNavigation.IdEventoNavigation.IdClienteNavigation;
                if (string.IsNullOrEmpty(cliente.StripeCustomerId))
                    return BadRequest(new { mensaje = "El cliente no cuenta con un perfil de Stripe asociado." });

                // 3. Obtener el método de pago predeterminado del cliente en Stripe
                var customerService = new Stripe.CustomerService();
                var stripeCustomer = await customerService.GetAsync(cliente.StripeCustomerId);
                string paymentMethodId = stripeCustomer.InvoiceSettings?.DefaultPaymentMethodId;

                if (string.IsNullOrEmpty(paymentMethodId))
                {
                    // Si no tiene uno por defecto, tomamos la tarjeta guardada más reciente
                    var pmService = new Stripe.PaymentMethodService();
                    var paymentMethods = await pmService.ListAsync(new Stripe.PaymentMethodListOptions
                    {
                        Customer = cliente.StripeCustomerId,
                        Type = "card"
                    });
                    paymentMethodId = paymentMethods.Data.FirstOrDefault()?.Id;
                }

                if (string.IsNullOrEmpty(paymentMethodId))
                    return BadRequest(new { mensaje = "El cliente no tiene ninguna tarjeta guardada para realizar el cobro automático." });

                // 4. Crear y confirmar el PaymentIntent para cobrar automáticamente (Off-Session)
                var options = new Stripe.PaymentIntentCreateOptions
                {
                    Amount = (long)(cuota.Monto * 100), // Monto en centavos
                    Currency = "mxn",
                    Customer = cliente.StripeCustomerId,
                    PaymentMethod = paymentMethodId,
                    OffSession = true, // Indica que el cobro es automático sin que el usuario esté presente
                    Confirm = true,     // Ejecuta el cobro de inmediato
                };

                var service = new Stripe.PaymentIntentService();
                var paymentIntent = await service.CreateAsync(options);

                if (paymentIntent.Status == "succeeded")
                {
                    // 5. Registrar el pago en la base de datos de SQL Server de forma exitosa
                    var pago = new PagoCliente
                    {
                        IdCuota = cuota.IdCuota,
                        FechaPago = DateTime.Now,
                        Monto = cuota.Monto,
                        MetodoPago = "Tarjeta Automática (Stripe)",
                        Estado = "Completado"
                    };

                    _context.PagoClientes.Add(pago);
                    cuota.Estado = "Pagada";
                    await _context.SaveChangesAsync();

                    return Ok(new { mensaje = "Cobro automático procesado con éxito.", paymentIntentId = paymentIntent.Id });
                }
                else
                {
                    return BadRequest(new { mensaje = "El cobro automático requiere autenticación bancaria adicional (3D Secure).", status = paymentIntent.Status });
                }
            }
            catch (Stripe.StripeException ex)
            {
                return StatusCode(500, new { mensaje = "Error en la pasarela de Stripe al cobrar automáticamente.", detalle = ex.Message });
            }
        }
    }
}