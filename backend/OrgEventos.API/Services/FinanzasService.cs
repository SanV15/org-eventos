//using Microsoft.EntityFrameworkCore;
//using OrgEventos.API.DTOs.Finanzas;
//using OrgEventos.API.Models;
//using Stripe;
//using System.Linq.Expressions;
//using System.Runtime.CompilerServices;

//namespace OrgEventos.API.Services
//{
//    public class FinanzasService : IFinanzasService
//    {
//        private readonly GestionEventosContext _context;

//        public FinanzasService(GestionEventosContext context)
//        {
//            _context = context;
//        }



//        //public async Task<bool> RegistrarPagoClienteAsync(RegistrarPagoClienteDTO dto)
//        //{
//        //    using var transaction = await _context.Database.BeginTransactionAsync();
//        //    try
//        //    {
//        //        // 1. Buscamos la cuota con todo su árbol de relaciones (Plan y Contrato)
//        //        var cuota = await _context.Cuota
//        //            .Include(c => c.PagoClientes)
//        //            .Include(c => c.IdPlanPagoNavigation)
//        //                .ThenInclude(p => p.Cuota)
//        //            .Include(c => c.IdPlanPagoNavigation)
//        //                .ThenInclude(p => p.IdContratoNavigation)
//        //            .FirstOrDefaultAsync(c => c.IdCuota == dto.IdCuota);

//        //        if (cuota == null) return false;

//        //        // 2. Validar que no nos paguen más del saldo restante
//        //        decimal abonado = cuota.PagoClientes.Sum(p => p.Monto);
//        //        decimal restante = cuota.Monto - abonado;

//        //        if (dto.MontoPagado > restante)
//        //            throw new Exception($"El monto supera el saldo restante de la cuota. Restante: ${restante}");

//        //        // 3. Registrar el ingreso en PAGO_CLIENTE
//        //        var nuevoPago = new PagoCliente
//        //        {
//        //            IdCuota = dto.IdCuota,
//        //            Monto = dto.MontoPagado,
//        //            FechaPago = dto.FechaPago,
//        //            MetodoPago = dto.MetodoPago,
//        //            Estado = "Completado"
//        //        };
//        //        _context.PagoClientes.Add(nuevoPago);
//        //        await _context.SaveChangesAsync(); // Guardamos para actualizar la suma

//        //        // 4. Automatización de Estados: ¿Se liquidó la cuota?
//        //        if (abonado + dto.MontoPagado >= cuota.Monto)
//        //        {
//        //            cuota.Estado = "Pagada";
//        //            await _context.SaveChangesAsync();
//        //        }

//        //        // 5. Automatización de Estados: ¿Se liquidó todo el contrato?
//        //        var plan = cuota.IdPlanPagoNavigation;
//        //        if (plan.Cuota.All(c => c.Estado == "Pagada"))
//        //        {
//        //            plan.Estado = "Pagado";
//        //            plan.IdContratoNavigation.Estado = "Liquidado";
//        //            await _context.SaveChangesAsync();
//        //        }

//        //        await transaction.CommitAsync();
//        //        return true;
//        //    }
//        //    catch (Exception)
//        //    {
//        //        await transaction.RollbackAsync();
//        //        throw;
//        //    }
//        //}
//        public async Task<bool> RegistrarPagoClienteAsync(RegistrarPagoClienteDTO dto)
//        {
//            using var transaction = await _context.Database.BeginTransactionAsync();
//            try
//            {
//                // 1. Buscamos la cuota con todo su árbol de relaciones (Plan, Contrato y EVENTO)
//                var cuota = await _context.Cuota
//                    .Include(c => c.PagoClientes)
//                    .Include(c => c.IdPlanPagoNavigation)
//                        .ThenInclude(p => p.Cuota)
//                    .Include(c => c.IdPlanPagoNavigation)
//                        .ThenInclude(p => p.IdContratoNavigation)
//                            .ThenInclude(co => co.IdEventoNavigation)
//                    .FirstOrDefaultAsync(c => c.IdCuota == dto.IdCuota);

