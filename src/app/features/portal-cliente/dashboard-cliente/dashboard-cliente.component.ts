import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../../core/services/auth.service';
import { FinanzasService } from '../../../core/services/finanzas.service';
import { ToastrService } from 'ngx-toastr';
import { loadStripe, Stripe, StripeElements, StripeCardElement } from '@stripe/stripe-js';
import { environment } from '../../../../environments/environment';
import { ContratoPdfService } from '../../../core/services/contrato-pdf.service.service';
import { TicketPdfService } from '../../../core/services/ticket-pdf.service.service';
 // 👈 Importamos el servicio de tickets

@Component({
  selector: 'app-dashboard-cliente',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dashboard-cliente.component.html'
})
export class DashboardClienteComponent implements OnInit {
  private router = inject(Router);
  private authService = inject(AuthService);
  private finanzasService = inject(FinanzasService);
  private toastr = inject(ToastrService);
  private http = inject(HttpClient);

  // 🚀 Inyección de servicios compartidos
  private contratoPdfService = inject(ContratoPdfService);
  private ticketPdfService = inject(TicketPdfService); 

  nombreUsuario: string = '';
  cargando: boolean = true;
  sinContrato: boolean = false;

  // Lista global de eventos del cliente
  misEventos: any[] = [];
  idEventoSeleccionado: number = 0;
  eventoActivo: any = null;

  // Stripe
  stripe: Stripe | null = null;
  elements: StripeElements | null = null;
  cardElement: StripeCardElement | null = null;
  cargandoStripe: boolean = false;
  procesandoPago: boolean = false;
  clientSecretStripe: string = '';

  clientSecretSetup: string = '';
  cardElementUpdate: StripeCardElement | null = null;

  // Checkbox de consentimiento para guardar tarjeta
  autorizaGuardarTarjeta: boolean = false;

  cuotaPendienteActual: any = null;

  // Estados del Stepper (Estado del Servicio)
  tienePagosRealizados: boolean = false;
  eventoLiquidado: boolean = false;
  esDiaDelEvento: boolean = false;

  alertaPago = {
    mostrar: false,
    tipo: '',
    mensaje: '',
    monto: 0
  };

  cuentaAgencia = {
    banco: 'BBVA México',
    clabe: '0121 8000 4829 3019 42',
    titular: 'OrgEventos S.A. de C.V.'
  };

  ngOnInit(): void {
    this.nombreUsuario = this.authService.obtenerNombreUsuario();
    this.inicializarStripe();
    this.cargarEventosCliente();
  }

  async inicializarStripe() {
    this.stripe = await loadStripe(environment.stripePublicKey);
  }

  cargarEventosCliente() {
    this.cargando = true;
    const idContratoAnterior = this.idEventoSeleccionado;

    this.finanzasService.obtenerMisEventosCliente().subscribe({
      next: (eventos) => {
        if (!eventos || eventos.length === 0) {
          this.sinContrato = true;
          this.cargando = false;
          return;
        }

        this.misEventos = eventos;
        const existeAnterior = eventos.some(e => e.idContrato === idContratoAnterior);

        if (existeAnterior) {
          this.idEventoSeleccionado = idContratoAnterior;
        } else {
          this.idEventoSeleccionado = eventos[0].idContrato;
        }

        this.seleccionarEvento(this.idEventoSeleccionado);
        this.cargando = false;
      },
      error: (err) => {
        console.error('Error al cargar eventos del cliente:', err);
        this.sinContrato = true;
        this.cargando = false;
      }
    });
  }

