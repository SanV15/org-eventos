using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

public partial class CotizacionProveedor
{
    public int IdCotizacionProveedor { get; set; }

    public int IdCotizacion { get; set; }

    public int IdServicioProveedor { get; set; }

    public int Cantidad { get; set; }

    public decimal PrecioCotizado { get; set; }

    public string? Observaciones { get; set; }

    public virtual Cotizacion IdCotizacionNavigation { get; set; } = null!;

    public virtual ServicioProveedor IdServicioProveedorNavigation { get; set; } = null!;
}
