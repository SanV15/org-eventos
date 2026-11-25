using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class EventoProveedor
{
    public int IdEventoProveedor { get; set; }

    public int IdEvento { get; set; }

    public int IdServicioProveedor { get; set; }

    public decimal CostoAcordado { get; set; }

    public string? Observaciones { get; set; }

    public string EstadoOperativo { get; set; } = null!;

    public DateTime? HoraLlegada { get; set; }

    public DateTime? HoraPactada { get; set; }

    public DateTime? HoraSalida { get; set; }

    public string? EvidenciaUrl { get; set; }

    public int? IdUsuarioCheckin { get; set; }

    public virtual Evento IdEventoNavigation { get; set; } = null!;

    public virtual ServicioProveedor IdServicioProveedorNavigation { get; set; } = null!;

    public virtual Usuario? IdUsuarioCheckinNavigation { get; set; }

    public virtual ICollection<PagoProveedor> PagoProveedors { get; set; } = new List<PagoProveedor>();
}
