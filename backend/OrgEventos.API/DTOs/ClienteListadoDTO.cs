namespace OrgEventos.API.DTOs
{
    public class ClienteListadoDTO
    {
        public int IdCliente { get; set; }
        public string NombreCompleto { get; set; } = null!;
        public string CorreoContacto { get; set; } = null!;
        public string? Telefono { get; set; }
        public bool Activo { get; set; }
        public DateTime FechaRegistro { get; set; }
    }
}