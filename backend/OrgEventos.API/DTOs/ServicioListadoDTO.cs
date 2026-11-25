namespace OrgEventos.API.DTOs
{
    public class ServicioListadoDTO
    {
        public int IdServicio { get; set; }
        public string Nombre { get; set; } = null!;
        public string? Descripcion { get; set; }
        public decimal Precio { get; set; }
        public bool Activo { get; set; }
    }
}