using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.DTOs.Eventos;
using OrgEventos.API.Models;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrador,Recepcionista,Coordinador")]
    public class EventosController : ControllerBase
    {
        private readonly GestionEventosContext _context;
        private readonly IAmazonS3 _s3Client;
        private readonly IConfiguration _config;

        public EventosController(GestionEventosContext context, IAmazonS3 s3Client, IConfiguration config)
        {
            _context = context;
            _s3Client = s3Client;
            _config = config;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<EventoListadoDTO>>> ObtenerEventos()
        {
            try
            {
                var eventos = await _context.Eventos
                    .Include(e => e.IdClienteNavigation)
                    .OrderBy(e => e.FechaEvento)
                    .Select(e => new EventoListadoDTO
                    {
                        IdEvento = e.IdEvento,
                        IdCliente = e.IdCliente,
                        Cliente = e.IdClienteNavigation.Nombre + " " + e.IdClienteNavigation.ApellidoPaterno,
                        NombreEvento = e.Nombre,
                        FechaEvento = new DateTime(e.FechaEvento.Year, e.FechaEvento.Month, e.FechaEvento.Day),
                        Estado = e.Estado,
                        FotoEventoUrl = e.FotoEventoUrl
                    })
                    .ToListAsync();

                return Ok(eventos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener la lista de eventos.", detalle = ex.Message });
            }
        }

        [HttpGet("{idEvento:int}")]
        public async Task<IActionResult> ObtenerDetalleEvento(int idEvento)
        {
            var evento = await _context.Eventos.FindAsync(idEvento);
            if (evento == null) return NotFound(new { mensaje = "Evento no encontrado" });

            return Ok(new
            {
                fechaEvento = evento.FechaEvento,
                fotoEventoUrl = evento.FotoEventoUrl
            });
        }

        [HttpPost("{idEvento:int}/foto")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> SubirFotoEvento(int idEvento, IFormFile archivo)
        {
            var bucketName = _config["AWS:BucketName"] ?? "amazn-s3-bucket-san";

            if (archivo == null || archivo.Length == 0)
                return BadRequest(new { mensaje = "No se envió ninguna imagen." });

            var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
            if (!extensionesPermitidas.Contains(extension))
                return BadRequest(new { mensaje = "Formato no permitido. Usa JPG, PNG o WEBP." });

            var evento = await _context.Eventos.FindAsync(idEvento);
            if (evento == null)
                return NotFound(new { mensaje = "Evento no encontrado." });

            try
            {
                if (!string.IsNullOrEmpty(evento.FotoEventoUrl) &&
                    Uri.TryCreate(evento.FotoEventoUrl, UriKind.Absolute, out var uriAnterior))
                {
                    var keyAnterior = uriAnterior.AbsolutePath.TrimStart('/');
                    if (keyAnterior.StartsWith("eventos/"))
                    {
                        await _s3Client.DeleteObjectAsync(bucketName, keyAnterior);
                    }
                }

                var nuevaKey = $"eventos/evento_{idEvento}_{Guid.NewGuid():N}{extension}";

                using var stream = archivo.OpenReadStream();
                var putRequest = new PutObjectRequest
                {
                    BucketName = bucketName,
                    Key = nuevaKey,
                    InputStream = stream,
                    ContentType = archivo.ContentType,
                    CannedACL = S3CannedACL.PublicRead
                };

                await _s3Client.PutObjectAsync(putRequest);

                var region = _s3Client.Config.RegionEndpoint?.SystemName ?? "us-west-2";
                var urlPublica = $"https://{bucketName}.s3.{region}.amazonaws.com/{nuevaKey}";

                evento.FotoEventoUrl = urlPublica;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    mensaje = "Imagen del evento actualizada correctamente.",
                    fotoEventoUrl = urlPublica
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al subir la imagen a S3.", detalle = ex.Message });
            }
        }

        [HttpPut("{idEvento:int}/cancelar")]
        public async Task<IActionResult> CancelarEvento(int idEvento)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var evento = await _context.Eventos
                    .Include(e => e.IdCotizacionNavigation)
                    .FirstOrDefaultAsync(e => e.IdEvento == idEvento);

                if (evento == null)
                {
                    return NotFound(new { mensaje = "El evento no fue encontrado." });
                }

                if (evento.Estado == "Cancelado")
                {
                    return BadRequest(new { mensaje = "El evento ya se encuentra cancelado." });
                }

                evento.Estado = "Cancelado";

                if (evento.IdCotizacionNavigation != null)
                {
                    evento.IdCotizacionNavigation.Estado = "Rechazada";
                }

                var contrato = await _context.Contratos.FirstOrDefaultAsync(c => c.IdEvento == idEvento);
                if (contrato != null)
                {
                    contrato.Estado = "Cancelado";
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { mensaje = "Evento cancelado con éxito. Los recursos y proveedores han sido liberados." });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { mensaje = "Ocurrió un error al intentar cancelar el evento.", detalle = ex.Message });
            }
        }

        [HttpGet("{idEvento:int}/plan-operativo")]
        public async Task<ActionResult<PlanOperativoEventoDTO>> ObtenerPlanOperativo(int idEvento)
        {
            var evento = await _context.Eventos
                .Include(e => e.IdCotizacionNavigation)
                    .ThenInclude(c => c!.CotizacionDetalles)
                        .ThenInclude(d => d.IdServicioNavigation)
                .Include(e => e.EventoProveedors)
                    .ThenInclude(ep => ep.IdServicioProveedorNavigation)
                        .ThenInclude(sp => sp.IdProveedorNavigation)
                .FirstOrDefaultAsync(e => e.IdEvento == idEvento);

            if (evento == null)
                return NotFound(new { mensaje = "Evento no encontrado." });

            var serviciosInternos = evento.IdCotizacionNavigation?.CotizacionDetalles
                .Select(d => new ServicioInternoEventoDTO
                {
                    IdServicio = d.IdServicio,
                    Nombre = d.IdServicioNavigation?.Nombre ?? "Servicio interno",
                    Descripcion = d.IdServicioNavigation?.Descripcion ?? string.Empty,
                    Cantidad = d.Cantidad,
                    PrecioUnitario = d.PrecioUnitario,
                    Subtotal = d.Cantidad * d.PrecioUnitario
                })
                .ToList() ?? new();

            var proveedores = evento.EventoProveedors
                .Select(ep =>
                {
                    var prov = ep.IdServicioProveedorNavigation?.IdProveedorNavigation;
                    var nombreProv = prov != null
                        ? $"{prov.Nombre} {prov.ApellidoPaterno} {prov.ApellidoMaterno}".Trim()
                        : "Proveedor";

                    return new ProveedorHorarioEventoDTO
                    {
                        IdEventoProveedor = ep.IdEventoProveedor,
                        IdServicioProveedor = ep.IdServicioProveedor,
                        NombreServicio = ep.IdServicioProveedorNavigation?.NombreServicio ?? "Servicio externo",
                        NombreProveedor = string.IsNullOrWhiteSpace(nombreProv) ? "Proveedor" : nombreProv,
                        TelefonoProveedor = prov?.Telefono ?? string.Empty,
                        CostoAcordado = ep.CostoAcordado,
                        EstadoOperativo = string.IsNullOrWhiteSpace(ep.EstadoOperativo) ? "Pendiente" : ep.EstadoOperativo,
                        HoraPactada = ep.HoraPactada,
                        HoraLlegada = ep.HoraLlegada,
                        HoraSalida = ep.HoraSalida,
                        IdUsuarioCheckin = ep.IdUsuarioCheckin,
                        Observaciones = ep.Observaciones ?? string.Empty,
                        EvidenciaUrl = ep.EvidenciaUrl
                    };
                })
                .OrderBy(p => p.HoraPactada ?? DateTime.MaxValue)
                .ThenBy(p => p.IdEventoProveedor)
                .ToList();

            return Ok(new PlanOperativoEventoDTO
            {
                IdEvento = evento.IdEvento,
                NombreEvento = evento.Nombre,
                FechaEvento = evento.FechaEvento,
                FechaFin = evento.FechaFin,
                Lugar = evento.Lugar,
                NumeroInvitados = evento.NumeroInvitados,
                Estado = evento.Estado,
                ServiciosInternos = serviciosInternos,
                Proveedores = proveedores
            });
        }

        [HttpPatch("proveedores/{idEventoProveedor:int}/hora-pactada")]
        [Authorize(Roles = "Administrador,Coordinador,Recepcionista")]
        public async Task<IActionResult> ActualizarHoraPactadaProveedor(
            int idEventoProveedor,
            [FromBody] ActualizarHoraPactadaEventoDTO dto)
        {
            var registro = await _context.EventoProveedors.FindAsync(idEventoProveedor);
            if (registro == null)
                return NotFound(new { mensaje = "Asignación de proveedor no encontrada." });

            registro.HoraPactada = dto.HoraPactada;

            if (dto.Observaciones != null)
            {
                registro.Observaciones = dto.Observaciones.Trim();
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Hora pactada actualizada correctamente.",
                registro.IdEventoProveedor,
                registro.HoraPactada,
                registro.Observaciones
            });
        }

        [HttpPatch("proveedores/{idEventoProveedor:int}/operacion")]
        [Authorize(Roles = "Administrador,Coordinador,Recepcionista")]
        public async Task<IActionResult> ActualizarOperacionProveedor(
            int idEventoProveedor,
            [FromBody] ActualizarOperacionProveedorDTO dto)
        {
            var registro = await _context.EventoProveedors.FindAsync(idEventoProveedor);
            if (registro == null)
                return NotFound(new { mensaje = "Asignación de proveedor no encontrada." });

            registro.HoraPactada = dto.HoraPactada;
            registro.HoraLlegada = dto.HoraLlegada;
            registro.HoraSalida = dto.HoraSalida;

            if (!string.IsNullOrWhiteSpace(dto.EstadoOperativo))
                registro.EstadoOperativo = dto.EstadoOperativo.Trim();

            if (dto.IdUsuarioCheckin.HasValue && dto.IdUsuarioCheckin.Value > 0)
                registro.IdUsuarioCheckin = dto.IdUsuarioCheckin.Value;

            if (dto.Observaciones != null)
                registro.Observaciones = dto.Observaciones.Trim();

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Operación del proveedor actualizada correctamente.",
                registro.IdEventoProveedor
            });
        }

        public class ActualizarInvitadosEventoDTO
        {
            public int NumeroInvitados { get; set; }
        }


        [HttpPut("{idEvento:int}/invitados")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ActualizarInvitadosEvento(int idEvento, [FromBody] ActualizarInvitadosEventoDTO dto)
        {
            if (dto.NumeroInvitados < 0)
                return BadRequest(new { mensaje = "El número de invitados no puede ser negativo." });

            var evento = await _context.Eventos
                .Include(e => e.EventoProveedors)
                    .ThenInclude(ep => ep.IdServicioProveedorNavigation)
                .Include(e => e.IdCotizacionNavigation)
                    .ThenInclude(c => c!.CotizacionDetalles)
                .Include(e => e.Contrato)
                    .ThenInclude(ct => ct.PlanPago)
                        .ThenInclude(pp => pp.Cuota)
                            .ThenInclude(cu => cu.PagoClientes)
                .FirstOrDefaultAsync(e => e.IdEvento == idEvento);

            if (evento == null)
                return NotFound(new { mensaje = "Evento no encontrado." });

            var contrato = await _context.Contratos
    .Include(c => c.PlanPago)
        .ThenInclude(pp => pp.Cuota)
            .ThenInclude(cu => cu.PagoClientes)
    .FirstOrDefaultAsync(c => c.IdEvento == evento.IdEvento);

            // Blindaje: si ya existe algún pago del cliente en el contrato, no alterar automáticamente
            bool tienePagos = contrato?.PlanPago?.Cuota
                .Any(cu => cu.PagoClientes.Any()) ?? false;

            if (tienePagos)
            {
                return BadRequest(new
                {
                    mensaje = "El contrato ya tiene pagos registrados; el evento está asegurado y no se puede recalcular automáticamente."
                });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                int invitadosAnteriores = evento.NumeroInvitados > 0 ? evento.NumeroInvitados : 1;
                evento.NumeroInvitados = dto.NumeroInvitados;

                decimal totalProveedores = 0m;
                foreach (var ep in evento.EventoProveedors)
                {
                    var unidad = ep.IdServicioProveedorNavigation?.UnidadCobro?.Trim() ?? "Por evento";
                    if (string.Equals(unidad, "Por persona", StringComparison.OrdinalIgnoreCase))
                    {
                        decimal precioUnitario = ep.CostoAcordado > 0 && invitadosAnteriores > 0
                            ? Math.Round(ep.CostoAcordado / invitadosAnteriores, 2)
                            : (ep.IdServicioProveedorNavigation?.Costo ?? 0m);

                        int factor = dto.NumeroInvitados > 0 ? dto.NumeroInvitados : 1;
                        ep.CostoAcordado = precioUnitario * factor;
                    }
                    totalProveedores += ep.CostoAcordado;
                }

                decimal totalInternos = evento.IdCotizacionNavigation?.CotizacionDetalles?
                    .Sum(d => d.Cantidad * d.PrecioUnitario) ?? 0m;

                decimal nuevoMontoTotal = totalInternos + totalProveedores;

                if (contrato != null)
                {
                    contrato.MontoAcordado = nuevoMontoTotal;

                    var cuotas = contrato.PlanPago?.Cuota?.OrderBy(c => c.NumeroCuota).ToList();
                    if (cuotas != null && cuotas.Count > 0)
                    {
                        int numCuotas = cuotas.Count;
                        decimal anticipo = Math.Round(nuevoMontoTotal * 0.10m, 2);
                        decimal restante = nuevoMontoTotal - anticipo;
                        decimal baseRestante = numCuotas > 1 ? Math.Round(restante / (numCuotas - 1), 2) : 0m;

                        for (int i = 0; i < numCuotas; i++)
                        {
                            int num = i + 1;
                            if (numCuotas == 1)
                                cuotas[i].Monto = nuevoMontoTotal;
                            else if (num == 1)
                                cuotas[i].Monto = anticipo;
                            else if (num == numCuotas)
                                cuotas[i].Monto = restante - (baseRestante * (numCuotas - 2));
                            else
                                cuotas[i].Monto = baseRestante;
                        }
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    mensaje = "Número de invitados, costos de proveedores y contrato recalculados correctamente.",
                    idEvento = evento.IdEvento,
                    numeroInvitados = evento.NumeroInvitados,
                    nuevoMontoTotal = nuevoMontoTotal
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { mensaje = "Error al recalcular los invitados del evento.", detalle = ex.Message });
            }
        }

    }


}