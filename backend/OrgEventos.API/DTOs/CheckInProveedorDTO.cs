namespace OrgEventos.API.DTOs
{
    public class CheckInProveedorDTO
    {
        public string EstadoOperativo { get; set; } = "En sitio"; // Pendiente, En sitio, Retrasado, Completado
        public string? Observaciones { get; set; }
        public bool RegistrarHoraLlegada { get; set; } = true;
        public DateTime? HoraPactada { get; set; }
        public DateTime? HoraLlegada { get; set; }
        public DateTime? HoraSalida { get; set; }
        public string? EvidenciaUrl { get; set; }
        public int? IdUsuarioCheckIn { get; set; }
    }
}