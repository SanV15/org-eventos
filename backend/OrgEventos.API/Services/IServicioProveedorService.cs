using OrgEventos.API.DTOs;

namespace OrgEventos.API.Services
{
    public interface IServicioProveedorService
    {
        Task<IEnumerable<ServicioProveedorListadoDTO>> ObtenerServiciosPorProveedorAsync(int idProveedor);
        Task<bool> AgregarServicioAsync(int idProveedor, ServicioProveedorRegistroDTO dto);
        Task<bool> ActualizarServicioAsync(int idServicioProveedor, ServicioProveedorRegistroDTO dto);
        // Ojo: usa el nombre del DTO que estés usando para lectura
        Task<IEnumerable<ServicioProveedorListadoDTO>> ObtenerTodosAsync();
        Task<bool> CambiarEstadoServicioAsync(int idServicioProveedor, bool activo);
    }
}