using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena la información de los proveedores externos utilizados por la empresa.
/// </summary>
public partial class Proveedor
{
    public int IdProveedor { get; set; }

    public string Nombre { get; set; } = null!;

    public string? ApellidoPaterno { get; set; }

    public string? ApellidoMaterno { get; set; }

    public string? Telefono { get; set; }

    public string? Correo { get; set; }

    public string? Direccion { get; set; }

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public string? Banco { get; set; }

    public string? ClabeInterbancaria { get; set; }

    public string? TitularCuenta { get; set; }

    public string? FotoProveedorUrl { get; set; }

    public virtual ICollection<ProveedorCategorium> ProveedorCategoria { get; set; } = new List<ProveedorCategorium>();

    public virtual ICollection<ServicioProveedor> ServicioProveedors { get; set; } = new List<ServicioProveedor>();
}
