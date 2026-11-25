using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena la información de los clientes de la empresa y su relación con una cuenta de usuario.
/// </summary>
public partial class Cliente
{
    public int IdCliente { get; set; }

    public int IdUsuario { get; set; }

    public string Nombre { get; set; } = null!;

    public string ApellidoPaterno { get; set; } = null!;

    public string? ApellidoMaterno { get; set; }

    public string? Telefono { get; set; }

    public string? Correo { get; set; }

    public string? Direccion { get; set; }

    public bool Activo { get; set; }

    public DateTime FechaRegistro { get; set; }

    public string? StripeCustomerId { get; set; }

    public virtual ICollection<Cotizacion> Cotizacions { get; set; } = new List<Cotizacion>();

    public virtual ICollection<Evento> Eventos { get; set; } = new List<Evento>();

    public virtual Usuario IdUsuarioNavigation { get; set; } = null!;
}
