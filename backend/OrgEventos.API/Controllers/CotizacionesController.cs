using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs.Cotizaciones;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrador,Recepcionista")]
    public class CotizacionesController : ControllerBase
    {
        private readonly ICotizacionService _cotizacionService;

        public CotizacionesController(ICotizacionService cotizacionService)
        {
            _cotizacionService = cotizacionService;
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerCotizaciones()
        {
            var cotizaciones = await _cotizacionService.ObtenerCotizacionesAsync();
            return Ok(cotizaciones);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> ObtenerCotizacionPorId(int id)
        {
            var cotizacion = await _cotizacionService.ObtenerCotizacionPorIdAsync(id);
            if (cotizacion == null) return NotFound(new { mensaje = "Cotización no encontrada." });
            return Ok(cotizacion);
        }

        [HttpPost]
        public async Task<IActionResult> CrearCotizacion([FromBody] CrearCotizacionDTO dto)
        {
            // Validación de negocio básica
            if (dto.ServiciosInternos.Count == 0 && dto.ServiciosExternos.Count == 0)
            {
                return BadRequest(new { mensaje = "La cotización debe tener al menos un servicio o proveedor asignado." });
            }

            try
            {
                // 1. Recibimos el objeto resultado del servicio
                var resultado = await _cotizacionService.CrearCotizacionAsync(dto);

                // 2. Devolvemos el ID y la propiedad 'advertencia' (si la hubo) hacia Angular
                return Ok(new
                {
                    mensaje = "Cotización generada con éxito.",
                    idCotizacion = resultado.IdCotizacion,
                    advertencia = resultado.Advertencia // 👈 Esto lo leerá el frontend para mostrar el alert preventivo
                });
            }
            catch (Exception ex)
            {
                // En producción, aquí se guardaría el error en un log (Serilog, etc.)
                return StatusCode(500, new { mensaje = "Ocurrió un error al guardar la cotización.", detalle = ex.Message });
            }
        }

        [HttpPost("{id}/aprobar")]
        public async Task<IActionResult> Aprobar(int id, [FromBody] AprobarCotizacionDTO dto)
        {
            try
            {
                var resultado = await _cotizacionService.AprobarCotizacionYCrearEventoAsync(id, dto);
                if (!resultado)
                    return BadRequest(new { mensaje = "No se pudo aprobar la cotización. Verifica que exista y esté en estado Pendiente." });

                return Ok(new { mensaje = "Evento y finanzas creados correctamente." });
            }
            catch (Exception ex)
            {
                // Esto expondrá el mensaje real de SQL o de .NET
                var inner = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { mensaje = "Error en la transacción", error = inner });
            }
        }

        [HttpPost("{id}/rechazar")]
        public async Task<IActionResult> Rechazar(int id)
        {
            try
            {
                var resultado = await _cotizacionService.RechazarCotizacionAsync(id);
                if (!resultado)
                    return BadRequest(new { mensaje = "No se pudo rechazar. Verifica que la cotización exista y esté Pendiente." });

                return Ok(new { mensaje = "Cotización rechazada correctamente." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al rechazar", error = ex.Message });
            }
        }

        [HttpGet("tipos-evento")]
        public async Task<IActionResult> ObtenerTiposEvento()
        {
            var tipos = await _cotizacionService.ObtenerTiposEventoAsync();
            return Ok(tipos);
        }
    }
}