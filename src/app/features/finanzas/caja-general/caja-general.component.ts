import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { forkJoin } from 'rxjs';
import { FinanzasService, RegistrarPagoProveedor } from '../../../core/services/finanzas.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-caja-general',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './caja-general.component.html'
})
export class CajaGeneralComponent implements OnInit {
  private finanzasService = inject(FinanzasService);
  private toastr = inject(ToastrService);

  resumen: any = null;
  transacciones: any[] = [];
  cobranza: any[] = [];
  proveedores: any[] = [];

  cargando: boolean = true;
  procesandoPagoProveedor: boolean = false;
  errorMensaje: string | null = null;
  pestanaActiva: string = 'flujo';

  proveedorSeleccionado: any = null;
  idEventoActual: number = 0;

  saldoRestanteProveedor: number = 0;
  datosPagoProveedor: RegistrarPagoProveedor = {
    idEventoProveedor: 0,
    montoPagado: 0,
    metodoPago: 'Transferencia',
    fechaPago: new Date().toISOString().split('T')[0]
  };

  ngOnInit(): void {
    this.cargarDatosFinancieros();
  }

  cargarDatosFinancieros() {
    this.cargando = true;
    this.errorMensaje = null;

    forkJoin({
      resumen: this.finanzasService.obtenerResumenFinanciero(),
      flujo: this.finanzasService.obtenerFlujoCaja(),
      cobro: this.finanzasService.obtenerCobranzaActiva(),
      proveedores: this.finanzasService.obtenerProveedoresPendientes()
    }).subscribe({
      next: (resultados) => {
        this.resumen = resultados.resumen;
        this.transacciones = resultados.flujo;
        this.cobranza = resultados.cobro;
        this.proveedores = resultados.proveedores;
        this.cargando = false;
      },
      error: (err) => {
        this.errorMensaje = err.error?.mensaje || 'Error al cargar los datos financieros.';
        this.cargando = false;
      }
    });
  }

  cambiarPestana(pestana: string) {
    this.pestanaActiva = pestana;
  }

  abrirModalPagoProveedor(item: any) {
    this.proveedorSeleccionado = item;
    this.datosPagoProveedor.idEventoProveedor = item.idEventoProveedor;
    this.saldoRestanteProveedor = item.saldoPendiente;
    this.datosPagoProveedor.montoPagado = item.saldoPendiente;
    this.datosPagoProveedor.metodoPago = 'Transferencia';

    const modal = document.getElementById('modal_pago_proveedor') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalPagoProveedor() {
    const modal = document.getElementById('modal_pago_proveedor') as HTMLDialogElement;
    if (modal) modal.close();
  }

  confirmarPagoProveedor() {
    if (this.datosPagoProveedor.montoPagado <= 0) return;

    this.procesandoPagoProveedor = true;
    const payload = {
      ...this.datosPagoProveedor,
      fechaPago: new Date(this.datosPagoProveedor.fechaPago + 'T00:00:00').toISOString()
    };

    this.finanzasService.registrarPagoProveedor(payload).subscribe({
      next: () => {
        this.procesandoPagoProveedor = false;
        this.cerrarModalPagoProveedor();
        this.toastr.success('El egreso al proveedor ha sido contabilizado.', '¡Pago Registrado!');
        this.cargarDatosFinancieros();
      },
      error: (err) => {
        this.procesandoPagoProveedor = false;
        this.toastr.error(err.error?.mensaje || 'Ocurrió un error al registrar el pago.', 'Error');
      }
    });
  }
}