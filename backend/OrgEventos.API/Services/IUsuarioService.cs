using Microsoft.EntityFrameworkCore;
using OrgEventos.API.DTOs;
using OrgEventos.API.Models;

namespace OrgEventos.API.Services
{ 
    public interface IUsuariosService
    {
        Task<IEnumerable<RolDto>> ObtenerRolesAsync();
        Task<(bool Exito, string Mensaje, UsuarioResponseDto? Usuario)> CrearUsuarioAsync(CrearUsuarioRequest request);
        Task<IEnumerable<UsuarioResponseDto>> ObtenerUsuariosAsync();
        Task<(bool Exito, string Mensaje)> CambiarEstadoUsuarioAsync(int idUsuario, bool activo);
        Task<(bool Exito, string Mensaje)> CambiarContraseniaUsuarioAsync(int idUsuario, string nuevaContrasenia);
    }
}