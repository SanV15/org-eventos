using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena los servicios que ofrece cada proveedor y su costo de referencia.
/// </summary>
public partial class ServicioProveedor
{
    public int IdServicioProveedor { get; set; }

    public int IdProveedor { get; set; }

    public string NombreServicio { get; set; } = null!;

    public string? Descripcion { get; set; }

    public decimal Costo { get; set; }

    public bool Activo { get; set; }

    public string UnidadCobro { get; set; } = null!;

    public virtual ICollection<CotizacionProveedor> CotizacionProveedors { get; set; } = new List<CotizacionProveedor>();

    public virtual ICollection<EventoProveedor> EventoProveedors { get; set; } = new List<EventoProveedor>();

    public virtual Proveedor IdProveedorNavigation { get; set; } = null!;
}