//                if (cuota == null)
//                    throw new Exception("La cuota especificada no existe.");

//                // NUEVA VALIDACIÓN COMERCIAL: No permitir abonos a cuotas ya pagadas
//                if (cuota.Estado == "Pagada")
//                    throw new Exception("Esta cuota ya se encuentra totalmente liquidada.");

//                // 2. Validar que no nos paguen más del saldo restante
//                decimal abonado = cuota.PagoClientes.Sum(p => p.Monto);
//                decimal restante = cuota.Monto - abonado;

//                if (dto.MontoPagado <= 0)
//                    throw new Exception("El monto del pago debe ser mayor a cero.");

//                if (dto.MontoPagado > restante)
//                    throw new Exception($"El monto (${dto.MontoPagado}) supera el saldo restante de la cuota (${restante}).");

//                // 3. Registrar el ingreso en PAGO_CLIENTE
//                var nuevoPago = new PagoCliente
//                {
//                    IdCuota = dto.IdCuota,
//                    Monto = dto.MontoPagado,
//                    FechaPago = dto.FechaPago,
//                    MetodoPago = dto.MetodoPago,
//                    Estado = "Completado"
//                };
//                _context.PagoClientes.Add(nuevoPago);


//                // --- INICIO DE LA NUEVA LÓGICA DE ACTIVACIÓN ---
//                var contrato = cuota.IdPlanPagoNavigation.IdContratoNavigation;
//                var evento = contrato.IdEventoNavigation;

//                // Si el contrato estaba bloqueado esperando este primer pago, lo liberamos
//                if (contrato.Estado == "Pendiente")
//                {
//                    contrato.Estado = "Activo"; // El contrato sí puede ser 'Activo' (si su restricción lo permite)
//                    evento.Estado = "En planificación"; // <-- ¡LA PALABRA MÁGICA DE TU BASE DE DATOS!
//                }
//                // --- FIN DE LA NUEVA LÓGICA ---


//                await _context.SaveChangesAsync(); // Guardamos el pago y los cambios de estado del contrato/evento

//                // 4. Automatización de Estados: ¿Se liquidó la cuota?
//                if (abonado + dto.MontoPagado >= cuota.Monto)
//                {
//                    cuota.Estado = "Pagada";
//                    await _context.SaveChangesAsync();
//                }

//                // 5. Automatización de Estados: ¿Se liquidó todo el contrato?
//                var plan = cuota.IdPlanPagoNavigation;
//                if (plan.Cuota.All(c => c.Estado == "Pagada"))
//                {
//                    plan.Estado = "Pagado";
//                    plan.IdContratoNavigation.Estado = "Liquidado";
//                    await _context.SaveChangesAsync();
//                }

//                await transaction.CommitAsync();
//                return true;
//            }
//            catch (Exception ex)
//            {
//                await transaction.RollbackAsync();

//                // PISTAS GIGANTES EN LA CONSOLA DE VISUAL STUDIO
//                Console.WriteLine("\n\n============= ¡ERROR CRÍTICO EN FINANZAS! =============");
//                Console.WriteLine($"MENSAJE PRINCIPAL: {ex.Message}");
//                if (ex.InnerException != null)
//                {
//                    Console.WriteLine($"CULPABLE REAL (INNER): {ex.InnerException.Message}");
//                }
//                Console.WriteLine($"¿DÓNDE OCURRIÓ?: {ex.StackTrace}");
//                Console.WriteLine("=======================================================\n\n");

//                throw; // Volvemos a lanzar el error
//            }
//        }


