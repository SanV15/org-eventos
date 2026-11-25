namespace OrgEventos.API.DTOs.Finanzas
{
    public class PagoProveedorPendienteDTO
    {
        public int IdEventoProveedor { get; set; }
        public string Proveedor { get; set; } = null!;
        public string Servicio { get; set; } = null!;
        public string Evento { get; set; } = null!;
        public decimal CostoAcordado { get; set; }
        public decimal MontoPagado { get; set; }
        public decimal SaldoPendiente { get; set; }
        public string Estado { get; set; } = null!;

        // --- AÑADE ESTOS TRES CAMPOS BANCARIOS ---
        public string? Banco { get; set; }
        public string? ClabeInterbancaria { get; set; }
        public string? TitularCuenta { get; set; }
        // ----------------------------------------
    }
}