namespace OrgEventos.API.DTOs.Eventos
{
    public class PlanOperativoEventoDTO
    {
        public int IdEvento { get; set; }
        public string NombreEvento { get; set; } = string.Empty;
        public DateOnly FechaEvento { get; set; }
        public DateOnly? FechaFin { get; set; }
        public string Lugar { get; set; } = string.Empty;
        public int NumeroInvitados { get; set; }
        public bool EsEntradaLibre => NumeroInvitados <= 0;
        public string Estado { get; set; } = string.Empty;

        public List<ServicioInternoEventoDTO> ServiciosInternos { get; set; } = new();
        public List<ProveedorHorarioEventoDTO> Proveedores { get; set; } = new();
    }

    public class ServicioInternoEventoDTO
    {
        public int IdServicio { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
        public decimal Subtotal { get; set; }
    }

    public class ProveedorHorarioEventoDTO
    {
        public int IdEventoProveedor { get; set; }
        public int IdServicioProveedor { get; set; }
        public string NombreServicio { get; set; } = string.Empty;
        public string NombreProveedor { get; set; } = string.Empty;
        public string TelefonoProveedor { get; set; } = string.Empty;
        public decimal? CostoAcordado { get; set; }
        public string EstadoOperativo { get; set; } = "Pendiente";
        public DateTime? HoraPactada { get; set; }
        public DateTime? HoraLlegada { get; set; }
        public DateTime? HoraSalida { get; set; }
        public int? IdUsuarioCheckin { get; set; }
        public string Observaciones { get; set; } = string.Empty;
        public string? EvidenciaUrl { get; set; }
    }

    public class ActualizarHoraPactadaEventoDTO
    {
        public DateTime? HoraPactada { get; set; }
        public string? Observaciones { get; set; }
    }

    public class ActualizarOperacionProveedorDTO
    {
        public DateTime? HoraPactada { get; set; }
        public DateTime? HoraLlegada { get; set; }
        public DateTime? HoraSalida { get; set; }
        public string? EstadoOperativo { get; set; }
        public int? IdUsuarioCheckin { get; set; }
        public string? Observaciones { get; set; }
    }
}