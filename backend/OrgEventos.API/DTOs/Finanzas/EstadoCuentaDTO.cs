using System;
using System.Collections.Generic;

namespace OrgEventos.API.DTOs.Finanzas
{
    public class EstadoCuentaDTO
    {
        public int IdContrato { get; set; }
        public int IdEvento { get; set; }
        public string NombreCliente { get; set; } = null!;
        public decimal TotalContrato { get; set; }
        public decimal MontoAbonado { get; set; }
        public decimal SaldoRestante { get; set; }
        public string EstadoContrato { get; set; } = null!;
        public List<CuotaDetalleDTO> Cuotas { get; set; } = new();
    }

    public class CuotaDetalleDTO
    {
        public int IdCuota { get; set; }
        public int NumeroCuota { get; set; }
        public DateOnly FechaLimite { get; set; }
        public decimal MontoTotal { get; set; }
        public decimal MontoAbonado { get; set; }
        public decimal SaldoRestante { get; set; }
        public string Estado { get; set; } = null!;
    }
}