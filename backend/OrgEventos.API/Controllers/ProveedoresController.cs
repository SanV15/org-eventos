using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;
using OrgEventos.API.Services;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ProveedoresController : ControllerBase
    {
        private readonly IProveedorService _proveedorService;
        private readonly ICategoriaService _categoriaService;
        private readonly GestionEventosContext _context;
        private readonly IAmazonS3 _s3Client;
        private readonly IConfiguration _config;

        public ProveedoresController(
            IProveedorService proveedorService,
            ICategoriaService categoriaService,
            GestionEventosContext context,
            IAmazonS3 s3Client,
            IConfiguration config)
        {
            _proveedorService = proveedorService;
            _categoriaService = categoriaService;
            _context = context;
            _s3Client = s3Client;
            _config = config;
        }

        [HttpGet("categorias")]
        public async Task<IActionResult> ObtenerCategorias()
        {
            var categorias = await _categoriaService.ObtenerCategoriasActivasAsync();
            return Ok(categorias);
        }

        [HttpPost("registrar")]
        public async Task<IActionResult> Registrar([FromBody] ProveedorRegistroDTO dto)
        {
            try
            {
                await _proveedorService.RegistrarProveedorAsync(dto);
                return Ok(new { mensaje = "Proveedor registrado exitosamente." });
            }
            catch (Exception ex)
            {
                var errorReal = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(500, new { mensaje = "Error interno al registrar el proveedor.", detalle = errorReal });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerTodos()
        {
            var proveedores = await _proveedorService.ObtenerProveedoresAsync();
            return Ok(proveedores);
        }

        [HttpPut("{id}/estado")]
        public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoDTO dto)
        {
            var resultado = await _proveedorService.CambiarEstadoProveedorAsync(id, dto.Activo);

            if (!resultado)
                return NotFound(new { mensaje = "El proveedor especificado no existe." });

            var mensajeEstado = dto.Activo ? "activado" : "desactivado";
            return Ok(new { mensaje = $"Proveedor {mensajeEstado} correctamente." });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> ObtenerPorId(int id)
        {
            var proveedor = await _proveedorService.ObtenerProveedorPorIdAsync(id);
            if (proveedor == null) return NotFound(new { mensaje = "Proveedor no encontrado." });
            return Ok(proveedor);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Actualizar(int id, [FromBody] ProveedorRegistroDTO dto)
        {
            try
            {
                var resultado = await _proveedorService.ActualizarProveedorAsync(id, dto);
                if (!resultado) return NotFound(new { mensaje = "Proveedor no encontrado." });

                return Ok(new { mensaje = "Proveedor actualizado correctamente." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error interno al actualizar.", detalle = ex.Message });
            }
        }

        [HttpPost("{idProveedor}/foto")]
        public async Task<IActionResult> SubirFotoProveedor(int idProveedor, IFormFile archivo)
        {
            var bucketName = _config["AWS:BucketName"] ?? "amazn-s3-bucket-san";

            if (archivo == null || archivo.Length == 0)
                return BadRequest(new { mensaje = "No se envió ninguna imagen." });

            var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
            if (!extensionesPermitidas.Contains(extension))
                return BadRequest(new { mensaje = "Formato no permitido. Usa JPG, PNG o WEBP." });

            var proveedor = await _context.Proveedors.FindAsync(idProveedor);
            if (proveedor == null)
                return NotFound(new { mensaje = "Proveedor no encontrado." });

            try
            {
                if (!string.IsNullOrEmpty(proveedor.FotoProveedorUrl) &&
                    Uri.TryCreate(proveedor.FotoProveedorUrl, UriKind.Absolute, out var uriAnterior))
                {
                    var keyAnterior = uriAnterior.AbsolutePath.TrimStart('/');
                    if (keyAnterior.StartsWith("proveedores/"))
                    {
                        await _s3Client.DeleteObjectAsync(bucketName, keyAnterior);
                    }
                }

                var nuevaKey = $"proveedores/proveedor_{idProveedor}_{Guid.NewGuid():N}{extension}";

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

                proveedor.FotoProveedorUrl = urlPublica;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    mensaje = "Imagen del proveedor actualizada correctamente.",
                    fotoProveedorUrl = urlPublica
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al subir la imagen a S3.", detalle = ex.Message });
            }
        }

        [HttpGet("con-estado")]
        public async Task<IActionResult> ObtenerProveedoresConEstado()
        {
            var proveedores = await _proveedorService.ObtenerProveedoresConEstadoAsync();
            return Ok(proveedores);
        }

        [HttpGet("{idProveedor}/fechas-ocupadas")]
        public async Task<IActionResult> ObtenerFechasOcupadasProveedor(int idProveedor)
        {
            try
            {
                var fechasOcupadas = await _context.EventoProveedors
                    .Include(ep => ep.IdEventoNavigation)
                    .Include(ep => ep.IdServicioProveedorNavigation)
                    .Where(ep => ep.IdServicioProveedorNavigation.IdProveedor == idProveedor &&
                                 ep.IdEventoNavigation != null &&
                                 ep.IdEventoNavigation.Estado != "Cancelado")
                    .Select(ep => new
                    {
                        fecha = ep.IdEventoNavigation.FechaEvento,
                        nombreEvento = ep.IdEventoNavigation.Nombre,
                        nombreServicio = ep.IdServicioProveedorNavigation.NombreServicio
                    })
                    .Distinct()
                    .ToListAsync();

                return Ok(fechasOcupadas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener el calendario de ocupación.", detalle = ex.Message });
            }
        }
        [HttpGet("evento/{idEvento}")]
        public async Task<IActionResult> ObtenerProveedoresPorEvento(int idEvento)
        {
            var asignados = await _context.EventoProveedors
                .Where(ep => ep.IdEvento == idEvento)
                .Select(ep => new
                {
                    ep.IdEventoProveedor,
                    ep.IdEvento,
                    ep.CostoAcordado,
                    ep.EstadoOperativo,
                    ep.HoraPactada,
                    ep.HoraLlegada,
                    ep.HoraSalida,
                    ep.Observaciones,
                    ep.EvidenciaUrl,
                    NombreServicio = ep.IdServicioProveedorNavigation != null
                        ? ep.IdServicioProveedorNavigation.NombreServicio
                        : "Servicio contratado",
                    DescripcionServicio = ep.IdServicioProveedorNavigation != null
                        ? ep.IdServicioProveedorNavigation.Descripcion
                        : null,
                    Proveedor = ep.IdServicioProveedorNavigation != null &&
                                ep.IdServicioProveedorNavigation.IdProveedorNavigation != null
                        ? new
                        {
                            ep.IdServicioProveedorNavigation.IdProveedorNavigation.IdProveedor,
                            NombreCompleto = ep.IdServicioProveedorNavigation.IdProveedorNavigation.Nombre + " " +
                                             (ep.IdServicioProveedorNavigation.IdProveedorNavigation.ApellidoPaterno ?? ""),
                            ep.IdServicioProveedorNavigation.IdProveedorNavigation.Telefono,
                            ep.IdServicioProveedorNavigation.IdProveedorNavigation.Correo,
                            ep.IdServicioProveedorNavigation.IdProveedorNavigation.FotoProveedorUrl
                        }
                        : null
                })
                .ToListAsync();

            return Ok(asignados);
        }

        [HttpPatch("checkin/{idEventoProveedor}")]
        public async Task<IActionResult> RegistrarCheckInProveedor(int idEventoProveedor, [FromBody] CheckInProveedorDTO dto)
        {
            var registro = await _context.EventoProveedors.FindAsync(idEventoProveedor);
            if (registro == null)
                return NotFound(new { mensaje = "Asignación de proveedor no encontrada." });

            registro.EstadoOperativo = dto.EstadoOperativo;
            registro.Observaciones = dto.Observaciones;

            if (dto.HoraPactada.HasValue)
            {
                registro.HoraPactada = dto.HoraPactada.Value;
            }

            if (dto.HoraLlegada.HasValue)
            {
                registro.HoraLlegada = dto.HoraLlegada.Value;
            }
            else if (dto.RegistrarHoraLlegada && registro.HoraLlegada == null &&
                     (dto.EstadoOperativo == "En sitio" || dto.EstadoOperativo == "Retrasado"))
            {
                registro.HoraLlegada = DateTime.Now;
            }

            if (dto.HoraSalida.HasValue)
            {
                registro.HoraSalida = dto.HoraSalida.Value;
            }
            else if (dto.EstadoOperativo == "Completado" && registro.HoraSalida == null)
            {
                registro.HoraSalida = DateTime.Now;
            }

            if (!string.IsNullOrWhiteSpace(dto.EvidenciaUrl))
            {
                registro.EvidenciaUrl = dto.EvidenciaUrl;
            }

            var idUsuarioClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                              ?? User.FindFirst("sub")?.Value
                              ?? User.FindFirst("idUsuario")?.Value;

            if (int.TryParse(idUsuarioClaim, out var idUsuarioToken))
            {
                registro.IdUsuarioCheckin = idUsuarioToken;
            }
            else if (dto.IdUsuarioCheckIn.HasValue && dto.IdUsuarioCheckIn.Value > 0)
            {
                registro.IdUsuarioCheckin = dto.IdUsuarioCheckIn.Value;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Seguimiento de proveedor actualizado",
                registro.IdEventoProveedor,
                registro.EstadoOperativo,
                registro.HoraPactada,
                registro.HoraLlegada,
                registro.HoraSalida,
                registro.Observaciones,
                registro.EvidenciaUrl,
                registro.IdUsuarioCheckin
            });
        }

        [HttpPost("checkin/{idEventoProveedor}/evidencia")]
        public async Task<IActionResult> SubirEvidenciaCheckIn(int idEventoProveedor, IFormFile archivo)
        {
            var bucketName = _config["AWS:BucketName"] ?? "amazn-s3-bucket-san";

            if (archivo == null || archivo.Length == 0)
                return BadRequest(new { mensaje = "No se envió ninguna imagen." });

            var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
            if (!extensionesPermitidas.Contains(extension))
                return BadRequest(new { mensaje = "Formato no permitido. Usa JPG, PNG o WEBP." });

            var registro = await _context.EventoProveedors.FindAsync(idEventoProveedor);
            if (registro == null)
                return NotFound(new { mensaje = "Asignación de proveedor no encontrada." });

            try
            {
                if (!string.IsNullOrEmpty(registro.EvidenciaUrl) &&
                    Uri.TryCreate(registro.EvidenciaUrl, UriKind.Absolute, out var uriAnterior))
                {
                    var keyAnterior = uriAnterior.AbsolutePath.TrimStart('/');
                    if (keyAnterior.StartsWith("checkin-proveedores/"))
                    {
                        await _s3Client.DeleteObjectAsync(bucketName, keyAnterior);
                    }
                }

                var nuevaKey = $"checkin-proveedores/checkin_{idEventoProveedor}_{Guid.NewGuid():N}{extension}";

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

                registro.EvidenciaUrl = urlPublica;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    mensaje = "Evidencia de check-in guardada correctamente.",
                    evidenciaUrl = urlPublica
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al subir la evidencia a S3.", detalle = ex.Message });
            }
        }

        //Mover esto a sus respectivos DTO
        public class ActualizarHoraPactadaDTO
        {
            public DateTime? HoraPactada { get; set; }
        }

        [HttpPatch("evento-proveedor/{idEventoProveedor}/hora-pactada")]
        public async Task<IActionResult> ActualizarHoraPactada(
            int idEventoProveedor,
            [FromBody] ActualizarHoraPactadaDTO dto)
        {
            var registro = await _context.EventoProveedors.FindAsync(idEventoProveedor);
            if (registro == null)
                return NotFound(new { mensaje = "Asignación de proveedor no encontrada." });

            registro.HoraPactada = dto.HoraPactada;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Hora pactada actualizada",
                registro.IdEventoProveedor,
                registro.HoraPactada
            });
        }

    }
}