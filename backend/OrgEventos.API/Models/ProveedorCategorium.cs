using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Representa la relación muchos a muchos entre proveedores y categorías.
/// </summary>
public partial class ProveedorCategorium
{
    public int IdProveedorCategoria { get; set; }

    public int IdProveedor { get; set; }

    public int IdCategoria { get; set; }

    public virtual CategoriaProveedor IdCategoriaNavigation { get; set; } = null!;

    public virtual Proveedor IdProveedorNavigation { get; set; } = null!;
}
