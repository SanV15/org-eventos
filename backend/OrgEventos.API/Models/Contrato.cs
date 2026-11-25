using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class Contrato
{
    public int IdContrato { get; set; }

    public int IdEvento { get; set; }

    public DateTime FechaContrato { get; set; }

    public decimal MontoAcordado { get; set; }

    public string Estado { get; set; } = null!;

    public virtual Evento IdEventoNavigation { get; set; } = null!;

    public virtual PlanPago? PlanPago { get; set; }
}