//        public async Task<bool> RegistrarPagoProveedorAsync(RegistrarPagoProveedorDTO dto)
//        {
//            using var transaction = await _context.Database.BeginTransactionAsync();
//            try
//            {
//                // 1. Buscamos la asignación del proveedor al evento con sus pagos previos
//                var eventoProveedor = await _context.EventoProveedors
//                    .Include(ep => ep.PagoProveedors)
//                    .FirstOrDefaultAsync(ep => ep.IdEventoProveedor == dto.IdEventoProveedor);

//                if (eventoProveedor == null) return false;

//                // 2. Validaciones comerciales
//                if (dto.MontoPagado <= 0)
//                    throw new Exception("El monto del pago debe ser mayor a cero.");

//                decimal totalPagado = eventoProveedor.PagoProveedors.Sum(p => p.Monto);
//                decimal saldoPendiente = eventoProveedor.CostoAcordado - totalPagado;

//                if (dto.MontoPagado > saldoPendiente)
//                    throw new Exception($"El monto (${dto.MontoPagado}) supera el saldo pendiente con el proveedor (${saldoPendiente}).");

//                // 3. Registrar el egreso en PAGO_PROVEEDOR
//                var nuevoPago = new PagoProveedor
//                {
//                    IdEventoProveedor = dto.IdEventoProveedor,
//                    Monto = dto.MontoPagado,
//                    FechaPago = dto.FechaPago,
//                    MetodoPago = dto.MetodoPago, // Ej: "Transferencia Bancaria (SPEI)"
//                    Estado = "Completado"
//                };

//                _context.PagoProveedors.Add(nuevoPago);
//                await _context.SaveChangesAsync();

//                await transaction.CommitAsync();
//                return true;
//            }
//            catch (Exception ex)
//            {
//                await transaction.RollbackAsync();

//                // Pistas en la consola de Visual Studio por si ocurre algún inconveniente
//                Console.WriteLine("\n\n============= ¡ERROR CRÍTICO EN EGRESOS PROVEEDOR! =============");
//                Console.WriteLine($"MENSAJE PRINCIPAL: {ex.Message}");
//                if (ex.InnerException != null)
//                {
//                    Console.WriteLine($"CULPABLE REAL (INNER): {ex.InnerException.Message}");
//                }
//                Console.WriteLine("===============================================================\n\n");

//                throw;
//            }
//        }

//        public async Task<EstadoCuentaDTO?> ObtenerEstadoCuentaAsync(int idContrato)
//        {
//            // 1. Traemos el contrato con todo su árbol familiar
//            var contrato = await _context.Contratos
//                .Include(c => c.IdEventoNavigation)
//                    .ThenInclude(e => e.IdClienteNavigation)
//                .Include(c => c.PlanPago) // Cambiado a singular según tu modelo
//                    .ThenInclude(p => p.Cuota)
//                        .ThenInclude(cu => cu.PagoClientes)
//                .FirstOrDefaultAsync(c => c.IdContrato == idContrato);

//            if (contrato == null) return null;

//            // 2. Extraemos el plan de pago directamente (ya no usamos FirstOrDefault porque no es una lista)
//            var planPago = contrato.PlanPago;

//            if (planPago == null) return null;

//            // 3. Mapeamos y calculamos las cuotas una por una
//            var cuotasDTO = planPago.Cuota.Select(cu => {
//                decimal abonadoEnEstaCuota = cu.PagoClientes.Sum(p => p.Monto);
//                return new CuotaDetalleDTO
//                {
//                    IdCuota = cu.IdCuota,
//                    NumeroCuota = cu.NumeroCuota,
//                    FechaLimite = cu.FechaLimite,
//                    MontoTotal = cu.Monto,
//                    MontoAbonado = abonadoEnEstaCuota,
//                    SaldoRestante = cu.Monto - abonadoEnEstaCuota,
//                    Estado = cu.Estado
//                };
//            }).OrderBy(c => c.NumeroCuota).ToList();

//            // 4. Calculamos los totales globales del contrato
//            decimal totalAbonadoContrato = cuotasDTO.Sum(c => c.MontoAbonado);

