using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public class ProveedorService : IProveedorService
    {
        private readonly GestionEventosContext _context;

        public ProveedorService(GestionEventosContext context)
        {
            _context = context;
        }

        public async Task<bool> RegistrarProveedorAsync(ProveedorRegistroDTO dto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var nuevoProveedor = new Proveedor
                {
                    Nombre = dto.Nombre,
                    ApellidoPaterno = dto.ApellidoPaterno,
                    ApellidoMaterno = dto.ApellidoMaterno,
                    Telefono = dto.Telefono,
                    Correo = dto.Correo,
                    Direccion = dto.Direccion,
                    Descripcion = dto.Descripcion,
                    Banco = dto.Banco,
                    ClabeInterbancaria = dto.ClabeInterbancaria,
                    TitularCuenta = dto.TitularCuenta,
                    Activo = true
                };

                _context.Proveedors.Add(nuevoProveedor);
                await _context.SaveChangesAsync();

                if (dto.CategoriasIds != null && dto.CategoriasIds.Any())
                {
                    foreach (var idCategoria in dto.CategoriasIds)
                    {
                        var relacion = new ProveedorCategorium
                        {
                            IdProveedor = nuevoProveedor.IdProveedor,
                            IdCategoria = idCategoria
                        };
                        _context.ProveedorCategoria.Add(relacion);
                    }
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<IEnumerable<ProveedorListadoDTO>> ObtenerProveedoresAsync()
        {
            return await _context.Proveedors
                .Include(p => p.ProveedorCategoria)
                    .ThenInclude(pc => pc.IdCategoriaNavigation)
                .Select(p => new ProveedorListadoDTO
                {
                    IdProveedor = p.IdProveedor,
                    NombreCompleto = $"{p.Nombre} {p.ApellidoPaterno} {p.ApellidoMaterno}".Trim(),
                    Telefono = p.Telefono,
                    Correo = p.Correo,
                    Activo = p.Activo,
                    FotoProveedorUrl = p.FotoProveedorUrl,
                    Categorias = string.Join(", ", p.ProveedorCategoria.Select(pc => pc.IdCategoriaNavigation.Nombre))
                })
                .ToListAsync();
        }

        public async Task<bool> CambiarEstadoProveedorAsync(int idProveedor, bool activo)
        {
            var proveedor = await _context.Proveedors.FindAsync(idProveedor);
            if (proveedor == null) return false;

            proveedor.Activo = activo;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<ProveedorRegistroDTO?> ObtenerProveedorPorIdAsync(int idProveedor)
        {
            var proveedor = await _context.Proveedors
                .Include(p => p.ProveedorCategoria)
                .FirstOrDefaultAsync(p => p.IdProveedor == idProveedor);

            if (proveedor == null) return null;

            return new ProveedorRegistroDTO
            {
                Nombre = proveedor.Nombre,
                ApellidoPaterno = proveedor.ApellidoPaterno,
                ApellidoMaterno = proveedor.ApellidoMaterno,
                Correo = proveedor.Correo,
                Telefono = proveedor.Telefono,
                Direccion = proveedor.Direccion,
                Descripcion = proveedor.Descripcion,
                Banco = proveedor.Banco,
                ClabeInterbancaria = proveedor.ClabeInterbancaria,
                TitularCuenta = proveedor.TitularCuenta,
                FotoProveedorUrl = proveedor.FotoProveedorUrl,
                CategoriasIds = proveedor.ProveedorCategoria.Select(pc => pc.IdCategoria).ToList()
            };
        }

        public async Task<bool> ActualizarProveedorAsync(int idProveedor, ProveedorRegistroDTO dto)
        {
            var proveedor = await _context.Proveedors
                .Include(p => p.ProveedorCategoria)
                .FirstOrDefaultAsync(p => p.IdProveedor == idProveedor);

            if (proveedor == null) return false;

            proveedor.Nombre = dto.Nombre;
            proveedor.ApellidoPaterno = dto.ApellidoPaterno;
            proveedor.ApellidoMaterno = dto.ApellidoMaterno;
            proveedor.Correo = dto.Correo;
            proveedor.Telefono = dto.Telefono;
            proveedor.Direccion = dto.Direccion;
            proveedor.Descripcion = dto.Descripcion;
            proveedor.Banco = dto.Banco;
            proveedor.ClabeInterbancaria = dto.ClabeInterbancaria;
            proveedor.TitularCuenta = dto.TitularCuenta;

            _context.ProveedorCategoria.RemoveRange(proveedor.ProveedorCategoria);

            if (dto.CategoriasIds != null && dto.CategoriasIds.Any())
            {
                foreach (var idCategoria in dto.CategoriasIds)
                {
                    proveedor.ProveedorCategoria.Add(new ProveedorCategorium
                    {
                        IdProveedor = idProveedor,
                        IdCategoria = idCategoria
                    });
                }
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<IEnumerable<object>> ObtenerProveedoresConEstadoAsync()
        {
            var hoy = DateOnly.FromDateTime(DateTime.Today);

            var proveedores = await _context.Proveedors
                .Include(p => p.ProveedorCategoria)
                    .ThenInclude(pc => pc.IdCategoriaNavigation)
                .Include(p => p.ServicioProveedors)
                    .ThenInclude(sp => sp.EventoProveedors)
                        .ThenInclude(ep => ep.IdEventoNavigation)
                .Select(p => new
                {
                    idProveedor = p.IdProveedor,
                    nombreCompleto = $"{p.Nombre} {p.ApellidoPaterno} {p.ApellidoMaterno}".Trim(),
                    correo = p.Correo,
                    telefono = p.Telefono,
                    activo = p.Activo,
                    fotoProveedorUrl = p.FotoProveedorUrl,
                    categorias = string.Join(", ", p.ProveedorCategoria.Select(pc => pc.IdCategoriaNavigation.Nombre)),
                    estaOcupadoHoy = p.ServicioProveedors
                        .SelectMany(sp => sp.EventoProveedors)
                        .Any(ep => ep.IdEventoNavigation != null &&
                                   ep.IdEventoNavigation.FechaEvento == hoy &&
                                   ep.IdEventoNavigation.Estado != "Cancelado")
                })
                .ToListAsync();

            return proveedores;
        }
    }
}