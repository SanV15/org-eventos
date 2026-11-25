using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class PlanPago
{
    public int IdPlanPago { get; set; }

    public int IdContrato { get; set; }

    public int NumeroCuotas { get; set; }

    public string Estado { get; set; } = null!;

    public virtual ICollection<Cuotum> Cuota { get; set; } = new List<Cuotum>();

    public virtual Contrato IdContratoNavigation { get; set; } = null!;
}