//            // 5. Retornamos el paquete armado para Angular
//            return new EstadoCuentaDTO
//            {
//                IdContrato = contrato.IdContrato,
//                IdEvento = contrato.IdEvento,
//                NombreCliente = $"{contrato.IdEventoNavigation.IdClienteNavigation.Nombre} {contrato.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno}".Trim(),
//                TotalContrato = contrato.MontoAcordado,
//                MontoAbonado = totalAbonadoContrato,
//                SaldoRestante = contrato.MontoAcordado - totalAbonadoContrato,
//                EstadoContrato = contrato.Estado,
//                Cuotas = cuotasDTO
//            };
//        }

//        public async Task<EstadoCuentaDTO?> ObtenerEstadoCuentaPorClienteAsync(int idCliente)
//        {
//            //Buscamos el contrato asociado al evento de este cliente (tomamos el más reciente si tuviera varios)
//            var contrato = await _context.Contratos
//                .Include(c => c.IdEventoNavigation)
//                .Where(c => c.IdEventoNavigation.IdCliente == idCliente)
//                .OrderByDescending(c => c.FechaContrato)
//                .FirstOrDefaultAsync();

//            //Si el cliente aun no tiene contrato, devolvemos null
//            if (contrato == null) return null;

//            //Reutilizamos el método que ya tiene toda la matemática 
//            return await ObtenerEstadoCuentaAsync(contrato.IdContrato);
//        }

//        public async Task<IEnumerable<ContratoListadoDTO>> ObtenerTodosLosContratosAsync()
//        {
//            // 1. Traemos TODOS los contratos con sus relaciones
//            var contratos = await _context.Contratos
//                .Include(c => c.IdEventoNavigation)
//                    .ThenInclude(e => e.IdClienteNavigation)
//                .Include(c => c.PlanPago) // Ojo: Verifica si en tu Context es PlanPago o PlanPagos
//                    .ThenInclude(p => p.Cuota)
//                        .ThenInclude(cu => cu.PagoClientes)
//                .OrderByDescending(c => c.FechaContrato)
//                .ToListAsync();

//            // 2. Mapeamos y calculamos el dinero de cada uno
//            var listado = contratos.Select(c => {
//                decimal totalAbonado = 0;

//                // Sumamos los pagos si tiene un plan de pago
//                if (c.PlanPago != null)
//                {
//                    totalAbonado = c.PlanPago.Cuota
//                        .SelectMany(cu => cu.PagoClientes)
//                        .Sum(p => p.Monto);
//                }

//                return new ContratoListadoDTO
//                {
//                    IdContrato = c.IdContrato,
//                    IdCliente = c.IdEventoNavigation.IdCliente,
//                    Cliente = $"{c.IdEventoNavigation.IdClienteNavigation.Nombre} {c.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno}".Trim(),
//                    Evento = c.IdEventoNavigation.Nombre,
//                    FechaContrato = c.FechaContrato,
//                    MontoTotal = c.MontoAcordado,
//                    MontoAbonado = totalAbonado,
//                    SaldoRestante = c.MontoAcordado - totalAbonado,
//                    Estado = c.Estado
//                };
//            }).ToList();

//            return listado;
//        }
//    }
//}
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs.Finanzas;
using OrgEventos.API.Models;
using Stripe;
using System.Linq.Expressions;
using System.Runtime.CompilerServices;

namespace OrgEventos.API.Services
{
    public class FinanzasService : IFinanzasService
    {
        private readonly GestionEventosContext _context;
        private readonly IEmailService _emailService; // <-- Nuevo servicio inyectado

