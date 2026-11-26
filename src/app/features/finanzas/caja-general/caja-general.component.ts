import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { catchError, forkJoin, of } from 'rxjs';
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
  pestanaActiva: string = 'flujo';

  // Errores individuales por bloque para no bloquear toda la vista
  errores: {
    resumen: string | null;
    flujo: string | null;
    cobranza: string | null;
    proveedores: string | null;
  } = {
    resumen: null,
    flujo: null,
    cobranza: null,
    proveedores: null
  };

  // Filtros de Flujo de Caja
  filtroTipo: 'Todos' | 'Ingreso' | 'Egreso' = 'Todos';
  filtroTexto: string = '';
  fechaDesde: string = '';
  fechaHasta: string = '';

  proveedorSeleccionado: any = null;
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

  get saldoNeto(): number {
    if (!this.resumen) return 0;
    if (typeof this.resumen.margenBruto === 'number') {
      return this.resumen.margenBruto;
    }
    const ingresos = Number(this.resumen.totalEnCaja ?? 0);
    const egresos = Number(this.resumen.egresosTotales ?? 0);
    return ingresos - egresos;
  }

  get transaccionesFiltradas(): any[] {
    const texto = this.filtroTexto.trim().toLowerCase();
    const desdeTime = this.fechaDesde ? new Date(`${this.fechaDesde}T00:00:00`).getTime() : null;
    const hastaTime = this.fechaHasta ? new Date(`${this.fechaHasta}T23:59:59`).getTime() : null;

    return this.transacciones.filter((t) => {
      if (this.filtroTipo !== 'Todos' && t.tipo !== this.filtroTipo) {
        return false;
      }

      if (desdeTime !== null || hastaTime !== null) {
        const fechaTx = t.fecha ? new Date(t.fecha).getTime() : NaN;
        if (!Number.isNaN(fechaTx)) {
          if (desdeTime !== null && fechaTx < desdeTime) return false;
          if (hastaTime !== null && fechaTx > hastaTime) return false;
        }
      }

      if (texto) {
        const entidad = String(t.entidad ?? '').toLowerCase();
        const concepto = String(t.concepto ?? '').toLowerCase();
        const tipo = String(t.tipo ?? '').toLowerCase();
        const referencia = String(t.referencia ?? '').toLowerCase();
        const metodo = String(t.metodoPago ?? '').toLowerCase();
        if (
          !entidad.includes(texto) &&
          !concepto.includes(texto) &&
          !tipo.includes(texto) &&
          !referencia.includes(texto) &&
          !metodo.includes(texto)
        ) {
          return false;
        }
      }

      return true;
    });
  }

  limpiarFiltros(): void {
    this.filtroTipo = 'Todos';
    this.filtroTexto = '';
    this.fechaDesde = '';
    this.fechaHasta = '';
  }

  cargarDatosFinancieros(): void {
    this.cargando = true;
    this.errores = {
      resumen: null,
      flujo: null,
      cobranza: null,
      proveedores: null
    };

    forkJoin({
      resumen: this.finanzasService.obtenerResumenFinanciero().pipe(
        catchError((err) => {
          this.errores.resumen = err?.error?.mensaje || 'No se pudo cargar el resumen financiero.';
          return of(null);
        })
      ),
      flujo: this.finanzasService.obtenerFlujoCaja().pipe(
        catchError((err) => {
          this.errores.flujo = err?.error?.mensaje || 'No se pudo cargar el flujo de caja.';
          return of([]);
        })
      ),
      cobro: this.finanzasService.obtenerCobranzaActiva().pipe(
        catchError((err) => {
          this.errores.cobranza = err?.error?.mensaje || 'No se pudo cargar la cobranza activa.';
          return of([]);
        })
      ),
      proveedores: this.finanzasService.obtenerProveedoresPendientes().pipe(
        catchError((err) => {
          this.errores.proveedores = err?.error?.mensaje || 'No se pudieron cargar los pagos a proveedores.';
          return of([]);
        })
      )
    }).subscribe({
      next: (resultados) => {
        this.resumen = resultados.resumen;
        this.transacciones = Array.isArray(resultados.flujo) ? resultados.flujo : [];
        this.cobranza = Array.isArray(resultados.cobro) ? resultados.cobro : [];
        this.proveedores = Array.isArray(resultados.proveedores) ? resultados.proveedores : [];
        this.cargando = false;
      },
      error: () => {
        this.cargando = false;
      }
    });
  }

  cambiarPestana(pestana: string): void {
    this.pestanaActiva = pestana;
  }

  private sanitizarCeldaCsv(val: unknown): string {
    let texto = String(val ?? '');
    // Neutraliza fórmulas en Excel/Calc (=, +, -, @, tabulador, CR, LF)
    if (/^[=+\-@\t\r\n]/.test(texto)) {
      texto = `'${texto}`;
    }
    return `"${texto.replace(/"/g, '""')}"`;
  }

  exportarFlujoCsv(): void {
    const filas = this.transaccionesFiltradas;
    if (filas.length === 0) {
      this.toastr.info('No hay movimientos para exportar con los filtros actuales.', 'Exportación');
      return;
    }

    const encabezados = ['Fecha', 'Tipo', 'Referencia', 'Entidad', 'Concepto', 'MetodoPago', 'Monto'];
    const lineas = [
      encabezados.map((h) => this.sanitizarCeldaCsv(h)).join(','),
      ...filas.map((t) =>
        [
          t.fecha ? new Date(t.fecha).toISOString().split('T')[0] : '',
          t.tipo ?? '',
          t.referencia ?? '',
          t.entidad ?? '',
          t.concepto ?? '',
          t.metodoPago ?? '',
          Number(t.monto ?? 0).toFixed(2)
        ]
          .map((campo) => this.sanitizarCeldaCsv(campo))
          .join(',')
      )
    ];

    const blob = new Blob([`\uFEFF${lineas.join('\n')}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const enlace = document.createElement('a');
    enlace.href = url;
    enlace.download = `flujo-caja-${new Date().toISOString().split('T')[0]}.csv`;
    enlace.click();
    URL.revokeObjectURL(url);
  }

  abrirModalPagoProveedor(item: any): void {
    this.proveedorSeleccionado = item;
    this.saldoRestanteProveedor = Number(item.saldoPendiente ?? 0);
    this.datosPagoProveedor = {
      idEventoProveedor: item.idEventoProveedor,
      montoPagado: this.saldoRestanteProveedor,
      metodoPago: 'Transferencia',
      fechaPago: new Date().toISOString().split('T')[0]
    };

    const modal = document.getElementById('modal_pago_proveedor') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalPagoProveedor(): void {
    const modal = document.getElementById('modal_pago_proveedor') as HTMLDialogElement;
    if (modal) modal.close();
  }

  confirmarPagoProveedor(): void {
    const monto = Number(this.datosPagoProveedor.montoPagado);
    if (monto <= 0 || monto > this.saldoRestanteProveedor) {
      this.toastr.warning('Verifica que el monto sea mayor a $0 y no supere el saldo pendiente.', 'Monto inválido');
      return;
    }

    this.procesandoPagoProveedor = true;
    const payload: RegistrarPagoProveedor = {
      ...this.datosPagoProveedor,
      montoPagado: monto,
      fechaPago: new Date(`${this.datosPagoProveedor.fechaPago}T00:00:00`).toISOString()
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
        this.toastr.error(err?.error?.mensaje || 'Ocurrió un error al registrar el pago.', 'Error');
      }
    });
  }
}