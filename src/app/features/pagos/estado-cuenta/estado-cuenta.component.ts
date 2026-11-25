import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { FinanzasService, RegistrarPagoCliente } from '../../../core/services/finanzas.service';
import { AuthService } from '../../../core/services/auth.service';
import { ToastrService } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';// 👈 Servicio de Contratos
import { TicketPdfService } from '../../../core/services/ticket-pdf.service.service';
import { ContratoPdfService } from '../../../core/services/contrato-pdf.service.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-estado-cuenta',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './estado-cuenta.component.html'
})
export class EstadoCuentaComponent implements OnInit {
  private finanzasService = inject(FinanzasService);
  private authService = inject(AuthService);
  private route = inject(ActivatedRoute);
  private toastr = inject(ToastrService);
  private http = inject(HttpClient);
  private ticketPdfService = inject(TicketPdfService);       // 👈 Inyección
  private contratoPdfService = inject(ContratoPdfService);   // 👈 Inyección

  cargando: boolean = true;
  procesandoPago: boolean = false;
  saldoRestanteModal: number = 0;

  sinContrato: boolean = false;
  errorMensaje: string | null = null;

  contratoDetalle: any = null;
  
  rolUsuario: string = '';
  idClienteActual: number = 0;

  resumen: any = {
    total: 0,
    pagado: 0,
    restante: 0,
    estadoContrato: 'Cargando...',
    nombreCliente: ''
  };

  cuotas: any[] = [];

  datosPago: RegistrarPagoCliente = {
    idCuota: 0,
    montoPagado: 0,
    metodoPago: 'Efectivo',
    fechaPago: new Date().toISOString().split('T')[0]
  };

  ngOnInit(): void {
    this.rolUsuario = this.authService.obtenerRol() || '';
    const idUrl = this.route.snapshot.paramMap.get('id');
    
    if (idUrl && idUrl !== 'undefined' && idUrl !== 'null') {
      const parsedId = parseInt(idUrl, 10);
      if (!isNaN(parsedId)) {
        this.idClienteActual = parsedId;
        this.cargarDatosFinancieros();
      }
    }
  }

  cargarDatosFinancieros() {
    this.cargando = true;
    this.sinContrato = false; 
    this.errorMensaje = null;

    this.finanzasService.obtenerEstadoCuentaPorCliente(this.idClienteActual).subscribe({
      next: (data) => {
        this.resumen = {
          total: data.totalContrato ?? 0,
          pagado: data.montoAbonado ?? 0,
          restante: data.saldoRestante ?? 0,
          estadoContrato: data.estadoContrato,
          nombreCliente: data.nombreCliente
        };
        this.cuotas = data.cuotas ?? [];
        this.cargando = false;
      },
      error: (err) => {
        console.error('Error al cargar datos financieros:', err);
        this.cargando = false;

        if (err.status === 404) {
          this.sinContrato = true;
        } else {
          this.errorMensaje = 'No fue posible cargar la cuenta del cliente. Verifica la conexión con el servidor e inténtalo de nuevo.';
        }
      }
    });
  }

  abrirModalPago(cuota: any) {
    this.datosPago.idCuota = cuota.idCuota;
    this.saldoRestanteModal = cuota.saldoRestante; 
    this.datosPago.montoPagado = this.saldoRestanteModal; 
    this.datosPago.metodoPago = 'Efectivo';
    
    const modal = document.getElementById('modal_pago_cliente') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalPago() {
    const modal = document.getElementById('modal_pago_cliente') as HTMLDialogElement;
    if (modal) modal.close();
  }

  async confirmarPago() {
    if (this.datosPago.montoPagado <= 0) return;
    this.procesandoPago = true;

    const payload = {
      ...this.datosPago,
      fechaPago: new Date(this.datosPago.fechaPago + 'T00:00:00').toISOString() 
    };

    this.finanzasService.registrarPagoCliente(payload).subscribe({
      next: (res) => {
        this.procesandoPago = false;
        this.cerrarModalPago();
        this.toastr.success('El abono se ha contabilizado en caja.', '¡Pago Registrado!');

        setTimeout(() => {
          try {
            // 🚀 Generación de ticket usando el servicio exclusivo
            this.ticketPdfService.generarTicket(this.datosPago);
            this.toastr.success('El ticket se ha descargado exitosamente.', 'PDF Generado');
          } catch (e) {
            console.error("Error al generar PDF", e);
          }
        }, 500);
        
        this.cargarDatosFinancieros(); 
      },
      error: (err) => {
        console.error('Error al registrar el abono:', err);
        this.procesandoPago = false;
        const mensajeError = err.error?.mensaje || err.error?.error || 'Ocurrió un problema al procesar el abono.';
        this.toastr.error(mensajeError, 'Error de cobro');
      }
    });
  }

  descargarContratoPDF() {
    this.http.get<any>(`https://localhost:7106/api/contratos/cliente/${this.idClienteActual}`).subscribe({
      next: (res: any) => {
        this.contratoDetalle = res;
        // 🚀 Generación de contrato usando el servicio compartido
        this.contratoPdfService.generarPdfContrato(this.contratoDetalle);
        this.toastr.success('El contrato se ha descargado exitosamente.', 'PDF Generado');
      },
      error: (err: any) => {
        console.error('Error al cargar contrato', err);
        this.toastr.error('No se pudo obtener la información actualizada del contrato.', 'Error');
      }
    });
  }

  imprimirContrato() {
    window.print();
  }
}