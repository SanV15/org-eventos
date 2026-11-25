using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public class ServicioProveedorService : IServicioProveedorService
    {
        private readonly GestionEventosContext _context;

        public ServicioProveedorService(GestionEventosContext context)
        {
            _context = context;
        }

        private static string NormalizarUnidadCobro(string? unidad)
        {
            if (string.IsNullOrWhiteSpace(unidad)) return "Por evento";
            var limpia = unidad.Trim();
            return string.Equals(limpia, "Por unidad", StringComparison.OrdinalIgnoreCase)
                ? "Por unidad"
                : "Por evento";
        }

        public async Task<IEnumerable<ServicioProveedorListadoDTO>> ObtenerTodosAsync()
        {
            return await _context.ServicioProveedors
                .Include(s => s.IdProveedorNavigation)
                .Where(s => s.Activo == true && s.IdProveedorNavigation.Activo == true)
                .Select(s => new ServicioProveedorListadoDTO
                {
                    IdServicioProveedor = s.IdServicioProveedor,
                    NombreProveedor = s.IdProveedorNavigation != null
    ? $"{s.IdProveedorNavigation.Nombre} {s.IdProveedorNavigation.ApellidoPaterno}".Trim()
    : "Proveedor",
                    NombreServicio = s.NombreServicio,

                    Descripcion = s.Descripcion,
                    Costo = s.Costo,
                    UnidadCobro = s.UnidadCobro ?? "Por evento",
                    Activo = s.Activo
                }).ToListAsync();
        }

        public async Task<IEnumerable<ServicioProveedorListadoDTO>> ObtenerServiciosPorProveedorAsync(int idProveedor)
        {
            var hoy = DateOnly.FromDateTime(DateTime.Today);
            Console.WriteLine($"[DEBUG DISPONIBILIDAD] Buscando eventos para hoy: {hoy}");

            return await _context.ServicioProveedors
                .Where(s => s.IdProveedor == idProveedor)
                .Select(s => new ServicioProveedorListadoDTO
                {
                    IdServicioProveedor = s.IdServicioProveedor,
                    NombreServicio = s.NombreServicio,
                    Descripcion = s.Descripcion,
                    Costo = s.Costo,
                    UnidadCobro = s.UnidadCobro ?? "Por evento",
                    Activo = s.Activo,

                    EstaOcupadoHoy = s.EventoProveedors
                        .Any(ep => ep.IdEventoNavigation != null &&
                                   ep.IdEventoNavigation.FechaEvento == hoy &&
                                   ep.IdEventoNavigation.Estado != "Cancelado"),

                    NombreEventoActual = s.EventoProveedors
                        .Where(ep => ep.IdEventoNavigation != null &&
                                     ep.IdEventoNavigation.FechaEvento == hoy &&
                                     ep.IdEventoNavigation.Estado != "Cancelado")
                        .Select(ep => ep.IdEventoNavigation.Nombre)
                        .FirstOrDefault()
                })
                .ToListAsync();
        }

        public async Task<bool> AgregarServicioAsync(int idProveedor, ServicioProveedorRegistroDTO dto)
        {
            var proveedorExiste = await _context.Proveedors.AnyAsync(p => p.IdProveedor == idProveedor);
            if (!proveedorExiste) return false;

            var nuevoServicio = new ServicioProveedor
            {
                IdProveedor = idProveedor,
                NombreServicio = dto.NombreServicio,
                Descripcion = dto.Descripcion,
                Costo = dto.Costo,
                UnidadCobro = NormalizarUnidadCobro(dto.UnidadCobro),
                Activo = true
            };

            _context.ServicioProveedors.Add(nuevoServicio);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ActualizarServicioAsync(int idServicioProveedor, ServicioProveedorRegistroDTO dto)
        {
            var servicio = await _context.ServicioProveedors.FindAsync(idServicioProveedor);
            if (servicio == null) return false;

            servicio.NombreServicio = dto.NombreServicio;
            servicio.Descripcion = dto.Descripcion;
            servicio.Costo = dto.Costo;
            servicio.UnidadCobro = NormalizarUnidadCobro(dto.UnidadCobro);

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> CambiarEstadoServicioAsync(int idServicioProveedor, bool activo)
        {
            var servicio = await _context.ServicioProveedors.FindAsync(idServicioProveedor);
            if (servicio == null) return false;

            servicio.Activo = activo;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}