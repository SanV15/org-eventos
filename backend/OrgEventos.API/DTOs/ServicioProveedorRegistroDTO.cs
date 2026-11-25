namespace OrgEventos.API.DTOs
{
    public class ServicioProveedorRegistroDTO
    {
        public string NombreServicio { get; set; } = null!;
        public string? Descripcion { get; set; }
        public decimal Costo { get; set; }
        public string UnidadCobro { get; set; } = "Por evento";
    }
}