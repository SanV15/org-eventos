namespace OrgEventos.API.DTOs
{
    public class ServicioProveedorListadoDTO
    {
        public int IdServicioProveedor { get; set; }
        public string NombreProveedor { get; set; } = string.Empty;
        public string NombreServicio { get; set; } = null!;
        public string? Descripcion { get; set; }
        public decimal Costo { get; set; }
        public string UnidadCobro { get; set; } = "Por evento";
        public bool Activo { get; set; }

        public bool EstaOcupadoHoy { get; set; }
        public string? NombreEventoActual { get; set; }
    }
}