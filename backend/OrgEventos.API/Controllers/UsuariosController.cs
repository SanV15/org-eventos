using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UsuariosController : ControllerBase
{
    private readonly GestionEventosContext _context;
    private readonly IUsuariosService _usuariosService;

    public UsuariosController(GestionEventosContext context, IUsuariosService usuariosService)
    {
        _context = context;
        _usuariosService = usuariosService;
    }

    [HttpGet("empleados")]
    public async Task<IActionResult> ObtenerEmpleados()
    {
        try
        {
            // Filtramos a los usuarios activos y que NO sean clientes (IdRol != 4)
            var empleados = await _context.Usuarios
                .Where(u => u.Activo == true && u.IdRol != 4)
                .Select(u => new
                {
                    IdUsuario = u.IdUsuario,
                    Nombre = u.Nombre,
                    ApellidoPaterno = u.ApellidoPaterno,
                    IdRol = u.IdRol
                })
                .ToListAsync();

            return Ok(empleados);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al obtener la lista de empleados.", detalle = ex.Message });
        }
    }

    [Authorize(Roles = "Administrador")]
    [HttpGet("roles")]
    public async Task<IActionResult> ObtenerRoles()
    {
        try
        {
            var roles = await _usuariosService.ObtenerRolesAsync();
            return Ok(roles);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al obtener los roles.", detalle = ex.Message });
        }
    }

    [Authorize(Roles = "Administrador")]
    [HttpPost]
    public async Task<IActionResult> CrearUsuario([FromBody] CrearUsuarioRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        try
        {
            var (exito, mensaje, usuario) = await _usuariosService.CrearUsuarioAsync(request);
            if (!exito)
            {
                return BadRequest(new { mensaje });
            }

            return CreatedAtAction(nameof(ObtenerEmpleados), new { id = usuario!.IdUsuario }, new
            {
                mensaje,
                usuario
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al crear el usuario.", detalle = ex.Message });
        }
    }


    [Authorize(Roles = "Administrador")]
    [HttpGet]
    public async Task<IActionResult> ObtenerUsuarios()
    {
        try
        {
            var lista = await _usuariosService.ObtenerUsuariosAsync();
            return Ok(lista);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al obtener usuarios.", detalle = ex.Message });
        }
    }

    public record CambiarEstadoUsuarioRequest(bool Activo);

    [Authorize(Roles = "Administrador")]
    [HttpPatch("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoUsuarioRequest request)
    {
        try
        {
            var (exito, mensaje) = await _usuariosService.CambiarEstadoUsuarioAsync(id, request.Activo);
            if (!exito)
            {
                return NotFound(new { mensaje });
            }

            return Ok(new { mensaje, activo = request.Activo });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al cambiar el estado del usuario.", detalle = ex.Message });
        }
    }


    public record CambiarContraseniaRequest(string NuevaContrasenia);

    [Authorize(Roles = "Administrador")]
    [HttpPatch("{id:int}/contrasenia")]
    public async Task<IActionResult> CambiarContrasenia(int id, [FromBody] CambiarContraseniaRequest request)
    {
        try
        {
            var (exito, mensaje) = await _usuariosService.CambiarContraseniaUsuarioAsync(id, request.NuevaContrasenia);
            if (!exito)
            {
                return BadRequest(new { mensaje });
            }

            return Ok(new { mensaje });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { mensaje = "Error al actualizar la contraseña.", detalle = ex.Message });
        }
    }
}