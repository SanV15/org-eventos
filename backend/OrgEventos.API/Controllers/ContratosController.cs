using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs.Finanzas;
using OrgEventos.API.Models;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ContratosController : ControllerBase
    {
        private readonly GestionEventosContext _context;

        public ContratosController(GestionEventosContext context)
        {
            _context = context;
        }

        [HttpGet("evento/{idEvento}")]
        public async Task<IActionResult> ObtenerContratoPorEvento(int idEvento)
        {
            var contrato = await ObtenerContratoQueryBase()
                .FirstOrDefaultAsync(c => c.IdEvento == idEvento);

            if (contrato == null)
                return NotFound(new { mensaje = "No se encontró un contrato asociado a este evento." });

            return Ok(ContratoDetalleDTO.MapearDesde(contrato));
        }

        [HttpGet("cliente/{idCliente}")]
        public async Task<IActionResult> ObtenerContratoPorCliente(int idCliente)
        {
            var contrato = await ObtenerContratoQueryBase()
                .OrderByDescending(c => c.FechaContrato)
                .FirstOrDefaultAsync(c => c.IdEventoNavigation.IdCliente == idCliente);

            if (contrato == null)
                return NotFound(new { mensaje = "No se encontró un contrato asociado a este cliente." });

            return Ok(ContratoDetalleDTO.MapearDesde(contrato));
        }

        // Método auxiliar privado para no repetir los .Include() kilométricos
        private IQueryable<Contrato> ObtenerContratoQueryBase()
        {
            return _context.Contratos
                .Include(c => c.IdEventoNavigation)
                    .ThenInclude(e => e.IdClienteNavigation)
                .Include(c => c.IdEventoNavigation)
                    .ThenInclude(e => e.IdCotizacionNavigation)
                        .ThenInclude(cot => cot.CotizacionDetalles)
                            .ThenInclude(d => d.IdServicioNavigation)
                .Include(c => c.IdEventoNavigation)
                    .ThenInclude(e => e.IdCotizacionNavigation)
                        .ThenInclude(cot => cot.CotizacionProveedors)
                            .ThenInclude(cp => cp.IdServicioProveedorNavigation)
                .Include(c => c.PlanPago)
                    .ThenInclude(pp => pp.Cuota);
        }


        [HttpGet("{idContrato}")]
        public async Task<IActionResult> ObtenerContratoPorId(int idContrato)
        {
            var contrato = await ObtenerContratoQueryBase()
                .FirstOrDefaultAsync(c => c.IdContrato == idContrato);

            if (contrato == null)
                return NotFound(new { mensaje = "No se encontró el contrato." });

            return Ok(ContratoDetalleDTO.MapearDesde(contrato));
        }
    }
}