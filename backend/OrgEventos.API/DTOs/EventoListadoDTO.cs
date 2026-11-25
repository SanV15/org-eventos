namespace OrgEventos.API.DTOs
{
    public class EventoListadoDTO
    {
        public int IdEvento { get; set; }
        public string Cliente { get; set; } = null!;
        public string NombreEvento { get; set; } = null!;
        public DateTime FechaEvento { get; set; }
        public string Estado { get; set; } = null!;
        public int IdCliente { get; set; }
        public string? FotoEventoUrl { get; set; }
    }
}