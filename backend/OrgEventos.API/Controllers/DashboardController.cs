using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrgEventos.API.Models;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly GestionEventosContext _context;

        public DashboardController(GestionEventosContext context)
        {
            _context = context;
        }

        [HttpGet("resumen")]
        public async Task<IActionResult> ObtenerResumenDashboard()
        {
            var hoy = DateOnly.FromDateTime(DateTime.Today);
            var primerDiaMes = new DateOnly(hoy.Year, hoy.Month, 1);
            var ultimoDiaMes = primerDiaMes.AddMonths(1).AddDays(-1);

            int eventosActivos = await _context.Eventos
                .CountAsync(e => e.Estado == "En planificación" || e.Estado == "Activo" || e.Estado == "Pendiente");

            int eventosEsteMes = await _context.Eventos
                .CountAsync(e => e.FechaEvento >= primerDiaMes && e.FechaEvento <= ultimoDiaMes);

            int tareasPendientes = await _context.Set<Tarea>()
                .CountAsync(t => t.Estado == "Pendiente");

            int cotizacionesPendientes = await _context.Cotizacions
                .CountAsync(c => c.Estado == "Pendiente");

            var proximosEventos = await _context.Eventos
                            .Include(e => e.IdClienteNavigation)
                            .Where(e => e.FechaEvento >= hoy)
                            .OrderBy(e => e.FechaEvento)
                            .Take(5)
                            .Select(e => new {
                                idEvento = e.IdEvento,
                                idCliente = e.IdCliente, // 👈 Si marca error aquí, cámbialo por e.Id_Cliente según tu modelo de EF
                                nombreEvento = e.Nombre,
                                fechaEvento = e.FechaEvento,
                                lugar = e.Lugar,
                                estado = e.Estado
                            })
                            .ToListAsync();

            return Ok(new
            {
                eventosActivos,
                eventosEsteMes,
                tareasPendientes,
                cotizacionesPendientes,
                proximosEventos
            });
        }
    }
}
