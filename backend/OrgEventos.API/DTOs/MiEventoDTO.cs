using System;
using System.Collections.Generic;

namespace OrgEventos.API.DTOs.Finanzas
{
    public class MiEventoDTO
    {
        public int IdContrato { get; set; }
        public int IdEvento { get; set; }
        public string NombreEvento { get; set; } = null!;
        public DateTime FechaEvento { get; set; }
        public string EstadoContrato { get; set; } = null!;
        public decimal TotalContrato { get; set; }
        public decimal MontoAbonado { get; set; }
        public decimal SaldoRestante { get; set; }
        public List<CuotaDTO> Cuotas { get; set; } = new();
    }

    public class CuotaDTO
    {
        public int IdCuota { get; set; }
        public int NumeroCuota { get; set; }
        public DateTime FechaLimite { get; set; }
        public decimal MontoTotal { get; set; }
        public decimal MontoAbonado { get; set; }
        public decimal SaldoRestante { get; set; }
        public string Estado { get; set; } = null!;
    }

    public class MontoRequestDTO
    {
        public decimal Monto { get; set; }
    }
}