using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class PagoProveedor
{
    public int IdPagoProveedor { get; set; }

    public int IdEventoProveedor { get; set; }

    public DateTime FechaPago { get; set; }

    public decimal Monto { get; set; }

    public string MetodoPago { get; set; } = null!;

    public string Estado { get; set; } = null!;

    public virtual EventoProveedor IdEventoProveedorNavigation { get; set; } = null!;
}
