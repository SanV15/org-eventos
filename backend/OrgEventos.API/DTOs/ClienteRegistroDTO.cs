namespace OrgEventos.API.DTOs
{
    public class ClienteRegistroDTO
    {
        // Datos Personales
        public string Nombre { get; set; } = null!;
        public string ApellidoPaterno { get; set; } = null!;
        public string ApellidoMaterno { get; set; } = string.Empty;

        // Datos de Acceso (USUARIO)
        public string CorreoAcceso { get; set; } = null!;

        // Datos de Ficha (CLIENTE)
        public string CorreoContacto { get; set; } = null!;
        public string Telefono { get; set; } = string.Empty;
        public string Direccion { get; set; } = string.Empty;
    }
}
