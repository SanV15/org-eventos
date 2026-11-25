//namespace OrgEventos.API.DTOs.Finanzas
//{
//    public class ContratoDetalleDTO
//    {
//        public int IdContrato { get; set; }
//        public DateTime FechaContrato { get; set; }
//        public decimal MontoAcordado { get; set; }
//        public string EstadoContrato { get; set; } = null!;

//        // Datos del Evento
//        public string NombreEvento { get; set; } = null!;
//        public DateOnly FechaEvento { get; set; }
//        public string Lugar { get; set; } = null!;
//        public int NumeroInvitados { get; set; }

//        // Datos del Cliente
//        public string NombreCliente { get; set; } = null!;
//        public string CorreoCliente { get; set; } = null!;
//        public string TelefonoCliente { get; set; } = null!;
//        public string DireccionCliente { get; set; } = null!;

//        // Listas desglosadas
//        public List<ServicioContratadoDTO> Servicios { get; set; } = new();
//        public List<CuotaContratoDTO> Cuotas { get; set; } = new();
//    }

//    public class ServicioContratadoDTO
//    {
//        public string Nombre { get; set; } = null!;
//        public int Cantidad { get; set; }
//        public decimal Precio { get; set; }
//        public decimal Subtotal { get; set; }
//        public string Tipo { get; set; } = null!; // "Interno" o "Externo"
//    }

//    public class CuotaContratoDTO
//    {
//        public int NumeroCuota { get; set; }
//        public DateOnly FechaLimite { get; set; }
//        public decimal Monto { get; set; }
//        public string Estado { get; set; } = null!;
//    }
//}
using OrgEventos.API.Models;

namespace OrgEventos.API.DTOs.Finanzas
{
    public class ContratoDetalleDTO
    {
        public int IdContrato { get; set; }
        public DateTime FechaContrato { get; set; }
        public decimal MontoAcordado { get; set; }
        public string EstadoContrato { get; set; } = null!;

        // Datos del Evento
        public string NombreEvento { get; set; } = null!;
        public DateOnly FechaEvento { get; set; }
        public string Lugar { get; set; } = null!;
        public int NumeroInvitados { get; set; }

        // Datos del Cliente
        public string NombreCliente { get; set; } = null!;
        public string CorreoCliente { get; set; } = null!;
        public string TelefonoCliente { get; set; } = null!;
        public string DireccionCliente { get; set; } = null!;

        // Listas desglosadas
        public List<ServicioContratadoDTO> Servicios { get; set; } = new();
        public List<CuotaContratoDTO> Cuotas { get; set; } = new();

        // 💡 Método estático para encapsular todo el mapeo relacional de la entidad
        public static ContratoDetalleDTO MapearDesde(Contrato contrato)
        {
            var ev = contrato.IdEventoNavigation;
            var cli = ev?.IdClienteNavigation;
            var cot = ev?.IdCotizacionNavigation;
            var planPago = contrato.PlanPago;

            var dto = new ContratoDetalleDTO
            {
                IdContrato = contrato.IdContrato,
                FechaContrato = contrato.FechaContrato,
                MontoAcordado = contrato.MontoAcordado,
                EstadoContrato = contrato.Estado,
                NombreEvento = ev?.Nombre ?? "Sin evento",
                FechaEvento = ev?.FechaEvento ?? DateOnly.FromDateTime(DateTime.Now),
                Lugar = ev?.Lugar ?? "Sin lugar",
                NumeroInvitados = ev?.NumeroInvitados ?? 0,
                NombreCliente = cli != null ? $"{cli.Nombre} {cli.ApellidoPaterno} {cli.ApellidoMaterno}".Trim() : "Sin cliente",
                CorreoCliente = cli?.Correo ?? "Sin correo",
                TelefonoCliente = cli?.Telefono ?? "Sin teléfono",
                DireccionCliente = cli?.Direccion ?? "Sin dirección",
                Servicios = new List<ServicioContratadoDTO>()
            };

            // Mapear servicios internos
            if (cot?.CotizacionDetalles != null)
            {
                foreach (var det in cot.CotizacionDetalles)
                {
                    dto.Servicios.Add(new ServicioContratadoDTO
                    {
                        Nombre = det.IdServicioNavigation?.Nombre ?? "Servicio Interno",
                        Cantidad = det.Cantidad,
                        Precio = det.PrecioUnitario,
                        Subtotal = det.Cantidad * det.PrecioUnitario,
                        Tipo = "Interno"
                    });
                }
            }

            // Mapear servicios externos (proveedores)
            if (cot?.CotizacionProveedors != null)
            {
                foreach (var prov in cot.CotizacionProveedors)
                {
                    dto.Servicios.Add(new ServicioContratadoDTO
                    {
                        Nombre = prov.IdServicioProveedorNavigation?.NombreServicio ?? "Servicio Externo",
                        Cantidad = prov.Cantidad,
                        Precio = prov.PrecioCotizado,
                        Subtotal = prov.Cantidad * prov.PrecioCotizado,
                        Tipo = "Externo"
                    });
                }
            }

            // Mapear cuotas del plan de pago
            if (planPago?.Cuota != null)
            {
                dto.Cuotas = planPago.Cuota.Select(cu => new CuotaContratoDTO
                {
                    NumeroCuota = cu.NumeroCuota,
                    FechaLimite = cu.FechaLimite,
                    Monto = cu.Monto,
                    Estado = cu.Estado
                }).OrderBy(cu => cu.NumeroCuota).ToList();
            }

            return dto;
        }
    }

    public class ServicioContratadoDTO
    {
        public string Nombre { get; set; } = null!;
        public int Cantidad { get; set; }
        public decimal Precio { get; set; }
        public decimal Subtotal { get; set; }
        public string Tipo { get; set; } = null!; // "Interno" o "Externo"
    }

    public class CuotaContratoDTO
    {
        public int NumeroCuota { get; set; }
        public DateOnly FechaLimite { get; set; }
        public decimal Monto { get; set; }
        public string Estado { get; set; } = null!;
    }
}