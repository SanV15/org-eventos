using System.ComponentModel.DataAnnotations;

namespace OrgEventos.API.DTOs
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "El correo es obligatorio")]
        [EmailAddress(ErrorMessage = "Formate de correo inválido")]
        public string Correo { get; set; } = null!;

        [Required(ErrorMessage = "La contraseña es obligatoria")]
        public string Contrasenia { get; set; } = null!;
    }
}
