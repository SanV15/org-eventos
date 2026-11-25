using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Contiene las categorías utilizadas para clasificar a los proveedores.
/// </summary>
public partial class CategoriaProveedor
{
    public int IdCategoria { get; set; }

    public string Nombre { get; set; } = null!;

    public string? Descripcion { get; set; }

    public virtual ICollection<ProveedorCategorium> ProveedorCategoria { get; set; } = new List<ProveedorCategorium>();
}
