using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class PagoCliente
{
    public int IdPagoCliente { get; set; }

    public int IdCuota { get; set; }

    public DateTime FechaPago { get; set; }

    public decimal Monto { get; set; }

    public string? MetodoPago { get; set; }

    public string Estado { get; set; } = null!;

    public virtual Cuotum IdCuotaNavigation { get; set; } = null!;
}
