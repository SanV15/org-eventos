using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrgEventos.API.DTOs;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    //[Authorize(Roles = "Administrador,Recepcionista")]
    [Authorize]
    public class ServiciosProveedorController : ControllerBase
    {
        private readonly IServicioProveedorService _servicioService;

        public ServiciosProveedorController(IServicioProveedorService servicioService)
        {
            _servicioService = servicioService;
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerTodos()
        {
            // Llama al servicio para obtener absolutamente todos los servicios externos
            var servicios = await _servicioService.ObtenerTodosAsync();
            return Ok(servicios);
        }

        // GET: api/serviciosproveedor/proveedor/5
        [HttpGet("proveedor/{idProveedor}")]
        public async Task<IActionResult> ObtenerServiciosDeProveedor(int idProveedor)
        {
            var servicios = await _servicioService.ObtenerServiciosPorProveedorAsync(idProveedor);
            return Ok(servicios);
        }

        // POST: api/serviciosproveedor/proveedor/5
        [HttpPost("proveedor/{idProveedor}")]
        public async Task<IActionResult> AgregarServicio(int idProveedor, [FromBody] ServicioProveedorRegistroDTO dto)
        {
            var resultado = await _servicioService.AgregarServicioAsync(idProveedor, dto);
            if (!resultado) return NotFound(new { mensaje = "El proveedor especificado no existe." });

            return Ok(new { mensaje = "Servicio agregado correctamente al proveedor." });
        }

        // PUT: api/serviciosproveedor/5
        [HttpPut("{idServicioProveedor}")]
        public async Task<IActionResult> ActualizarServicio(int idServicioProveedor, [FromBody] ServicioProveedorRegistroDTO dto)
        {
            var resultado = await _servicioService.ActualizarServicioAsync(idServicioProveedor, dto);
            if (!resultado) return NotFound(new { mensaje = "El servicio especificado no existe." });

            return Ok(new { mensaje = "Servicio actualizado correctamente." });
        }

        // PUT: api/serviciosproveedor/5/estado
        [HttpPut("{idServicioProveedor}/estado")]
        public async Task<IActionResult> CambiarEstado(int idServicioProveedor, [FromBody] CambiarEstadoDTO dto)
        {
            var resultado = await _servicioService.CambiarEstadoServicioAsync(idServicioProveedor, dto.Activo);
            if (!resultado) return NotFound(new { mensaje = "El servicio especificado no existe." });

            var mensajeEstado = dto.Activo ? "activado" : "desactivado";
            return Ok(new { mensaje = $"Servicio {mensajeEstado} correctamente." });
        }
    }
}