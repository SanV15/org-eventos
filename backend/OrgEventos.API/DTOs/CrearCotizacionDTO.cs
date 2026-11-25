namespace OrgEventos.API.DTOs.Cotizaciones
{

    public class CotizacionResultadoDTO
    {
        public int IdCotizacion { get; set; }
        public string? Advertencia { get; set; }
    }

    public class CrearCotizacionDTO
    {
        public int IdCliente { get; set; }

        public DateOnly? FechaReferencia { get; set; } 

        public List<CrearCotizacionDetalleDTO> ServiciosInternos { get; set; } = new();
        public List<CrearCotizacionProveedorDTO> ServiciosExternos { get; set; } = new();
    }

    public class CrearCotizacionDetalleDTO
    {
        public int IdServicio { get; set; }
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
    }

    public class CrearCotizacionProveedorDTO
    {
        public int IdServicioProveedor { get; set; }
        public int Cantidad { get; set; }
        public decimal PrecioCotizado { get; set; }
        public string? Observaciones { get; set; }
    }
}