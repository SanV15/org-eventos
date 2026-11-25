using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena las cotizaciones generadas para los clientes.
/// </summary>
public partial class Cotizacion
{
    public int IdCotizacion { get; set; }

    public int IdCliente { get; set; }

    public DateOnly Fecha { get; set; }

    public string Estado { get; set; } = null!;

    public decimal Total { get; set; }

    public DateOnly? FechaReferencia { get; set; }

    public virtual ICollection<CotizacionDetalle> CotizacionDetalles { get; set; } = new List<CotizacionDetalle>();

    public virtual ICollection<CotizacionProveedor> CotizacionProveedors { get; set; } = new List<CotizacionProveedor>();

    public virtual ICollection<Evento> Eventos { get; set; } = new List<Evento>();

    public virtual Cliente IdClienteNavigation { get; set; } = null!;
}
