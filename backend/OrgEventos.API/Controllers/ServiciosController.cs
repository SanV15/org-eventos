using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrgEventos.API.DTOs;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrador,Recepcionista")]
    public class ServiciosController : ControllerBase
    {
        private readonly IServicioService _servicioService;

        public ServiciosController(IServicioService servicioService)
        {
            _servicioService = servicioService;
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerServicios()
        {
            var servicios = await _servicioService.ObtenerServiciosAsync();
            return Ok(servicios);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> ObtenerServicio(int id)
        {
            var servicio = await _servicioService.ObtenerServicioPorIdAsync(id);
            if (servicio == null) return NotFound(new { mensaje = "Servicio no encontrado." });
            return Ok(servicio);
        }

        [HttpPost]
        public async Task<IActionResult> AgregarServicio([FromBody] ServicioRegistroDTO dto)
        {
            await _servicioService.AgregarServicioAsync(dto);
            return Ok(new { mensaje = "Servicio registrado correctamente." });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarServicio(int id, [FromBody] ServicioRegistroDTO dto)
        {
            var resultado = await _servicioService.ActualizarServicioAsync(id, dto);
            if (!resultado) return NotFound(new { mensaje = "Servicio no encontrado." });
            return Ok(new { mensaje = "Servicio actualizado correctamente." });
        }

        [HttpPut("{id}/estado")]
        public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoDTO dto)
        {
            var resultado = await _servicioService.CambiarEstadoServicioAsync(id, dto.Activo);
            if (!resultado) return NotFound(new { mensaje = "Servicio no encontrado." });

            var estado = dto.Activo ? "activado" : "desactivado";
            return Ok(new { mensaje = $"Servicio {estado} correctamente." });
        }
    }
}