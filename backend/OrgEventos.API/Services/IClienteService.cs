using OrgEventos.API.DTOs;

namespace OrgEventos.API.Services
{
    public interface IClienteService
    {
        Task<bool> RegistrarClienteAsync(ClienteRegistroDTO dto);
        Task<IEnumerable<ClienteListadoDTO>> ObtenerClientesAsync();
        Task<IEnumerable<object>> ObtenerClientesParaSelectAsync(); // 👈 ¡Agregamos esta línea aquí!
        Task<bool> CambiarEstadoClienteAsync(int idCliente, bool activo);
        Task<bool> ActualizarClienteAsync(int idCliente, ClienteActualizacionDTO dto);
        Task<ClienteActualizacionDTO?> ObtenerClientePorIdAsync(int idCliente);
    }
}