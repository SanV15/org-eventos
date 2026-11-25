using System;

namespace OrgEventos.API.DTOs.Finanzas
{
    public class ContratoListadoDTO
    {
        public int IdContrato { get; set; }
        public int IdCliente { get; set; } // Lo necesitamos para el botón "Ver Finanzas"
        public string Cliente { get; set; } = null!;
        public string Evento { get; set; } = null!;
        public DateTime FechaContrato { get; set; }
        public decimal MontoTotal { get; set; }
        public decimal MontoAbonado { get; set; }
        public decimal SaldoRestante { get; set; }
        public string Estado { get; set; } = null!;
    }
}