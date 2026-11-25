using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Contiene el catálogo de servicios que ofrece la empresa organizadora de eventos.
/// </summary>
public partial class Servicio
{
    public int IdServicio { get; set; }

    public string Nombre { get; set; } = null!;

    public string? Descripcion { get; set; }

    public decimal Precio { get; set; }

    public bool Activo { get; set; }

    public virtual ICollection<CotizacionDetalle> CotizacionDetalles { get; set; } = new List<CotizacionDetalle>();
}
