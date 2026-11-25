using Microsoft.AspNetCore.SignalR;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace OrgEventos.API.Hubs
{
    public class EventosHub : Hub
    {
        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                      ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"Usuario_{userId}");
            }

            await base.OnConnectedAsync();
        }

        // Respaldo para unir al usuario explícitamente desde Flutter si no usa auth en el handshake
        public async Task UnirseAUsuario(int idUsuario)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Usuario_{idUsuario}");
        }

        // Unirse a la sala de un evento específico
        public async Task UnirseAEvento(int idEvento)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Evento_{idEvento}");
        }

        // Salir de la sala cuando se cambia de pantalla
        public async Task SalirDeEvento(int idEvento)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Evento_{idEvento}");
        }

        //DESCOMENTAR ESTO CUANDO LA APLICACION SE DESPLIEGUE EL MÉTODO DE ABAJO SOLO ES DE PRUEBA
        //public async Task EnviarNotaVoz(int idEvento, string audioUrl, string emisorNombre)
        //{
        //    await Clients.OthersInGroup($"Evento_{idEvento}").SendAsync("NotaVozRecibida", new
        //    {
        //        idEvento = idEvento,
        //        audioUrl = audioUrl,
        //        emisorNombre = emisorNombre,
        //        fechaEnvio = DateTime.UtcNow
        //    });
        //}

        public async Task EnviarNotaVoz(int idEvento, string audioUrl, string emisorNombre)
        {
            await Clients.All.SendAsync("NotaVozRecibida", new
            {
                idEvento = idEvento,
                audioUrl = audioUrl,
                emisorNombre = emisorNombre,
                fechaEnvio = DateTime.UtcNow
            });
        }
    }
}
