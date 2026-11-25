namespace OrgEventos.API.DTOs.Cotizaciones
{
    public class AprobarCotizacionDTO
    {
        public string NombreEvento { get; set; } = null!;
        public int IdTipoEvento { get; set; }
        public DateOnly FechaEvento { get; set; }
        public string Lugar { get; set; } = null!;
        public int NumeroInvitados { get; set; }
        // Aquí recibiremos el ID del administrador que está aprobando el evento
        public int IdUsuarioCoordinador { get; set; }
        public DateOnly? FechaFin { get; set; }

        //Nuevo campo para las cuotas
        public int NumeroCuotas { get; set; }
    }
}