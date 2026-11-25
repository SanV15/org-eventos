using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrgEventos.API.DTOs;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrador,Recepcionista")] // Protección estricta del flujo
    public class ClientesController : ControllerBase
    {
        private readonly IClienteService _clienteService;

        public ClientesController(IClienteService clienteService)
        {
            _clienteService = clienteService;
        }

        [HttpPost]
        public async Task<IActionResult> Registrar([FromBody] ClienteRegistroDTO dto)
        {
            try
            {
                await _clienteService.RegistrarClienteAsync(dto);
                return Ok(new { mensaje = "Cliente registrado exitosamente." });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { mensaje = ex.Message });
            }
            catch (Exception ex)
            {
                var errorReal = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(500, new { mensaje = "Error interno al registrar el cliente.", detalle = errorReal });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerTodos()
        {
            var clientes = await _clienteService.ObtenerClientesAsync();
            return Ok(clientes);
        }

        // 🔍 NUEVO ENDPOINT: Alimenta el ComboBox diferenciando a los homónimos por correo y teléfono
        [HttpGet("select")]
        public async Task<IActionResult> ObtenerClientesParaSelect()
        {
            var clientes = await _clienteService.ObtenerClientesParaSelectAsync();
            return Ok(clientes);
        }

        [HttpPut("{id}/estado")]
        public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoDTO dto)
        {
            var resultado = await _clienteService.CambiarEstadoClienteAsync(id, dto.Activo);

            if (!resultado)
                return NotFound(new { mensaje = "El cliente especificado no existe." });

            var mensajeEstado = dto.Activo ? "activado" : "desactivado";
            return Ok(new { mensaje = $"Cliente {mensajeEstado} correctamente." });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Actualizar(int id, [FromBody] ClienteActualizacionDTO dto)
        {
            try
            {
                var resultado = await _clienteService.ActualizarClienteAsync(id, dto);

                if (!resultado)
                    return NotFound(new { mensaje = "El cliente especificado no existe." });

                return Ok(new { mensaje = "Datos del cliente actualizados correctamente." });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { mensaje = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error interno al actualizar el cliente.", detalle = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> ObtenerPorId(int id)
        {
            var cliente = await _clienteService.ObtenerClientePorIdAsync(id);
            if (cliente == null) return NotFound(new { mensaje = "Cliente no encontrado" });
            return Ok(cliente);
        }
    }
}