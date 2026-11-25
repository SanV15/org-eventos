using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public class ServicioService : IServicioService
    {
        private readonly GestionEventosContext _context;

        public ServicioService(GestionEventosContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ServicioListadoDTO>> ObtenerServiciosAsync()
        {
            return await _context.Servicios
                .Select(s => new ServicioListadoDTO
                {
                    IdServicio = s.IdServicio,
                    Nombre = s.Nombre,
                    Descripcion = s.Descripcion,
                    Precio = s.Precio,
                    Activo = s.Activo
                })
                .ToListAsync();
        }

        public async Task<ServicioListadoDTO?> ObtenerServicioPorIdAsync(int idServicio)
        {
            var servicio = await _context.Servicios.FindAsync(idServicio);
            if (servicio == null) return null;

            return new ServicioListadoDTO
            {
                IdServicio = servicio.IdServicio,
                Nombre = servicio.Nombre,
                Descripcion = servicio.Descripcion,
                Precio = servicio.Precio,
                Activo = servicio.Activo
            };
        }

        public async Task<bool> AgregarServicioAsync(ServicioRegistroDTO dto)
        {
            var nuevoServicio = new Servicio
            {
                Nombre = dto.Nombre,
                Descripcion = dto.Descripcion,
                Precio = dto.Precio,
                Activo = true
            };

            _context.Servicios.Add(nuevoServicio);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ActualizarServicioAsync(int idServicio, ServicioRegistroDTO dto)
        {
            var servicio = await _context.Servicios.FindAsync(idServicio);
            if (servicio == null) return false;

            servicio.Nombre = dto.Nombre;
            servicio.Descripcion = dto.Descripcion;
            servicio.Precio = dto.Precio;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> CambiarEstadoServicioAsync(int idServicio, bool activo)
        {
            var servicio = await _context.Servicios.FindAsync(idServicio);
            if (servicio == null) return false;

            servicio.Activo = activo;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}