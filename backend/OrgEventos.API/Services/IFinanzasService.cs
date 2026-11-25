using OrgEventos.API.DTOs.Finanzas;

namespace OrgEventos.API.Services
{
    public interface IFinanzasService
    {
            Task<bool> RegistrarPagoClienteAsync(RegistrarPagoClienteDTO dto);
            Task<bool> RegistrarPagoProveedorAsync(RegistrarPagoProveedorDTO dto);

            Task<EstadoCuentaDTO?> ObtenerEstadoCuentaAsync(int idContrato);
            Task<EstadoCuentaDTO?> ObtenerEstadoCuentaPorClienteAsync(int idCliente);
        Task<IEnumerable<ContratoListadoDTO>> ObtenerTodosLosContratosAsync();
    }
}
