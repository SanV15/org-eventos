using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Detalla los servicios incluidos en cada cotización, incluyendo cantidad y precio utilizado al momento de cotizar.
/// </summary>
public partial class CotizacionDetalle
{
    public int IdDetalle { get; set; }

    public int IdCotizacion { get; set; }

    public int IdServicio { get; set; }

    public int Cantidad { get; set; }

    public decimal PrecioUnitario { get; set; }

    public virtual Cotizacion IdCotizacionNavigation { get; set; } = null!;

    public virtual Servicio IdServicioNavigation { get; set; } = null!;
}
