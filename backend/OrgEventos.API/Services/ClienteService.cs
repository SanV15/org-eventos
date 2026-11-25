using BCrypt.Net;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;
using System;

namespace OrgEventos.API.Services
{
    public class ClienteService : IClienteService
    {
        private readonly GestionEventosContext _context;
        private readonly IEmailService _emailService;

        public ClienteService(GestionEventosContext context, IEmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        public async Task<bool> RegistrarClienteAsync(ClienteRegistroDTO dto)
        {
            // 1. Validar que el correo de acceso no exista ya en USUARIO
            var existeUsuario = await _context.Usuarios.AnyAsync(u => u.Correo == dto.CorreoAcceso);
            if (existeUsuario)
                throw new InvalidOperationException("El correo de acceso ya está registrado en el sistema.");

            string contraseniaPlana = GenerarContraseniaAleatoria(8);

            // 2. Transacción de Base de Datos aislada exclusivamente para guardar datos
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // 3. Crear el USUARIO
                    var nuevoUsuario = new Usuario
                    {
                        Nombre = dto.Nombre,
                        ApellidoPaterno = dto.ApellidoPaterno,
                        ApellidoMaterno = dto.ApellidoMaterno,
                        Correo = dto.CorreoAcceso,
                        Contrasenia = BCrypt.Net.BCrypt.HashPassword(contraseniaPlana),
                        IdRol = 4, // Rol de Cliente
                        Activo = true
                    };

                    _context.Usuarios.Add(nuevoUsuario);
                    await _context.SaveChangesAsync(); // Genera el IdUsuario

                    // 4. Crear la ficha CLIENTE vinculada
                    var nuevoCliente = new Cliente
                    {
                        IdUsuario = nuevoUsuario.IdUsuario,
                        Nombre = dto.Nombre,
                        ApellidoPaterno = dto.ApellidoPaterno,
                        ApellidoMaterno = dto.ApellidoMaterno,
                        Correo = dto.CorreoAcceso,
                        Telefono = dto.Telefono,
                        Direccion = dto.Direccion,
                        Activo = true,
                        FechaRegistro = DateTime.UtcNow
                    };

                    _context.Clientes.Add(nuevoCliente);
                    await _context.SaveChangesAsync();

                    // 5. Confirmar transacción de base de datos
                    await transaction.CommitAsync();
                }
                catch (Exception)
                {
                    // Si falla la base de datos, revertimos todo de forma segura
                    await transaction.RollbackAsync();
                    throw;
                }
            } // La transacción termina y se libera aquí correctamente

            // 6. Enviar el correo electrónico FUERA de la transacción
            try
            {
                string asunto = "¡Bienvenido a OrgEventos!";
                string cuerpo = $@"
        <h2 style='color: #4F46E5;'>¡Gracias por elegirnos, {dto.Nombre}!</h2>
        <p>Tu portal de cliente ha sido creado exitosamente.</p>
        <div style='background-color: #f3f4f6; padding: 15px; border-radius: 8px;'>
            <p><strong>Usuario:</strong> {dto.CorreoAcceso}</p>
            <p><strong>Contraseña:</strong> {contraseniaPlana}</p>
        </div>
        <p><a href='http://localhost:4200/login' style='background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px;'>Acceder a mi portal</a></p>
    ";

                Console.WriteLine($"[EMAIL] Intentando disparar envío a -> {dto.CorreoAcceso}");
                await _emailService.EnviarCorreoAsync(dto.CorreoAcceso, asunto, cuerpo);
            }
            catch (Exception emailEx)
            {
                Console.WriteLine($"❌ [ERROR AL ENVIAR CORREO]: {emailEx.Message} | Inner: {emailEx.InnerException?.Message}");
            }

            return true;
        }

        public async Task<IEnumerable<ClienteListadoDTO>> ObtenerClientesAsync()
        {
            return await _context.Clientes
                .Select(c => new ClienteListadoDTO
                {
                    IdCliente = c.IdCliente,
                    NombreCompleto = $"{c.Nombre} {c.ApellidoPaterno} {c.ApellidoMaterno}".Trim(),
                    CorreoContacto = c.Correo ?? "Sin correo",
                    Telefono = c.Telefono,
                    Activo = c.Activo,
                    FechaRegistro = c.FechaRegistro
                })
                .OrderByDescending(c => c.FechaRegistro)
                .ToListAsync();
        }

        // 🔍 NUEVO MÉTODO: Obtener clientes formateados para el ComboBox (evita confusión por homónimos)
        public async Task<IEnumerable<object>> ObtenerClientesParaSelectAsync()
        {
            return await _context.Clientes
                .Where(c => c.Activo)
                .OrderBy(c => c.Nombre)
                .Select(c => new
                {
                    c.IdCliente,
                    NombreConDetalle = $"{c.Nombre} {c.ApellidoPaterno} {c.ApellidoMaterno} — ({c.Correo ?? "Sin correo"} | Tel: {c.Telefono ?? "Sin tel"})".Trim()
                })
                .ToListAsync();
        }

        public async Task<bool> CambiarEstadoClienteAsync(int idCliente, bool activo)
        {
            var cliente = await _context.Clientes.FindAsync(idCliente);
            if (cliente == null) return false;

            cliente.Activo = activo;

            var usuario = await _context.Usuarios.FindAsync(cliente.IdUsuario);
            if (usuario != null)
            {
                usuario.Activo = activo;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ActualizarClienteAsync(int idCliente, ClienteActualizacionDTO dto)
        {
            var cliente = await _context.Clientes.FindAsync(idCliente);
            if (cliente == null) return false;

            var usuario = await _context.Usuarios.FindAsync(cliente.IdUsuario);

            if (usuario != null)
            {
                if (usuario.Correo != dto.CorreoContacto)
                {
                    var correoOcupado = await _context.Usuarios.AnyAsync(u => u.Correo == dto.CorreoContacto);
                    if (correoOcupado)
                    {
                        throw new InvalidOperationException("El nuevo correo ya está en uso por otra cuenta en el sistema.");
                    }

                    usuario.Correo = dto.CorreoContacto;
                }

                usuario.Nombre = dto.Nombre;
                usuario.ApellidoPaterno = dto.ApellidoPaterno;
                usuario.ApellidoMaterno = dto.ApellidoMaterno;
            }

            cliente.Nombre = dto.Nombre;
            cliente.ApellidoPaterno = dto.ApellidoPaterno;
            cliente.ApellidoMaterno = dto.ApellidoMaterno;
            cliente.Correo = dto.CorreoContacto;
            cliente.Telefono = dto.Telefono;
            cliente.Direccion = dto.Direccion;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<ClienteActualizacionDTO?> ObtenerClientePorIdAsync(int idCliente)
        {
            var cliente = await _context.Clientes.FindAsync(idCliente);
            if (cliente == null) return null;

            return new ClienteActualizacionDTO
            {
                Nombre = cliente.Nombre,
                ApellidoPaterno = cliente.ApellidoPaterno,
                ApellidoMaterno = cliente.ApellidoMaterno,
                CorreoContacto = cliente.Correo,
                Telefono = cliente.Telefono,
                Direccion = cliente.Direccion
            };
        }

        private string GenerarContraseniaAleatoria(int longitud)
        {
            const string caracteres = "ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@$*";
            var random = new Random();
            return new string(Enumerable.Repeat(caracteres, longitud)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }
}