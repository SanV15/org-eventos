using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class TipoEvento
{
    public int IdTipoEvento { get; set; }

    public string Nombre { get; set; } = null!;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public virtual ICollection<Evento> Eventos { get; set; } = new List<Evento>();
}
