using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{
    public interface ICategoriaService
    {
        Task<IEnumerable<CategoriaProveedor>> ObtenerCategoriasActivasAsync();
    }
}