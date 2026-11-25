using OrgEventos.API.DTOs;
using OrgEventos.API.DTOs.Tareas;
using OrgEventos.API.Models;
using System.Transactions;

namespace OrgEventos.API.Services
{
    public interface ITareaService
    {
        Task<bool> RegistrarTareaAsync(TareaEventoDTO dto);
    }

    public class TareasService : ITareaService
    {
        private readonly GestionEventosContext _context;

        public TareasService(GestionEventosContext context)
        {
            _context = context;
        }

        public async Task<bool> RegistrarTareaAsync(TareaEventoDTO dto)
        {

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var nuevaTarea = new Tarea
                {
                    Nombre = dto.Nombre,
                    Descripcion = dto.Descripcion,
                    FechaLimite = dto.FechaLimite,
                    Estado = dto.Estado,
                };
                _context.Tareas.Add(nuevaTarea);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                return true;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }


    }
}
