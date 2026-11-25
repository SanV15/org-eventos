using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena las tareas necesarias para planificar y dar seguimiento a un evento.
/// </summary>
public partial class Tarea
{
    public int IdTarea { get; set; }

    public int IdEvento { get; set; }

    public int? IdUsuario { get; set; }

    public string Nombre { get; set; } = null!;

    public string? Descripcion { get; set; }

    public DateTime? FechaLimite { get; set; }

    public string Estado { get; set; } = null!;

    public virtual Evento IdEventoNavigation { get; set; } = null!;

    public virtual Usuario? IdUsuarioNavigation { get; set; }

    public virtual ICollection<IncidenciaTarea> IncidenciaTareas { get; set; } = new List<IncidenciaTarea>();
}