        public FinanzasService(GestionEventosContext context, IEmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        public async Task<bool> RegistrarPagoClienteAsync(RegistrarPagoClienteDTO dto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Buscamos la cuota con todo su árbol de relaciones (Plan, Contrato, Evento y Cliente con correo)
                var cuota = await _context.Cuota
                    .Include(c => c.PagoClientes)
                    .Include(c => c.IdPlanPagoNavigation)
                        .ThenInclude(p => p.Cuota)
                    .Include(c => c.IdPlanPagoNavigation)
                        .ThenInclude(p => p.IdContratoNavigation)
                            .ThenInclude(co => co.IdEventoNavigation)
                                .ThenInclude(e => e.IdClienteNavigation) // <-- Aquí está el correo y nombre del cliente
                    .FirstOrDefaultAsync(c => c.IdCuota == dto.IdCuota);

                if (cuota == null)
                    throw new Exception("La cuota especificada no existe.");

                if (cuota.Estado == "Pagada")
                    throw new Exception("Esta cuota ya se encuentra totalmente liquidada.");

                decimal abonado = cuota.PagoClientes.Sum(p => p.Monto);
                decimal restante = cuota.Monto - abonado;

                if (dto.MontoPagado <= 0)
                    throw new Exception("El monto del pago debe ser mayor a cero.");

                if (dto.MontoPagado > restante)
                    throw new Exception($"El monto (${dto.MontoPagado}) supera el saldo restante de la cuota (${restante}).");

                // 2. Registrar el ingreso en PAGO_CLIENTE
                var nuevoPago = new PagoCliente
                {
                    IdCuota = dto.IdCuota,
                    Monto = dto.MontoPagado,
                    FechaPago = dto.FechaPago,
                    MetodoPago = dto.MetodoPago,
                    Estado = "Completado"
                };
                _context.PagoClientes.Add(nuevoPago);

                // --- LÓGICA DE ACTIVACIÓN ---
                var contrato = cuota.IdPlanPagoNavigation.IdContratoNavigation;
                var evento = contrato.IdEventoNavigation;

                if (contrato.Estado == "Pendiente")
                {
                    contrato.Estado = "Activo";
                    evento.Estado = "En planificación";
                }

                await _context.SaveChangesAsync();

                // 4. Automatización de Estados: ¿Se liquidó la cuota?
                if (abonado + dto.MontoPagado >= cuota.Monto)
                {
                    cuota.Estado = "Pagada";
                    await _context.SaveChangesAsync();
                }

                // 5. Automatización de Estados: ¿Se liquidó todo el contrato?
                var plan = cuota.IdPlanPagoNavigation;
                if (plan.Cuota.All(c => c.Estado == "Pagada"))
                {
                    plan.Estado = "Pagado";
                    plan.IdContratoNavigation.Estado = "Liquidado";
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();

                // --- 6. ENVÍO AUTOMÁTICO DE CORREO ELECTRÓNICO AL CLIENTE ---
                try
                {
                    var cliente = evento.IdClienteNavigation;

                    // --> ¡Añadamos esto para depurar! <--
                    Console.WriteLine($"\n[DEPURACIÓN CORREO] Intentando enviar correo a: {cliente?.Correo ?? "CLIENTE O CORREO NULO"}");

                    if (cliente != null && !string.IsNullOrEmpty(cliente.Correo))
                    {
                        string fechaFormateada = dto.FechaPago.ToString("yyyy-MM-dd");
                        string cuerpoHtml = $@"
            <div style='font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;'>
                <h2 style='color: #4f46e5; text-align: center;'>OrgEventos</h2>
                <h3 style='text-align: center; color: #555;'>Comprobante Digital de Abono</h3>
                <hr style='border: none; border-top: 1px dashed #ccc;' />
                <p>Estimado/a <strong>{cliente.Nombre} {cliente.ApellidoPaterno}</strong>,</p>
                <p>Te confirmamos que hemos registrado exitosamente tu pago.</p>
                <table style='width: 100%; border-collapse: collapse; margin-top: 20px;'>
                    <tr>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Cuota ID:</strong></td>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'>#{cuota.IdCuota} (Nº {cuota.NumeroCuota})</td>
                    </tr>
                    <tr>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Método de Pago:</strong></td>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'>{dto.MetodoPago}</td>
                    </tr>
                    <tr>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Fecha de Pago:</strong></td>
                        <td style='padding: 8px; border-bottom: 1px solid #eee;'>{fechaFormateada}</td>
                    </tr>
                    <tr>
                        <td style='padding: 8px; border-top: 2px solid #4f46e5; padding-top: 12px;'><strong>Monto Recibido:</strong></td>
                        <td style='padding: 8px; border-top: 2px solid #4f46e5; padding-top: 12px; color: #16a34a; font-size: 18px;'><strong>${dto.MontoPagado:N2} MXN</strong></td>
                    </tr>
                </table>
                <p style='margin-top: 30px; text-align: center; color: #777; font-size: 12px;'>
                    Este documento es un comprobante oficial de abono a su contrato.<br>¡Gracias por confiar en nosotros!
                </p>
            </div>";

                        await _emailService.EnviarCorreoAsync(cliente.Correo, "Comprobante de Pago - OrgEventos", cuerpoHtml);
                        Console.WriteLine("[DEPURACIÓN CORREO] ¡Correo enviado exitosamente!\n");
                    }
                    else
                    {
                        Console.WriteLine("[DEPURACIÓN CORREO] Omitido: El cliente no tiene un correo válido registrado.\n");
                    }
                }
                catch (Exception emailEx)
                {
                    // --> ¡Imprimimos el error real completo para saber qué pasó! <--
                    Console.WriteLine($"\n\n============= ❌ ERROR AL ENVIAR CORREO ===============");
                    Console.WriteLine($"Mensaje: {emailEx.Message}");
                    Console.WriteLine($"Inner: {emailEx.InnerException?.Message}");
                    Console.WriteLine($"StackTrace: {emailEx.StackTrace}");
                    Console.WriteLine($"=======================================================\n\n");
                }

                return true;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine($"\n\n============= ¡ERROR CRÍTICO EN FINANZAS! =============");
                Console.WriteLine($"MENSAJE PRINCIPAL: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"CULPABLE REAL (INNER): {ex.InnerException.Message}");
                }
                Console.WriteLine("=======================================================\n\n");
                throw;
            }
        }

        public async Task<bool> RegistrarPagoProveedorAsync(RegistrarPagoProveedorDTO dto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var eventoProveedor = await _context.EventoProveedors
                    .Include(ep => ep.PagoProveedors)
                    .FirstOrDefaultAsync(ep => ep.IdEventoProveedor == dto.IdEventoProveedor);

                if (eventoProveedor == null) return false;

                if (dto.MontoPagado <= 0)
                    throw new Exception("El monto del pago debe ser mayor a cero.");

                decimal totalPagado = eventoProveedor.PagoProveedors.Sum(p => p.Monto);
                decimal saldoPendiente = eventoProveedor.CostoAcordado - totalPagado;

                if (dto.MontoPagado > saldoPendiente)
                    throw new Exception($"El monto (${dto.MontoPagado}) supera el saldo pendiente con el proveedor (${saldoPendiente}).");

                var nuevoPago = new PagoProveedor
                {
                    IdEventoProveedor = dto.IdEventoProveedor,
                    Monto = dto.MontoPagado,
                    FechaPago = dto.FechaPago,
                    MetodoPago = dto.MetodoPago,
                    Estado = "Completado"
                };

                _context.PagoProveedors.Add(nuevoPago);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine($"\n\n============= ¡ERROR CRÍTICO EN EGRESOS PROVEEDOR! =============");
                Console.WriteLine($"MENSAJE PRINCIPAL: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"CULPABLE REAL (INNER): {ex.InnerException.Message}");
                }
                Console.WriteLine("===============================================================\n\n");
                throw;
            }
        }

