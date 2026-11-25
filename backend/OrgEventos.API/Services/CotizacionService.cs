using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs.Cotizaciones;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public class CotizacionService : ICotizacionService
    {
        private readonly GestionEventosContext _context;
        private readonly IEmailService _emailService;
        private readonly GoogleCalendarService _googleCalendarService;

        public CotizacionService(
            GestionEventosContext context,
            IEmailService emailService,
            GoogleCalendarService googleCalendarService)
        {
            _context = context;
            _emailService = emailService;
            _googleCalendarService = googleCalendarService;
        }

        public async Task<CotizacionResultadoDTO> CrearCotizacionAsync(CrearCotizacionDTO dto)
        {
            string? advertencia = null;

            // 1. REVISAR DISPONIBILIDAD SOLO SI EL USUARIO ESCOGIÓ UNA FECHA
            var idsProveedoresServicio = dto.ServiciosExternos.Select(s => s.IdServicioProveedor).ToList();

            if (idsProveedoresServicio.Any() && dto.FechaReferencia.HasValue)
            {
                var fechaRef = dto.FechaReferencia.Value;

                var proveedoresOcupados = await _context.EventoProveedors
                    .Include(ep => ep.IdEventoNavigation)
                    .Include(ep => ep.IdServicioProveedorNavigation)
                    .Where(ep => idsProveedoresServicio.Contains(ep.IdServicioProveedor) &&
                                 ep.IdEventoNavigation != null &&
                                 ep.IdEventoNavigation.FechaEvento == fechaRef &&
                                 ep.IdEventoNavigation.Estado != "Cancelado")
                    .Select(ep => ep.IdServicioProveedorNavigation.NombreServicio + " (Ocupado en el evento: " + ep.IdEventoNavigation.Nombre + ")")
                    .Distinct()
                    .ToListAsync();

                if (proveedoresOcupados.Any())
                {
                    advertencia = $"⚠️ Aviso de Disponibilidad: Para la fecha estimada ({fechaRef}), los siguientes servicios ya tienen un compromiso confirmado: {string.Join(", ", proveedoresOcupados)}. La cotización se guardará de todos modos como borrador.";
                }
            }

            // 2. CÁLCULOS Y CREACIÓN DE LA COTIZACIÓN
            decimal totalInterno = dto.ServiciosInternos.Sum(s => s.Cantidad * s.PrecioUnitario);
            decimal totalExterno = dto.ServiciosExternos.Sum(s => s.Cantidad * s.PrecioCotizado);
            decimal totalFinal = totalInterno + totalExterno;

            var nuevaCotizacion = new Cotizacion
            {
                IdCliente = dto.IdCliente,
                Fecha = DateOnly.FromDateTime(DateTime.Now),
                FechaReferencia = dto.FechaReferencia,
                Estado = "Pendiente",
                Total = totalFinal,

                CotizacionDetalles = dto.ServiciosInternos.Select(s => new CotizacionDetalle
                {
                    IdServicio = s.IdServicio,
                    Cantidad = s.Cantidad,
                    PrecioUnitario = s.PrecioUnitario
                }).ToList(),

                CotizacionProveedors = dto.ServiciosExternos.Select(s => new CotizacionProveedor
                {
                    IdServicioProveedor = s.IdServicioProveedor,
                    Cantidad = s.Cantidad,
                    PrecioCotizado = s.PrecioCotizado,
                    Observaciones = s.Observaciones
                }).ToList()
            };

            _context.Cotizacions.Add(nuevaCotizacion);
            await _context.SaveChangesAsync();

            return new CotizacionResultadoDTO
            {
                IdCotizacion = nuevaCotizacion.IdCotizacion,
                Advertencia = advertencia
            };
        }

        public async Task<CotizacionLecturaDTO?> ObtenerCotizacionPorIdAsync(int idCotizacion)
        {
            var cotizacion = await _context.Cotizacions
                .Include(c => c.IdClienteNavigation)
                .Include(c => c.CotizacionDetalles)
                    .ThenInclude(d => d.IdServicioNavigation)
                .Include(c => c.CotizacionProveedors)
                    .ThenInclude(cp => cp.IdServicioProveedorNavigation)
                        .ThenInclude(sp => sp.IdProveedorNavigation)
                .FirstOrDefaultAsync(c => c.IdCotizacion == idCotizacion);

            if (cotizacion == null) return null;

            return MapearALecturaDTO(cotizacion);
        }

        public async Task<IEnumerable<CotizacionLecturaDTO>> ObtenerCotizacionesAsync()
        {
            var cotizaciones = await _context.Cotizacions
                .Include(c => c.IdClienteNavigation)
                .OrderByDescending(c => c.Fecha)
                .ToListAsync();

            return cotizaciones.Select(c => new CotizacionLecturaDTO
            {
                IdCotizacion = c.IdCotizacion,
                IdCliente = c.IdCliente,
                NombreClienteCompleto = $"{c.IdClienteNavigation.Nombre} {c.IdClienteNavigation.ApellidoPaterno}".Trim(),
                Fecha = c.Fecha,
                Estado = c.Estado,
                Total = c.Total
            }).ToList();
        }

        private CotizacionLecturaDTO MapearALecturaDTO(Cotizacion c)
        {
            return new CotizacionLecturaDTO
            {
                IdCotizacion = c.IdCotizacion,
                IdCliente = c.IdCliente,
                NombreClienteCompleto = $"{c.IdClienteNavigation.Nombre} {c.IdClienteNavigation.ApellidoPaterno} {c.IdClienteNavigation.ApellidoMaterno}".Trim(),
                Fecha = c.Fecha,
                FechaReferencia = c.FechaReferencia,
                Estado = c.Estado,
                Total = c.Total,
                ServiciosInternos = c.CotizacionDetalles.Select(d => new CotizacionDetalleLecturaDTO
                {
                    IdDetalle = d.IdDetalle,
                    IdServicio = d.IdServicio,
                    NombreServicio = d.IdServicioNavigation.Nombre,
                    Cantidad = d.Cantidad,
                    PrecioUnitario = d.PrecioUnitario
                }).ToList(),
                ServiciosExternos = c.CotizacionProveedors.Select(cp => new CotizacionProveedorLecturaDTO
                {
                    IdCotizacionProveedor = cp.IdCotizacionProveedor,
                    IdServicioProveedor = cp.IdServicioProveedor,
                    NombreServicioProveedor = cp.IdServicioProveedorNavigation.NombreServicio,
                    NombreEmpresaProveedor = $"{cp.IdServicioProveedorNavigation.IdProveedorNavigation.Nombre} {cp.IdServicioProveedorNavigation.IdProveedorNavigation.ApellidoPaterno}".Trim(),
                    UnidadCobro = cp.IdServicioProveedorNavigation.UnidadCobro ?? "Por evento",
                    Cantidad = cp.Cantidad,
                    PrecioCotizado = cp.PrecioCotizado,
                    Observaciones = cp.Observaciones
                }).ToList()
            };
        }

        public async Task<bool> AprobarCotizacionYCrearEventoAsync(int idCotizacion, AprobarCotizacionDTO dto)
        {
            var cotizacion = await _context.Cotizacions
                .Include(c => c.IdClienteNavigation)
                .Include(c => c.CotizacionProveedors)
                    .ThenInclude(cp => cp.IdServicioProveedorNavigation)
                .Include(c => c.CotizacionDetalles)
                    .ThenInclude(d => d.IdServicioNavigation)
                .FirstOrDefaultAsync(c => c.IdCotizacion == idCotizacion);

            if (cotizacion == null || cotizacion.Estado != "Pendiente")
                return false;

            DateOnly fechaInicio = dto.FechaEvento;
            DateOnly fechaFin = dto.FechaFin.HasValue && dto.FechaFin.Value >= fechaInicio
                ? dto.FechaFin.Value
                : fechaInicio;

            if (dto.FechaFin.HasValue && dto.FechaFin.Value < fechaInicio)
            {
                throw new ArgumentException("La fecha de fin del evento no puede ser anterior a la fecha de inicio.");
            }

            // 0 = Entrada libre / sin límite de invitados; valores positivos = aforo estimado
            if (dto.NumeroInvitados < 0)
            {
                throw new ArgumentException("El número de invitados no puede ser negativo.");
            }

            var serviciosAContratar = cotizacion.CotizacionDetalles
                .Select(d => d.IdServicio)
                .ToList();

            var serviciosOcupados = await _context.Eventos
                .Where(e =>
                    (e.Estado == "En planificación" || e.Estado == "Activo" || e.Estado == "Pendiente") &&
                    e.FechaEvento <= fechaFin &&
                    (e.FechaFin ?? e.FechaEvento) >= fechaInicio)
                .SelectMany(e => e.IdCotizacionNavigation.CotizacionDetalles
                    .Where(d => serviciosAContratar.Contains(d.IdServicio))
                    .Select(d => $"{d.IdServicioNavigation.Nombre} (Bloqueado por el evento: '{e.Nombre}' en estado {e.Estado})"))
                .Distinct()
                .ToListAsync();

            if (serviciosOcupados.Any())
            {
                string nombresServicios = string.Join(", ", serviciosOcupados);
                string rangoTexto = fechaFin > fechaInicio
                    ? $"del {fechaInicio} al {fechaFin}"
                    : $"el {fechaInicio}";
                throw new InvalidOperationException($"Colisión de inventario: Los siguientes servicios ya están reservados {rangoTexto}: {nombresServicios}");
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                cotizacion.Estado = "Aceptada";

                string textoInvitados = eventoOrInvitadosTexto(dto.NumeroInvitados);

                // 1. Crear EVENTO
                var evento = new Evento
                {
                    IdCliente = cotizacion.IdCliente,
                    IdCotizacion = cotizacion.IdCotizacion,
                    IdUsuarioCoordinador = dto.IdUsuarioCoordinador,
                    IdTipoEvento = dto.IdTipoEvento,
                    Nombre = dto.NombreEvento,
                    FechaEvento = fechaInicio,
                    FechaFin = dto.FechaFin.HasValue && dto.FechaFin.Value > fechaInicio ? fechaFin : null,
                    Lugar = dto.Lugar,
                    NumeroInvitados = dto.NumeroInvitados,
                    Estado = "Pendiente"
                };
                _context.Eventos.Add(evento);
                await _context.SaveChangesAsync();

                // 📅 2. SINCRONIZAR AUTOMÁTICAMENTE CON GOOGLE CALENDAR
                try
                {
                    DateTime fechaHoraEvento = evento.FechaEvento.ToDateTime(new TimeOnly(10, 0));

                    await _googleCalendarService.CrearEventoEnCalendarioAsync(
                        evento.Nombre,
                        $"Sede: {evento.Lugar} - Invitados: {textoInvitados}",
                        evento.Lugar,
                        fechaHoraEvento
                    );
                    Console.WriteLine("[GOOGLE CALENDAR] ✅ Evento sincronizado en la nube exitosamente.");
                }
                catch (Exception calEx)
                {
                    Console.WriteLine($"[ADVERTENCIA CALENDAR] No se pudo sincronizar el evento con Google Calendar: {calEx.Message}");
                }
                // 3. Crear EVENTO_PROVEEDOR aplicando UnidadCobro ("Por evento" vs "Por unidad")
                decimal totalProveedoresAcordado = 0m;

                if (cotizacion.CotizacionProveedors != null && cotizacion.CotizacionProveedors.Any())
                {
                    foreach (var prov in cotizacion.CotizacionProveedors)
                    {
                        string unidad = prov.IdServicioProveedorNavigation?.UnidadCobro?.Trim() ?? "Por evento";
                        int cantidadAplicada = prov.Cantidad > 0 ? prov.Cantidad : 1;

                        if (string.Equals(unidad, "Por unidad", StringComparison.OrdinalIgnoreCase))
                        {
                            // Si en la cotización se indicó cantidad > 0, usa esa cantidad;
                            // si no, y se indicaron invitados (> 0), puede usarse como referencia opcional.
                            cantidadAplicada = prov.Cantidad > 0
                                ? prov.Cantidad
                                : (dto.NumeroInvitados > 0 ? dto.NumeroInvitados : 1);
                        }

                        decimal costoAcordado = prov.PrecioCotizado * cantidadAplicada;
                        totalProveedoresAcordado += costoAcordado;

                        _context.EventoProveedors.Add(new EventoProveedor
                        {
                            IdEvento = evento.IdEvento,
                            IdServicioProveedor = prov.IdServicioProveedor,
                            CostoAcordado = costoAcordado,
                            Observaciones = prov.Observaciones
                        });
                    }
                    await _context.SaveChangesAsync();
                }

                // Total real del evento = servicios internos + proveedores ajustados según unidad/invitados
                decimal totalInternos = cotizacion.CotizacionDetalles?.Sum(d => d.Cantidad * d.PrecioUnitario) ?? 0m;
                decimal montoTotal = totalInternos + totalProveedoresAcordado;

                // 4. Crear CONTRATO
                var contrato = new Contrato
                {
                    IdEvento = evento.IdEvento,
                    FechaContrato = DateTime.Now,
                    MontoAcordado = montoTotal,
                    Estado = "Pendiente"
                };
                _context.Contratos.Add(contrato);
                await _context.SaveChangesAsync();

                // 5. Crear PLAN_PAGO y CUOTAS
                var planPago = new PlanPago
                {
                    IdContrato = contrato.IdContrato,
                    NumeroCuotas = dto.NumeroCuotas,
                    Estado = "Pendiente"
                };
                _context.PlanPagos.Add(planPago);
                await _context.SaveChangesAsync();

                int numCuotas = dto.NumeroCuotas;

                DateOnly fechaHoy = DateOnly.FromDateTime(DateTime.Now);
                DateOnly fechaEvento = evento.FechaEvento;

                DateOnly fechaFiniquito = fechaEvento.AddDays(-15);
                if (fechaFiniquito <= fechaHoy)
                {
                    fechaFiniquito = fechaEvento > fechaHoy ? fechaEvento.AddDays(-1) : fechaHoy;
                }

                decimal montoAnticipo = Math.Round(montoTotal * 0.10m, 2);
                decimal montoRestante = montoTotal - montoAnticipo;
                decimal montoBaseRestante = numCuotas > 1 ? Math.Round(montoRestante / (numCuotas - 1), 2) : 0;

                int diasTotales = fechaFiniquito.DayNumber - fechaHoy.DayNumber;
                int intervaloDias = numCuotas > 2 && diasTotales > 0 ? diasTotales / (numCuotas - 2) : 0;

                for (int i = 1; i <= numCuotas; i++)
                {
                    decimal montoAsignado;
                    DateOnly fechaLimiteAsignada;

                    if (numCuotas == 1)
                    {
                        montoAsignado = montoTotal;
                        fechaLimiteAsignada = fechaHoy;
                    }
                    else if (i == 1)
                    {
                        montoAsignado = montoAnticipo;
                        fechaLimiteAsignada = fechaHoy;
                    }
                    else if (i == numCuotas)
                    {
                        montoAsignado = montoRestante - (montoBaseRestante * (numCuotas - 2));
                        fechaLimiteAsignada = fechaFiniquito;
                    }
                    else
                    {
                        montoAsignado = montoBaseRestante;
                        fechaLimiteAsignada = fechaHoy.AddDays(intervaloDias * (i - 1));
                    }

                    var cuota = new Cuotum
                    {
                        IdPlanPago = planPago.IdPlanPago,
                        NumeroCuota = i,
                        FechaLimite = fechaLimiteAsignada,
                        Monto = montoAsignado,
                        Estado = "Pendiente"
                    };
                    _context.Cuota.Add(cuota);
                }

                await _context.SaveChangesAsync();

                // 📧 6. ENVÍO DE CORREO / TICKET DE CONFIRMACIÓN AL CLIENTE
                if (cotizacion.IdClienteNavigation != null && !string.IsNullOrEmpty(cotizacion.IdClienteNavigation.Correo))
                {
                    string clienteCorreo = cotizacion.IdClienteNavigation.Correo;
                    string clienteNombre = $"{cotizacion.IdClienteNavigation.Nombre} {cotizacion.IdClienteNavigation.ApellidoPaterno}".Trim();

                    string textoFechaEvento = evento.FechaFin.HasValue && evento.FechaFin.Value > evento.FechaEvento
                        ? $"{evento.FechaEvento} al {evento.FechaFin.Value}"
                        : $"{evento.FechaEvento}";

                    string asunto = $"¡Evento Confirmado: {evento.Nombre}!";
                    string cuerpoHtml = $@"
                        <div style='font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;'>
                            <h2 style='color: #4F46E5; text-align: center;'>¡Tu Evento ha sido Aprobado con Éxito!</h2>
                            <p>Hola <strong>{clienteNombre}</strong>,</p>
                            <p>Nos alegra informarte que tu cotización ha sido aprobada y tu evento ya se encuentra registrado oficialmente en <strong>OrgEventos</strong>.</p>
                            
                            <div style='background-color: #f3f4f6; padding: 15px; border-radius: 6px; margin: 20px 0;'>
                                <h3 style='margin-top: 0; color: #1f2937;'>Detalles del Evento:</h3>
                                <p><strong>Evento:</strong> {evento.Nombre}</p>
                                <p><strong>Fecha:</strong> {textoFechaEvento}</p>
                                <p><strong>Lugar:</strong> {evento.Lugar}</p>
                                <p><strong>Invitados:</strong> {textoInvitados}</p>
                                <p><strong>Monto Total Acordado:</strong> ${contrato.MontoAcordado:N2}</p>
                            </div>

                            <p>Puedes acceder a tu portal de cliente para consultar los detalles de tus pagos y el progreso de la organización.</p>
                            <div style='text-align: center; margin-top: 25px;'>
                                <a href='http://localhost:4200/login' style='background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;'>Ir a mi Portal</a>
                            </div>
                            <p style='font-size: 12px; color: #6b7280; text-align: center; margin-top: 30px;'>Este es un mensaje automático generado por OrgEventos.</p>
                        </div>
                    ";

                    try
                    {
                        Console.WriteLine($"[EMAIL TICKET] Enviando comprobante de evento a {clienteCorreo}...");
                        await _emailService.EnviarCorreoAsync(clienteCorreo, asunto, cuerpoHtml);
                        Console.WriteLine("[EMAIL TICKET] ✅ Correo de confirmación enviado exitosamente.");
                    }
                    catch (Exception mailEx)
                    {
                        Console.WriteLine($"[ADVERTENCIA EMAIL] El evento se creó, pero falló el envío del correo: {mailEx.Message}");
                    }
                }

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine($"Error en transacción: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
                }
                throw;
            }
        }

        private static string eventoOrInvitadosTexto(int numeroInvitados)
        {
            return numeroInvitados <= 0 ? "Entrada libre" : numeroInvitados.ToString();
        }

        public async Task<bool> RechazarCotizacionAsync(int idCotizacion)
        {
            var cotizacion = await _context.Cotizacions.FindAsync(idCotizacion);

            if (cotizacion == null || cotizacion.Estado != "Pendiente")
                return false;

            cotizacion.Estado = "Rechazada";
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<IEnumerable<object>> ObtenerTiposEventoAsync()
        {
            return await _context.TipoEventos
                .Where(t => t.Activo)
                .Select(t => new { t.IdTipoEvento, t.Nombre })
                .ToListAsync();
        }
    }
}