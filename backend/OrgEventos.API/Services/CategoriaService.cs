using Microsoft.EntityFrameworkCore;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public class CategoriaService : ICategoriaService
    {
        private readonly GestionEventosContext _context;

        public CategoriaService(GestionEventosContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<CategoriaProveedor>> ObtenerCategoriasActivasAsync()
        {
            // Traemos todas las categorías (aquí asumo que tu tabla se llama CategoriaProveedors por el scaffolding)
            return await _context.CategoriaProveedors.ToListAsync();
        }
    }
}