        public async Task<EstadoCuentaDTO?> ObtenerEstadoCuentaAsync(int idContrato)
        {
            var contrato = await _context.Contratos
                .Include(c => c.IdEventoNavigation)
                    .ThenInclude(e => e.IdClienteNavigation)
                .Include(c => c.PlanPago)
                    .ThenInclude(p => p.Cuota)
                        .ThenInclude(cu => cu.PagoClientes)
                .FirstOrDefaultAsync(c => c.IdContrato == idContrato);

            if (contrato == null) return null;
            var planPago = contrato.PlanPago;
            if (planPago == null) return null;

            var cuotasDTO = planPago.Cuota.Select(cu => {
                decimal abonadoEnEstaCuota = cu.PagoClientes.Sum(p => p.Monto);
                return new CuotaDetalleDTO
                {
                    IdCuota = cu.IdCuota,
                    NumeroCuota = cu.NumeroCuota,
                    FechaLimite = cu.FechaLimite,
                    MontoTotal = cu.Monto,
                    MontoAbonado = abonadoEnEstaCuota,
                    SaldoRestante = cu.Monto - abonadoEnEstaCuota,
                    Estado = cu.Estado
                };
            }).OrderBy(c => c.NumeroCuota).ToList();

            decimal totalAbonadoContrato = cuotasDTO.Sum(c => c.MontoAbonado);

            return new EstadoCuentaDTO
            {
                IdContrato = contrato.IdContrato,
                IdEvento = contrato.IdEvento,
                NombreCliente = $"{contrato.IdEventoNavigation.IdClienteNavigation.Nombre} {contrato.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno}".Trim(),
                TotalContrato = contrato.MontoAcordado,
                MontoAbonado = totalAbonadoContrato,
                SaldoRestante = contrato.MontoAcordado - totalAbonadoContrato,
                EstadoContrato = contrato.Estado,
                Cuotas = cuotasDTO
            };
        }

