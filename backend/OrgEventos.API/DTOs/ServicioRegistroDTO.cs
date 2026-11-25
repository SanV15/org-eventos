namespace OrgEventos.API.DTOs
{
    public class ServicioRegistroDTO
    {
        public string Nombre { get; set; } = null!;
        public string? Descripcion { get; set; }
        public decimal Precio { get; set; }
    }
}