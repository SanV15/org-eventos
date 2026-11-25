using System;

namespace OrgEventos.API.DTOs.Finanzas
{
    public class RegistrarPagoClienteDTO
    {
        public int IdCuota { get; set; }
        public decimal MontoPagado { get; set; }
        public string MetodoPago { get; set; } = null!;
        public DateTime FechaPago { get; set; }
    }
}