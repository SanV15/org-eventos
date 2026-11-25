using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class Cuotum
{
    public int IdCuota { get; set; }

    public int IdPlanPago { get; set; }

    public int NumeroCuota { get; set; }

    public DateOnly FechaLimite { get; set; }

    public decimal Monto { get; set; }

    public string Estado { get; set; } = null!;

    public virtual PlanPago IdPlanPagoNavigation { get; set; } = null!;

    public virtual ICollection<PagoCliente> PagoClientes { get; set; } = new List<PagoCliente>();
}
