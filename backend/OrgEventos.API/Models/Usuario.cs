using System;
using System.Collections.Generic;

namespace OrgEventos.API.Models;

/// <summary>
/// Almacena las cuentas de acceso de todos los usuarios del sistema y su rol.
/// </summary>
public partial class Usuario
{
    public int IdUsuario { get; set; }

    public string Nombre { get; set; } = null!;

    public string ApellidoPaterno { get; set; } = null!;

    public string? ApellidoMaterno { get; set; }

    public string Correo { get; set; } = null!;

    public string Contrasenia { get; set; } = null!;

    public bool Activo { get; set; }

    public int IdRol { get; set; }

    public string? FotoUrl { get; set; }

    public virtual Cliente? Cliente { get; set; }

    public virtual ICollection<EventoProveedor> EventoProveedors { get; set; } = new List<EventoProveedor>();

    public virtual ICollection<Evento> Eventos { get; set; } = new List<Evento>();

    public virtual Rol IdRolNavigation { get; set; } = null!;

    public virtual ICollection<Tarea> Tareas { get; set; } = new List<Tarea>();
}
