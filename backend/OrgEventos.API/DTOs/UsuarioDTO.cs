using System.ComponentModel.DataAnnotations;

namespace OrgEventos.API.DTOs;

public class CrearUsuarioRequest
{
    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [StringLength(100)]
    public string Nombre { get; set; } = null!;

    [Required(ErrorMessage = "El apellido paterno es obligatorio.")]
    [StringLength(100)]
    public string ApellidoPaterno { get; set; } = null!;

    [StringLength(100)]
    public string? ApellidoMaterno { get; set; }

    [Required(ErrorMessage = "El correo es obligatorio.")]
    [EmailAddress(ErrorMessage = "El correo no tiene un formato válido.")]
    [StringLength(150)]
    public string Correo { get; set; } = null!;

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    [MinLength(6, ErrorMessage = "La contraseña debe tener al menos 6 caracteres.")]
    public string Contrasenia { get; set; } = null!;

    [Range(1, int.MaxValue, ErrorMessage = "Debes seleccionar un rol válido.")]
    public int IdRol { get; set; }

    public bool Activo { get; set; } = true;
}

public class UsuarioResponseDto
{
    public int IdUsuario { get; set; }
    public string Nombre { get; set; } = null!;
    public string ApellidoPaterno { get; set; } = null!;
    public string? ApellidoMaterno { get; set; }
    public string Correo { get; set; } = null!;
    public bool Activo { get; set; }
    public int IdRol { get; set; }
    public string NombreRol { get; set; } = null!;
    public string? FotoUrl { get; set; }
}

public class RolDto
{
    public int IdRol { get; set; }
    public string Nombre { get; set; } = null!;
}