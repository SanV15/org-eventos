namespace OrgEventos.API.DTOs.Tareas
{
    public class TareaEventoDTO
    {
        public int IdTarea { get; set; }
        public int IdEvento { get; set; }
        public string Nombre { get; set; } = null!;
        public string? Descripcion { get; set; }
        public DateTime? FechaLimite { get; set; }
        public string? Estado { get; set; }
        public string? Observaciones { get; set; }
        public string? PersonalAsignado { get; set; }
        public int? IdUsuario { get; set; }
    }

    public class CrearTareaDTO
    {
        public int IdEvento { get; set; }
        public int? IdUsuario { get; set; }
        public string Nombre { get; set; } = null!;
        public string? Descripcion { get; set; }
        public DateTime? FechaLimite { get; set; }
        public string? Observaciones { get; set; }
    }

    public class ActualizarTareaDTO
    {
        public int? IdUsuario { get; set; }
        public string Nombre { get; set; } = null!;
        public string? Descripcion { get; set; }
        public DateTime? FechaLimite { get; set; }
        public string? Observaciones { get; set; }
    }

    // DTO unificado para la actualización de estado desde Web o Móvil
    public class ActualizarEstadoTareaDTO
    {
        public string Estado { get; set; } = string.Empty;
    }

    public class ReportarIncidenciaDTO
    {
        public string Observaciones { get; set; } = string.Empty;
    }
}