  seleccionarEvento(idContrato: number) {
    this.eventoActivo = this.misEventos.find(e => e.idContrato === Number(idContrato));
    if (!this.eventoActivo) return;

    const hoy = new Date();
    const fechaEv = new Date(this.eventoActivo.fechaEvento);
    const diffMs = fechaEv.getTime() - hoy.getTime();
    this.eventoActivo.diasRestantes = Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));

    const cuotas = this.eventoActivo.cuotas || [];
    this.cuotaPendienteActual = cuotas.find((c: any) => c.estado === 'Pendiente');

    if (this.cuotaPendienteActual) {
      this.evaluarAlertaPago(this.cuotaPendienteActual);
    } else {
      this.alertaPago.mostrar = false;
    }

    this.calcularEstadoServicio();
  }

  calcularEstadoServicio() {
    if (!this.eventoActivo) return;

    const cuotas = this.eventoActivo.cuotas || [];
    const cuotasPagadas = cuotas.filter((c: any) => c.estado === 'Pagada');

    this.tienePagosRealizados = cuotasPagadas.length > 0;
    this.eventoLiquidado = cuotas.length > 0 && cuotasPagadas.length === cuotas.length;

    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    
    const fechaEventoObj = new Date(this.eventoActivo.fechaEvento);
    fechaEventoObj.setHours(0, 0, 0, 0);

    this.esDiaDelEvento = hoy >= fechaEventoObj;
  }

  evaluarAlertaPago(cuota: any) {
    const hoy = new Date();
    const fechaLimite = new Date(cuota.fechaLimite);
    
    hoy.setHours(0, 0, 0, 0);
    fechaLimite.setHours(0, 0, 0, 0);

    const diffDias = Math.ceil((fechaLimite.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24));

    this.alertaPago.mostrar = true;
    this.alertaPago.monto = cuota.saldoRestante;

    if (diffDias < 0) {
      this.alertaPago.tipo = 'error';
      this.alertaPago.mensaje = `Tu pago de la Cuota #${cuota.numeroCuota} está vencido.`;
    } else if (diffDias === 0) {
      this.alertaPago.tipo = 'warning';
      this.alertaPago.mensaje = `Tu pago de la Cuota #${cuota.numeroCuota} vence HOY.`;
    } else if (diffDias <= 7) {
      this.alertaPago.tipo = 'info';
      this.alertaPago.mensaje = `Tu próximo pago (Cuota #${cuota.numeroCuota}) vence en ${diffDias} días.`;
    } else {
      this.alertaPago.mostrar = false;
    }
  }

  abrirModalStripe() {
    if (!this.cuotaPendienteActual) return;

    const modal = document.getElementById('modal_pago_stripe_cliente') as HTMLDialogElement;
    if (modal) modal.showModal();

    this.cargandoStripe = true;
    this.finanzasService.crearIntentPago(this.cuotaPendienteActual.saldoRestante).subscribe({
      next: async (res) => {
        this.clientSecretStripe = res.clientSecret;
        if (this.stripe) {
          this.elements = this.stripe.elements();
          this.destruirCardStripe();

          this.cardElement = this.elements.create('card', {
            style: {
              base: { fontSize: '16px', color: '#1f2937' }
            }
          });

          setTimeout(() => {
            this.cardElement?.mount('#card-element-cliente');
            this.cargandoStripe = false;
          }, 150);
        }
      },
      error: () => {
        this.cargandoStripe = false;
        this.toastr.error('No se pudo conectar con la pasarela de cobro.', 'Error');
      }
    });
  }

  destruirCardStripe() {
    if (this.cardElement) {
      this.cardElement.unmount();
      this.cardElement.destroy();
      this.cardElement = null;
    }
  }

  cerrarModalStripe() {
    this.destruirCardStripe();
    const modal = document.getElementById('modal_pago_stripe_cliente') as HTMLDialogElement;
    if (modal) modal.close();
  }

  async procesarPagoTarjeta() {
    if (!this.stripe || !this.cardElement || !this.clientSecretStripe || !this.cuotaPendienteActual) return;

    this.procesandoPago = true;
    const resultado = await this.stripe.confirmCardPayment(this.clientSecretStripe, {
      payment_method: { card: this.cardElement }
    });

    if (resultado.error) {
      this.toastr.error(resultado.error.message || 'Pago rechazado.', 'Error');
      this.procesandoPago = false;
      return;
    }

    if (resultado.paymentIntent?.status === 'succeeded') {
      const payload = {
        idCuota: this.cuotaPendienteActual.idCuota,
        montoPagado: this.cuotaPendienteActual.saldoRestante,
        metodoPago: 'Tarjeta',
        fechaPago: new Date().toISOString()
      };

      this.finanzasService.registrarPagoCliente(payload).subscribe({
        next: () => {
          this.procesandoPago = false;
          this.cerrarModalStripe();
          this.toastr.success('¡Tu abono fue recibido con éxito!', 'Pago Confirmado');
          
          // ---> 🚀 USANDO EL SERVICIO EXCLUSIVO DE TICKETS <---
          try {
            this.ticketPdfService.generarTicket({
              idCuota: this.cuotaPendienteActual.idCuota,
              montoPagado: payload.montoPagado,
              metodoPago: payload.metodoPago,
              fechaPago: new Date().toISOString().split('T')[0]
            });
            this.toastr.success('El comprobante se ha descargado exitosamente.', 'PDF Generado');
          } catch (e) {
            console.error("Error al generar PDF del cliente", e);
          }

          this.cargarEventosCliente();
        },
        error: (err) => {
          this.procesandoPago = false;
          this.toastr.error(err.error?.mensaje || 'Error al guardar el abono.', 'Error');
        }
      });
    }
  }

  // 📄 MÉTODO PARA DESCARGAR EL CONTRATO OFICIAL USANDO EL SERVICIO COMPARTIDO
  abrirModalContrato() {
    if (!this.eventoActivo || !this.eventoActivo.idContrato) {
      this.toastr.warning('No hay un contrato asociado seleccionado.', 'Aviso');
      return;
    }

    this.toastr.info('Generando contrato en PDF...', 'Espere');

    this.http.get<any>(`${environment.apiUrl}/api/contratos/${this.eventoActivo.idContrato}`).subscribe({
      next: (contratoDetalle) => {
        // 🚀 Llamada limpia y centralizada al servicio compartido
        this.contratoPdfService.generarPdfContrato(contratoDetalle);
        this.toastr.success('El contrato se ha descargado exitosamente.', 'PDF Generado');
      },
      error: (err) => {
        console.error('Error al obtener detalles del contrato:', err);
        this.toastr.error('No se pudo descargar la información del contrato.', 'Error');
      }
    });
  }

  cerrarModalContrato() {
    const modal = document.getElementById('modal_contrato') as HTMLDialogElement;
    if (modal) modal.close();
  }

  abrirModalTransferencia() {
    const modal = document.getElementById('modal_transferencia_agencia') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalTransferencia() {
    const modal = document.getElementById('modal_transferencia_agencia') as HTMLDialogElement;
    if (modal) modal.close();
  }

  abrirModalActualizarTarjeta() {
    const modal = document.getElementById('modal_actualizar_tarjeta') as HTMLDialogElement;
    if (modal) modal.showModal();

    this.cargandoStripe = true;
    this.finanzasService.crearSetupIntent().subscribe({
      next: async (res) => {
        this.clientSecretSetup = res.clientSecret;
        if (this.stripe) {
          this.elements = this.stripe.elements();
          
          if (this.cardElementUpdate) {
            this.cardElementUpdate.unmount();
            this.cardElementUpdate.destroy();
          }

          this.cardElementUpdate = this.elements.create('card', {
            style: {
              base: { fontSize: '16px', color: '#1f2937' }
            }
          });

          setTimeout(() => {
            this.cardElementUpdate?.mount('#card-element-actualizar');
            this.cargandoStripe = false;
          }, 150);
        }
      },
      error: () => {
        this.cargandoStripe = false;
        this.toastr.error('No se pudo inicializar la pasarela de actualización.', 'Error');
      }
    });
  }

  cerrarModalActualizarTarjeta() {
    if (this.cardElementUpdate) {
      this.cardElementUpdate.unmount();
      this.cardElementUpdate.destroy();
      this.cardElementUpdate = null;
    }
    const modal = document.getElementById('modal_actualizar_tarjeta') as HTMLDialogElement;
    if (modal) modal.close();
  }

  async guardarNuevaTarjeta() {
    if (!this.stripe || !this.cardElementUpdate || !this.clientSecretSetup) return;

    this.procesandoPago = true;

    const resultado = await this.stripe.confirmCardSetup(this.clientSecretSetup, {
      payment_method: { card: this.cardElementUpdate }
    });

    if (resultado.error) {
      this.toastr.error(resultado.error.message || 'La tarjeta fue rechazada.', 'Error de Tarjeta');
      this.procesandoPago = false;
      return;
    }

    if (resultado.setupIntent?.status === 'succeeded') {
      this.toastr.success('¡Tu tarjeta ha sido actualizada exitosamente!', 'Tarjeta Guardada');
      this.procesandoPago = false;
      this.cerrarModalActualizarTarjeta();
    }
  }

  abrirModalHistorial() {
    const modal = document.getElementById('modal_historial_cuotas') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalHistorial() {
    const modal = document.getElementById('modal_historial_cuotas') as HTMLDialogElement;
    if (modal) modal.close();
  }

  cerrarSesion() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }
}