using OrgEventos.API.DTOs;

namespace OrgEventos.API.Services
{
    public interface IProveedorService
    {
        Task<bool> RegistrarProveedorAsync(ProveedorRegistroDTO dto);
        Task<IEnumerable<ProveedorListadoDTO>> ObtenerProveedoresAsync();
        Task<bool> CambiarEstadoProveedorAsync(int idProveedor, bool activo);
        Task<ProveedorRegistroDTO?> ObtenerProveedorPorIdAsync(int idProveedor);
        Task<bool> ActualizarProveedorAsync(int idProveedor, ProveedorRegistroDTO dto);
        Task<IEnumerable<object>> ObtenerProveedoresConEstadoAsync();
    }
}