using Amazon.S3;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.DTOs.Tareas;
using OrgEventos.API.Hubs;
using OrgEventos.API.Models;
using System.Security.Claims;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TareasController : ControllerBase
    {
        private readonly GestionEventosContext _context;
        private readonly IHubContext<EventosHub> _hubContext;
        private readonly IAmazonS3 _s3Client;
        private readonly IConfiguration _config;

        public TareasController(
                    GestionEventosContext context,
                    IHubContext<EventosHub> hubContext,
                    IAmazonS3 s3Client,                      
                    IConfiguration config)                   
        {
            _context = context;
            _hubContext = hubContext;
            _s3Client = s3Client;                    
            _config = config;                       
        }

        [HttpGet("evento/{idEvento}")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> ObtenerTareasPorEvento(int idEvento)
        {
            try
            {
                var tareas = await _context.Tareas
                    .Include(t => t.IdUsuarioNavigation)
                    .Include(t => t.IncidenciaTareas) // Cargar el historial de incidencias
                    .Where(t => t.IdEvento == idEvento)
                    .OrderBy(t => t.FechaLimite)
                    .Select(t => new
                    {
                        IdTarea = t.IdTarea,
                        IdEvento = t.IdEvento,
                        Nombre = t.Nombre,
                        Descripcion = t.Descripcion,
                        FechaLimite = t.FechaLimite,
                        Estado = t.Estado,
                        IdUsuario = t.IdUsuario,
                        PersonalAsignado = t.IdUsuarioNavigation != null
                            ? t.IdUsuarioNavigation.Nombre + " " + t.IdUsuarioNavigation.ApellidoPaterno
                            : "Sin asignar",
                        // Dentro del .Select(t => new { ... }) en ObtenerTareasPorEvento y ObtenerMisTareas:
                        Incidencias = t.IncidenciaTareas
    .OrderByDescending(i => i.FechaHora)
    .Select(i => new
    {
        IdIncidencia = i.IdIncidencia,
        Observacion = i.Observacion,
        FotoUrl = i.FotoUrl,
        FechaHora = i.FechaHora
    })
    .ToList()
                    })
                    .ToListAsync();

                return Ok(tareas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener las tareas del evento.", detalle = ex.Message });
            }
        }
        [HttpPost]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> CrearTarea([FromBody] CrearTareaDTO dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var tarea = new Tarea
            {
                IdEvento = dto.IdEvento,
                IdUsuario = dto.IdUsuario,
                Nombre = dto.Nombre,
                Descripcion = dto.Descripcion,
                FechaLimite = dto.FechaLimite,
                Estado = "Pendiente"
            };

            _context.Tareas.Add(tarea);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(dto.Observaciones))
            {
                var incidencia = new IncidenciaTarea
                {
                    IdTarea = tarea.IdTarea,
                    Observacion = dto.Observaciones,
                    FechaHora = DateTime.Now
                };
                _context.IncidenciaTareas.Add(incidencia);
                await _context.SaveChangesAsync();
            }

            // 1. Notificar al cronograma general del evento
            await _hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("TareaCreada", new
            {
                idTarea = tarea.IdTarea,
                idEvento = tarea.IdEvento
            });

            // 2. Notificar directamente al usuario asignado (Angular -> Flutter)
            if (tarea.IdUsuario.HasValue)
            {
                await _hubContext.Clients.Group($"Usuario_{tarea.IdUsuario.Value}").SendAsync("NuevaTareaAsignada", new
                {
                    idTarea = tarea.IdTarea,
                    idEvento = tarea.IdEvento,
                    nombre = tarea.Nombre
                });
            }

            return Ok(new { mensaje = "Tarea creada exitosamente." });
        }

        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarTarea(int id, [FromBody] ActualizarTareaDTO dto)
        {
            var tarea = await _context.Tareas.FindAsync(id);
            if (tarea == null)
            {
                return NotFound(new { mensaje = "Tarea no encontrada" });
            }

            int? usuarioAnterior = tarea.IdUsuario;

            tarea.Nombre = dto.Nombre;
            tarea.Descripcion = dto.Descripcion;
            tarea.FechaLimite = dto.FechaLimite;
            tarea.IdUsuario = dto.IdUsuario;

            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("TareaEditada", new
            {
                idTarea = tarea.IdTarea,
                idEvento = tarea.IdEvento,
                nombre = tarea.Nombre,
                descripcion = tarea.Descripcion,
                fechaLimite = tarea.FechaLimite,
                estado = tarea.Estado
            });

            // Si la tarea se reasignó a otro coordinador desde Angular, notificarle
            if (tarea.IdUsuario.HasValue && tarea.IdUsuario != usuarioAnterior)
            {
                await _hubContext.Clients.Group($"Usuario_{tarea.IdUsuario.Value}").SendAsync("NuevaTareaAsignada", new
                {
                    idTarea = tarea.IdTarea,
                    idEvento = tarea.IdEvento,
                    nombre = tarea.Nombre
                });
            }

            return Ok(new { mensaje = "Tarea actualizada con éxito", tarea });
        }

        //[HttpPost]
        //[Authorize(Roles = "Administrador,Coordinador")]
        //public async Task<IActionResult> CrearTarea([FromBody] CrearTareaDTO dto)
        //{
        //    if (!ModelState.IsValid) return BadRequest(ModelState);

        //    var tarea = new Tarea
        //    {
        //        IdEvento = dto.IdEvento,
        //        IdUsuario = dto.IdUsuario,
        //        Nombre = dto.Nombre,
        //        Descripcion = dto.Descripcion,
        //        FechaLimite = dto.FechaLimite,
        //        Estado = "Pendiente"
        //    };

        //    _context.Tareas.Add(tarea);
        //    await _context.SaveChangesAsync();

        //    // Si el coordinador incluye una observación inicial en la creación
        //    if (!string.IsNullOrWhiteSpace(dto.Observaciones))
        //    {
        //        var incidencia = new IncidenciaTarea
        //        {
        //            IdTarea = tarea.IdTarea,
        //            Observacion = dto.Observaciones,
        //            FechaHora = DateTime.Now
        //        };
        //        _context.IncidenciaTareas.Add(incidencia);
        //        await _context.SaveChangesAsync();
        //    }

        //    // EMITIR SIGNALR: Notificar que hay una nueva tarea para recargar las listas
        //    await _hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("TareaCreada", new { idEvento = tarea.IdEvento });

        //    return Ok(new { mensaje = "Tarea creada exitosamente." });
        //}

        [HttpDelete("{idTarea}")]
        [Authorize(Roles = "Administrador,Coordinador")]
        public async Task<IActionResult> EliminarTarea(int idTarea)
        {
            var tarea = await _context.Tareas.FindAsync(idTarea);
            if (tarea == null) return NotFound(new { mensaje = "Tarea no encontrada." });

            int idEvento = tarea.IdEvento; // Guardamos el ID antes de borrarla

            _context.Tareas.Remove(tarea);
            await _context.SaveChangesAsync();

            // EMITIR SIGNALR: Notificar que se eliminó una tarea
            await _hubContext.Clients.Group($"Evento_{idEvento}").SendAsync("TareaEliminada", new { idEvento = idEvento });

            return Ok(new { mensaje = "Hito eliminado correctamente." });
        }

        //[HttpDelete("{idTarea}")]
        //[Authorize(Roles = "Administrador,Coordinador")]
        //public async Task<IActionResult> EliminarTarea(int idTarea)
        //{
        //    var tarea = await _context.Tareas.FindAsync(idTarea);
        //    if (tarea == null) return NotFound(new { mensaje = "Tarea no encontrada." });

        //    _context.Tareas.Remove(tarea);
        //    await _context.SaveChangesAsync();
        //    return Ok(new { mensaje = "Hito eliminado correctamente." });
        //}

        [HttpGet("mis-tareas")]
        [Authorize]
        public async Task<IActionResult> ObtenerMisTareas()
        {
            var userIdClaim = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                           ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int idUsuario))
            {
                return Unauthorized(new { mensaje = "Token inválido o sin ID de usuario." });
            }

            var misTareas = await _context.Tareas
                .Include(t => t.IdEventoNavigation)
                .Include(t => t.IncidenciaTareas) // Incluir historial
                .Where(t => t.IdUsuario == idUsuario && t.IdEventoNavigation.Estado != "Cancelado")
                .OrderBy(t => t.FechaLimite)
                .Select(t => new
                {
                    IdTarea = t.IdTarea,
                    IdEvento = t.IdEvento,
                    NombreEvento = t.IdEventoNavigation.Nombre,
                    NombreTarea = t.Nombre,
                    Descripcion = t.Descripcion,
                    FechaLimite = t.FechaLimite,
                    Estado = t.Estado,
                    // Dentro del .Select(t => new { ... }) en ObtenerTareasPorEvento y ObtenerMisTareas:
                    Incidencias = t.IncidenciaTareas
    .OrderByDescending(i => i.FechaHora)
    .Select(i => new
    {
        IdIncidencia = i.IdIncidencia,
        Observacion = i.Observacion,
        FotoUrl = i.FotoUrl,
        FechaHora = i.FechaHora
    })
    .ToList()
                })
                .ToListAsync();

            return Ok(misTareas);
        }

        [Authorize]
        [HttpPatch("{id}/estado")]
        public async Task<IActionResult> ActualizarEstado(int id, [FromBody] ActualizarEstadoTareaDTO dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Estado))
                return BadRequest(new { mensaje = "El estado no puede estar vacío" });

            var tarea = await _context.Tareas.FindAsync(id);
            if (tarea == null)
                return NotFound(new { mensaje = "Tarea no encontrada" });

            // 1. RESTRICCIÓN DE NEGOCIO: Bloquear retroceso desde estados terminales
            if (tarea.Estado == "Completada" || tarea.Estado == "Cancelada")
            {
                return BadRequest(new { mensaje = "No se puede cambiar el estado de una tarea que ya está Completada o Cancelada." });
            }

            tarea.Estado = dto.Estado;
            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("TareaEstadoActualizada", new
            {
                idTarea = tarea.IdTarea,
                idEvento = tarea.IdEvento,
                nuevoEstado = tarea.Estado
            });

            return Ok(new { mensaje = "Estado actualizado correctamente", tarea });
        }

        [Authorize]
        [HttpPatch("{id}/incidencia")]
        public async Task<IActionResult> ReportarIncidencia(int id, [FromForm] string observaciones, IFormFile? archivo)
        {
            if (string.IsNullOrWhiteSpace(observaciones))
                return BadRequest(new { mensaje = "La observación no puede estar vacía." });

            var tarea = await _context.Tareas.FindAsync(id);
            if (tarea == null)
                return NotFound(new { mensaje = "Tarea no encontrada." });

            if (tarea.Estado == "Cancelada")
            {
                return BadRequest(new { mensaje = "No se pueden agregar incidencias a una tarea cancelada." });
            }

            string? fotoUrl = null;

            // Si el coordinador adjuntó una foto de evidencia
            if (archivo != null && archivo.Length > 0)
            {
                var bucketName = _config["AWS:BucketName"] ?? "amazn-s3-bucket-san";
                var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
                var nuevaKey = $"incidencias/tarea_{id}_{Guid.NewGuid():N}{extension}";

                using var stream = archivo.OpenReadStream();
                var putRequest = new Amazon.S3.Model.PutObjectRequest
                {
                    BucketName = bucketName,
                    Key = nuevaKey,
                    InputStream = stream,
                    ContentType = archivo.ContentType,
                    CannedACL = Amazon.S3.S3CannedACL.PublicRead // Hace pública la foto de la incidencia
                };

                await _s3Client.PutObjectAsync(putRequest);
                var region = _s3Client.Config.RegionEndpoint?.SystemName ?? "us-west-2";
                fotoUrl = $"https://{bucketName}.s3.{region}.amazonaws.com/{nuevaKey}";
            }

            var nuevaIncidencia = new IncidenciaTarea
            {
                IdTarea = id,
                Observacion = observaciones,
                FechaHora = DateTime.Now,
                FotoUrl = fotoUrl 
            };

            _context.IncidenciaTareas.Add(nuevaIncidencia);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group($"Evento_{tarea.IdEvento}").SendAsync("IncidenciaReportada", new
            {
                idTarea = tarea.IdTarea,
                idEvento = tarea.IdEvento,
                nombreTarea = tarea.Nombre,
                observaciones = nuevaIncidencia.Observacion,
                fotoUrl = nuevaIncidencia.FotoUrl,
                fechaHora = nuevaIncidencia.FechaHora
            });

            return Ok(new { mensaje = "Incidencia registrada correctamente.", observaciones = nuevaIncidencia.Observacion, fotoUrl });
        }


    }
}