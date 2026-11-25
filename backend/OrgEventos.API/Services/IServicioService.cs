using OrgEventos.API.DTOs;

namespace OrgEventos.API.Services
{
    public interface IServicioService
    {
        Task<IEnumerable<ServicioListadoDTO>> ObtenerServiciosAsync();
        Task<ServicioListadoDTO?> ObtenerServicioPorIdAsync(int idServicio);
        Task<bool> AgregarServicioAsync(ServicioRegistroDTO dto);
        Task<bool> ActualizarServicioAsync(int idServicio, ServicioRegistroDTO dto);
        Task<bool> CambiarEstadoServicioAsync(int idServicio, bool activo);
    }
}