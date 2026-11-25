using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class IncidenciaTarea
{
    public int IdIncidencia { get; set; }

    public int IdTarea { get; set; }

    public string Observacion { get; set; } = null!;

    public DateTime FechaHora { get; set; }

    public string? FotoUrl { get; set; }

    public virtual Tarea IdTareaNavigation { get; set; } = null!;
}
