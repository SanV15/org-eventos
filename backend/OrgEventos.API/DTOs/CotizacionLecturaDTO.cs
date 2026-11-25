namespace OrgEventos.API.DTOs.Cotizaciones
{
    public class CotizacionLecturaDTO
    {
        public int IdCotizacion { get; set; }
        public int IdCliente { get; set; }
        public string NombreClienteCompleto { get; set; } = null!;
        public DateOnly Fecha { get; set; }
        public DateOnly? FechaReferencia { get; set; }
        public string Estado { get; set; } = null!;
        public decimal Total { get; set; }

        public List<CotizacionDetalleLecturaDTO> ServiciosInternos { get; set; } = new();
        public List<CotizacionProveedorLecturaDTO> ServiciosExternos { get; set; } = new();
    }

    public class CotizacionDetalleLecturaDTO
    {
        public int IdDetalle { get; set; }
        public int IdServicio { get; set; }
        public string NombreServicio { get; set; } = null!;
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
        public decimal Subtotal => Cantidad * PrecioUnitario; // Calculado automáticamente
    }

    public class CotizacionProveedorLecturaDTO
    {
        public int IdCotizacionProveedor { get; set; }
        public int IdServicioProveedor { get; set; }
        public string NombreServicioProveedor { get; set; } = null!;
        public string NombreEmpresaProveedor { get; set; } = null!;
        public int Cantidad { get; set; }
        public decimal PrecioCotizado { get; set; }
        public string UnidadCobro { get; set; } = "Por evento";
        public string? Observaciones { get; set; }
        public decimal Subtotal => Cantidad * PrecioCotizado; // Calculado automáticamente
    }
}