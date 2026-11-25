namespace OrgEventos.API.DTOs
{
    public class ClienteActualizacionDTO
    {
        public string Nombre { get; set; } = null!;
        public string ApellidoPaterno { get; set; } = null!;
        public string ApellidoMaterno { get; set; } = string.Empty;
        public string CorreoContacto { get; set; } = null!;
        public string Telefono { get; set; } = string.Empty;
        public string Direccion { get; set; } = string.Empty;
    }
}