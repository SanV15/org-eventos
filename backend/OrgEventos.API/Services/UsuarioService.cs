using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;
using OrgEventos.API.Services;

public class UsuariosService : IUsuariosService
{
    private readonly GestionEventosContext _context;

    public UsuariosService(GestionEventosContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<RolDto>> ObtenerRolesAsync()
    {
        return await _context.Rols
            .AsNoTracking()
            .OrderBy(r => r.IdRol)
            .Select(r => new RolDto
            {
                IdRol = r.IdRol,
                Nombre = r.Nombre
            })
            .ToListAsync();
    }

    public async Task<IEnumerable<UsuarioResponseDto>> ObtenerUsuariosAsync()
    {
        return await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.IdRolNavigation)
            .OrderBy(u => u.IdUsuario)
            .Select(u => new UsuarioResponseDto
            {
                IdUsuario = u.IdUsuario,
                Nombre = u.Nombre,
                ApellidoPaterno = u.ApellidoPaterno,
                ApellidoMaterno = u.ApellidoMaterno,
                Correo = u.Correo,
                Activo = u.Activo,
                IdRol = u.IdRol,
                NombreRol = u.IdRolNavigation.Nombre,
                FotoUrl = u.FotoUrl
            })
            .ToListAsync();
    }

    public async Task<(bool Exito, string Mensaje)> CambiarEstadoUsuarioAsync(int idUsuario, bool activo)
    {
        var usuario = await _context.Usuarios.FindAsync(idUsuario);
        if (usuario == null)
        {
            return (false, "Usuario no encontrado.");
        }

        usuario.Activo = activo;
        await _context.SaveChangesAsync();
        return (true, activo ? "Usuario activado correctamente." : "Usuario desactivado correctamente.");
    }

    public async Task<(bool Exito, string Mensaje, UsuarioResponseDto? Usuario)> CrearUsuarioAsync(CrearUsuarioRequest request)
    {
        var correoNormalizado = request.Correo.Trim().ToLowerInvariant();

        var correoExiste = await _context.Usuarios
            .AnyAsync(u => u.Correo.ToLower() == correoNormalizado);

        if (correoExiste)
        {
            return (false, "Ya existe un usuario registrado con ese correo electrónico.", null);
        }

        var rolExiste = await _context.Rols
            .FirstOrDefaultAsync(r => r.IdRol == request.IdRol);

        if (rolExiste == null)
        {
            return (false, "El rol especificado no existe en el sistema.", null);
        }

        var nuevoUsuario = new Usuario
        {
            Nombre = request.Nombre.Trim(),
            ApellidoPaterno = request.ApellidoPaterno.Trim(),
            ApellidoMaterno = string.IsNullOrWhiteSpace(request.ApellidoMaterno)
                ? null
                : request.ApellidoMaterno.Trim(),
            Correo = correoNormalizado,
            Contrasenia = BCrypt.Net.BCrypt.HashPassword(request.Contrasenia),
            IdRol = rolExiste.IdRol,
            Activo = request.Activo,
            FotoUrl = null
        };

        _context.Usuarios.Add(nuevoUsuario);
        await _context.SaveChangesAsync();

        var respuesta = new UsuarioResponseDto
        {
            IdUsuario = nuevoUsuario.IdUsuario,
            Nombre = nuevoUsuario.Nombre,
            ApellidoPaterno = nuevoUsuario.ApellidoPaterno,
            ApellidoMaterno = nuevoUsuario.ApellidoMaterno,
            Correo = nuevoUsuario.Correo,
            Activo = nuevoUsuario.Activo,
            IdRol = nuevoUsuario.IdRol,
            NombreRol = rolExiste.Nombre,
            FotoUrl = nuevoUsuario.FotoUrl
        };

        return (true, "Usuario creado correctamente.", respuesta);
    }

    public async Task<(bool Exito, string Mensaje)> CambiarContraseniaUsuarioAsync(int idUsuario, string nuevaContrasenia)
    {
        var usuario = await _context.Usuarios.FindAsync(idUsuario);
        if (usuario == null)
        {
            return (false, "Usuario no encontrado");
        }

        if (string.IsNullOrWhiteSpace(nuevaContrasenia) || nuevaContrasenia.Length < 6 )
        {
            return (false, "La nueva contraseña debe tener al menos 6 caracteres.");
        }

        usuario.Contrasenia = BCrypt.Net.BCrypt.HashPassword(nuevaContrasenia);

        await _context.SaveChangesAsync();
        return (true, "Contrasenia actualizada correctamente");


    }
}