using OrgEventos.API.DTOs.Cotizaciones;

namespace OrgEventos.API.Services
{
    public interface ICotizacionService
    {
        Task<CotizacionResultadoDTO> CrearCotizacionAsync(CrearCotizacionDTO dto); // 👈 Actualizado aquí
        Task<CotizacionLecturaDTO?> ObtenerCotizacionPorIdAsync(int idCotizacion);
        Task<IEnumerable<CotizacionLecturaDTO>> ObtenerCotizacionesAsync();
        Task<bool> AprobarCotizacionYCrearEventoAsync(int idCotizacion, AprobarCotizacionDTO dto);
        Task<IEnumerable<object>> ObtenerTiposEventoAsync();
        Task<bool> RechazarCotizacionAsync(int idCotizacion);
    }
}