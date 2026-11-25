namespace OrgEventos.API.DTOs.Finanzas
{
    // 1. Para los KPIs superiores (El dinero real)
    public class ResumenFinancieroDTO
    {
        public decimal TotalEnCaja { get; set; }
        public decimal CuentasPorCobrar { get; set; }
        public decimal EgresosTotales { get; set; }
        public decimal MargenBruto => TotalEnCaja - EgresosTotales; // Utilidad calculada
    }

    // 2. Para la Pestaña 1: Flujo de Caja (Libro Mayor)
    public class TransaccionDTO
    {
        public DateTime Fecha { get; set; }
        public string Tipo { get; set; } // "Ingreso" o "Egreso"
        public string Entidad { get; set; } // Nombre del Cliente o Proveedor
        public string Concepto { get; set; } // Ej. "Abono Cuota 1 - Boda Santiago"
        public decimal Monto { get; set; }
    }

    // 3. Para la Pestaña 2: Cobranza Activa
    public class CobranzaActivaDTO
    {
        public int IdContrato { get; set; }
        public int IdCliente { get; set; }
        public string Cliente { get; set; }
        public string NombreEvento { get; set; }
        public decimal TotalContrato { get; set; }
        public decimal SaldoPendiente { get; set; }
        public DateTime? ProximoVencimiento { get; set; }
        public string EstadoMorosidad { get; set; } // "Al día", "Atrasado" o "Vence hoy"
    }
}
