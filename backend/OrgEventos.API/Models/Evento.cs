using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Representa un evento contratado o en proceso de planificación para un cliente.
/// </summary>
public partial class Evento
{
    public int IdEvento { get; set; }

    public int IdCliente { get; set; }

    public int? IdCotizacion { get; set; }

    public int? IdUsuarioCoordinador { get; set; }

    public string Nombre { get; set; } = null!;

    public DateOnly FechaEvento { get; set; }

    public string Lugar { get; set; } = null!;

    public int NumeroInvitados { get; set; }

    public string Estado { get; set; } = null!;

    public int IdTipoEvento { get; set; }

    public string? FotoEventoUrl { get; set; }

    public DateOnly? FechaFin { get; set; }

    public virtual Contrato? Contrato { get; set; }

    public virtual ICollection<EventoProveedor> EventoProveedors { get; set; } = new List<EventoProveedor>();

    public virtual Cliente IdClienteNavigation { get; set; } = null!;

    public virtual Cotizacion? IdCotizacionNavigation { get; set; }

    public virtual TipoEvento IdTipoEventoNavigation { get; set; } = null!;

    public virtual Usuario? IdUsuarioCoordinadorNavigation { get; set; }

    public virtual ICollection<Tarea> Tareas { get; set; } = new List<Tarea>();
}
