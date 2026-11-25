//using Microsoft.AspNetCore.Mvc;
//using Microsoft.IdentityModel.Tokens;
//using OrgEventos.API.Models;
//using OrgEventos.API.DTOs;
//using System.IdentityModel.Tokens.Jwt;
//using System.Security.Claims;
//using System.Text;
//using Microsoft.EntityFrameworkCore;

//namespace OrgEventos.API.Controllers
//{
//    [Route("api/[controller]")]
//    [ApiController]
//    public class AuthController : ControllerBase
//    {
//        // Asegúrate de que el nombre coincida con el archivo Context que se generó
//        private readonly GestionEventosContext _context;
//        private readonly IConfiguration _config;

//        public AuthController(GestionEventosContext context, IConfiguration config)
//        {
//            _context = context;
//            _config = config;
//        }

//[HttpPost("login")]
//        public async Task<IActionResult> Login([FromBody] LoginRequest request) 
//        { 
//            var usuario = await _context.Usuarios
//                .Include(u => u.IdRolNavigation)
//                .FirstOrDefaultAsync(u => u.Correo == request.Correo);

//            // AQUÍ AGREGAMOS LA CONDICIÓN: !usuario.Activo
//            // Si el usuario no existe, O está inactivo, O la contraseña es incorrecta, lo rechazamos con el mismo mensaje.
//            if (usuario == null || !usuario.Activo || !BCrypt.Net.BCrypt.Verify(request.Contrasenia, usuario.Contrasenia))
//            {
//                return Unauthorized(new { mensaje = "Credenciales incorrectas" });
//            }

//            // Ya no necesitamos la variable 'claims' suelta aquí ni verificar la contraseña otra vez, 
//            // pasamos directo a generar el token porque el método GenerarJwt ya hace el trabajo de los claims.
//            var token = GenerarJwt(usuario);

//            return Ok(new
//            {
//                mensaje = "Login exitoso",
//                token = token
//            });
//        }

//        [HttpGet("generar-hash")]
//        public IActionResult GenerarHash(string textoPlano)
//        {
//            // Esto encripta cualquier texto que le pases usando BCrypt
//            var hashGenerado = BCrypt.Net.BCrypt.HashPassword(textoPlano);
//            return Ok(new { hash = hashGenerado });
//        }

//        private string GenerarJwt(Usuario usuario)
//        {
//            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["JwtSettings:SecretKey"]!));
//            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

//            var claims = new[]
//            {
//                new Claim(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
//                new Claim(JwtRegisteredClaimNames.Email, usuario.Correo),
//// Por esto:
//new Claim(ClaimTypes.Role, usuario.IdRolNavigation.Nombre),
//                new Claim("nombre_completo", $"{usuario.Nombre} {usuario.ApellidoPaterno}")
//            };

//            var token = new JwtSecurityToken(
//                issuer: _config["JwtSettings:Issuer"],
//                audience: _config["JwtSettings:Audience"],
//                claims: claims,
//                expires: DateTime.Now.AddHours(8),
//                signingCredentials: credentials);

//            return new JwtSecurityTokenHandler().WriteToken(token);
//        }
//    }
//}

using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly GestionEventosContext _context;
        private readonly IConfiguration _config;
        private readonly IAmazonS3 _s3Client;
        //private const string BucketName = "amzn-s3-bucket-san";

        public AuthController(GestionEventosContext context, IConfiguration config, IAmazonS3 s3Client)
        {
            _context = context;
            _config = config;
            _s3Client = s3Client;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var usuario = await _context.Usuarios
                .Include(u => u.IdRolNavigation)
                .FirstOrDefaultAsync(u => u.Correo == request.Correo);

            if (usuario == null || !usuario.Activo || !BCrypt.Net.BCrypt.Verify(request.Contrasenia, usuario.Contrasenia))
            {
                return Unauthorized(new { mensaje = "Credenciales incorrectas" });
            }

            var token = GenerarJwt(usuario);

            return Ok(new
            {
                mensaje = "Login exitoso",
                token = token
            });
        }

        [HttpGet("generar-hash")]
        public IActionResult GenerarHash(string textoPlano)
        {
            var hashGenerado = BCrypt.Net.BCrypt.HashPassword(textoPlano);
            return Ok(new { hash = hashGenerado });
        }
        [Authorize]
        [HttpPost("foto-perfil")]
        public async Task<IActionResult> SubirFotoPerfil(IFormFile archivo)
        {
            var bucketName = _config["AWS:BucketName"] ?? "amazn-s3-bucket-san";

            if (archivo == null || archivo.Length == 0)
                return BadRequest(new { mensaje = "No se envió ninguna imagen." });

            var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
            if (!extensionesPermitidas.Contains(extension))
                return BadRequest(new { mensaje = "Formato no permitido. Usa JPG, PNG o WEBP." });

            var subClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                           ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

            if (!int.TryParse(subClaim, out int idUsuario))
                return Unauthorized(new { mensaje = "Token inválido." });

            var usuario = await _context.Usuarios.FindAsync(idUsuario);
            if (usuario == null)
                return NotFound(new { mensaje = "Usuario no encontrado." });

            try
            {
                if (!string.IsNullOrEmpty(usuario.FotoUrl) &&
                    Uri.TryCreate(usuario.FotoUrl, UriKind.Absolute, out var uriAnterior))
                {
                    var keyAnterior = uriAnterior.AbsolutePath.TrimStart('/');
                    if (keyAnterior.StartsWith("perfiles/"))
                    {
                        await _s3Client.DeleteObjectAsync(bucketName, keyAnterior);
                    }
                }

                var nuevaKey = $"perfiles/usuario_{idUsuario}_{Guid.NewGuid():N}{extension}";

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

                usuario.FotoUrl = urlPublica;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    mensaje = "Foto de perfil actualizada correctamente.",
                    fotoUrl = urlPublica
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al subir la imagen a S3.", detalle = ex.Message });
            }
        }
        private string GenerarJwt(Usuario usuario)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["JwtSettings:SecretKey"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, usuario.Correo),
                new Claim(ClaimTypes.Role, usuario.IdRolNavigation.Nombre),
                new Claim("nombre_completo", $"{usuario.Nombre} {usuario.ApellidoPaterno}"),
                new Claim("foto_url", usuario.FotoUrl ?? "")
            };

            var token = new JwtSecurityToken(
                issuer: _config["JwtSettings:Issuer"],
                audience: _config["JwtSettings:Audience"],
                claims: claims,
                expires: DateTime.Now.AddHours(8),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}