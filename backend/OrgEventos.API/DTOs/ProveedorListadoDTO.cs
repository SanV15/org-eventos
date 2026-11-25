namespace OrgEventos.API.DTOs
{
    public class ProveedorListadoDTO
    {
        public int IdProveedor { get; set; }
        public string NombreCompleto { get; set; } = null!;
        public string? Telefono { get; set; }
        public string? Correo { get; set; }
        public bool Activo { get; set; }
        public string Categorias { get; set; } = string.Empty;
        public string? FotoProveedorUrl { get; set; }
    }
}