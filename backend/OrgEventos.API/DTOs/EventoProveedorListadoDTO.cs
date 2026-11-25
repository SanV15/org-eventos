namespace OrgEventos.API.DTOs
{
    public class EventoProveedorListadoDTO
    {
        public int IdEventoProveedor { get; set; }
        public int IdEvento { get; set; }
        public int IdProveedor { get; set; }
        public string NombreProveedor { get; set; } = string.Empty;
        public string? TelefonoProveedor { get; set; }
        public string? CorreoProveedor { get; set; }
        public string NombreServicio { get; set; } = string.Empty;
        public string? DescripcionServicio { get; set; }
        public decimal? CostoAcordado { get; set; }
        public string EstadoOperativo { get; set; } = "Pendiente";
        public DateTime? HoraLlegada { get; set; }
        public string? Observaciones { get; set; }
    }
}