        public async Task<EstadoCuentaDTO?> ObtenerEstadoCuentaPorClienteAsync(int idCliente)
        {
            var contrato = await _context.Contratos
                .Include(c => c.IdEventoNavigation)
                .Where(c => c.IdEventoNavigation.IdCliente == idCliente)
                .OrderByDescending(c => c.FechaContrato)
                .FirstOrDefaultAsync();

            if (contrato == null) return null;
            return await ObtenerEstadoCuentaAsync(contrato.IdContrato);
        }

        public async Task<IEnumerable<ContratoListadoDTO>> ObtenerTodosLosContratosAsync()
        {
            var contratos = await _context.Contratos
                .Include(c => c.IdEventoNavigation)
                    .ThenInclude(e => e.IdClienteNavigation)
                .Include(c => c.PlanPago)
                    .ThenInclude(p => p.Cuota)
                        .ThenInclude(cu => cu.PagoClientes)
                .OrderByDescending(c => c.FechaContrato)
                .ToListAsync();

            var listado = contratos.Select(c => {
                decimal totalAbonado = 0;
                if (c.PlanPago != null)
                {
                    totalAbonado = c.PlanPago.Cuota
                        .SelectMany(cu => cu.PagoClientes)
                        .Sum(p => p.Monto);
                }

                return new ContratoListadoDTO
                {
                    IdContrato = c.IdContrato,
                    IdCliente = c.IdEventoNavigation.IdCliente,
                    Cliente = $"{c.IdEventoNavigation.IdClienteNavigation.Nombre} {c.IdEventoNavigation.IdClienteNavigation.ApellidoPaterno}".Trim(),
                    Evento = c.IdEventoNavigation.Nombre,
                    FechaContrato = c.FechaContrato,
                    MontoTotal = c.MontoAcordado,
                    MontoAbonado = totalAbonado,
                    SaldoRestante = c.MontoAcordado - totalAbonado,
                    Estado = c.Estado
                };
            }).ToList();

            return listado;
        }
    }
}
