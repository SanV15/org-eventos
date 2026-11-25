namespace OrgEventos.API.DTOs
{
    public class ProveedorRegistroDTO
    {
        public string Nombre { get; set; } = null!;
        public string? ApellidoPaterno { get; set; }
        public string? ApellidoMaterno { get; set; }
        public string? Telefono { get; set; }
        public string? Correo { get; set; }
        public string? Direccion { get; set; }
        public string? Descripcion { get; set; }

        public string? Banco { get; set; }
        public string? ClabeInterbancaria { get; set; }
        public string? TitularCuenta { get; set; }

        public List<int> CategoriasIds { get; set; } = new List<int>();
        public string? FotoProveedorUrl { get; set; }
    }
}