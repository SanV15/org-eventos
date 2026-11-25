import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { CotizacionService } from '../../../core/services/cotizacion.service';
import { ServicioService, ServicioListado } from '../../../core/services/servicio.service';

export type UnidadCobroExterno = 'Por evento' | 'Por unidad';

interface ItemCarrito {
  tipo: 'Interno' | 'Externo';
  idServicio: number;
  nombre: string;
  unidadCobro?: UnidadCobroExterno;
  cantidad: number;
  precio: number;
  subtotal: number;
  observaciones?: string;
}

@Component({
  selector: 'app-nueva-cotizacion',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './nueva-cotizacion.component.html'
})
export class NuevaCotizacionComponent implements OnInit {
  private cotizacionService = inject(CotizacionService);
  private servicioService = inject(ServicioService);
  private http = inject(HttpClient);
  private router = inject(Router);

  clientes: any[] = [];
  serviciosInternos: ServicioListado[] = [];
  serviciosExternos: any[] = [];

  idClienteSeleccionado: number = 0;
  fechaReferencia: string = '';

  carrito: ItemCarrito[] = [];
  totalFinal: number = 0;
  guardando: boolean = false;

  servicioInternoSeleccionado: any = null;
  servicioExternoSeleccionado: any = null;

  get serviciosInternosDisponibles(): ServicioListado[] {
    const idsAgregados = this.carrito.filter(i => i.tipo === 'Interno').map(i => i.idServicio);
    return this.serviciosInternos.filter(s => !idsAgregados.includes(s.idServicio));
  }

  get serviciosExternosDisponibles(): any[] {
    const idsAgregados = this.carrito.filter(i => i.tipo === 'Externo').map(i => i.idServicio);
    return this.serviciosExternos.filter(se => !idsAgregados.includes(se.idServicioProveedor));
  }

  ngOnInit(): void {
    this.cargarCatalogos();
  }

  cargarCatalogos() {
    this.http.get<any[]>('https://localhost:7106/api/clientes/select').subscribe({
      next: (res) => { this.clientes = res; },
      error: (err) => console.error('❌ Error al cargar clientes:', err)
    });

    this.servicioService.obtenerServicios().subscribe({
      next: (res) => { this.serviciosInternos = res.filter(s => s.activo); },
      error: (err) => console.error('❌ Error servicios internos:', err)
    });

    this.http.get<any[]>('https://localhost:7106/api/serviciosproveedor').subscribe({
      next: (res) => { this.serviciosExternos = res.filter((s: any) => s.activo); },
      error: (err) => console.error('❌ Error al cargar servicios externos:', err)
    });
  }

  private normalizarUnidad(unidad?: string): UnidadCobroExterno {
    return unidad === 'Por unidad' ? 'Por unidad' : 'Por evento';
  }

  agregarServicioInterno() {
    if (!this.servicioInternoSeleccionado) return;

    this.carrito.push({
      tipo: 'Interno',
      idServicio: this.servicioInternoSeleccionado.idServicio,
      nombre: this.servicioInternoSeleccionado.nombre,
      cantidad: 1,
      precio: this.servicioInternoSeleccionado.precio,
      subtotal: this.servicioInternoSeleccionado.precio
    });

    this.servicioInternoSeleccionado = null;
    this.calcularTotal();
  }

  agregarServicioExterno() {
    if (!this.servicioExternoSeleccionado) return;

    const unidad = this.normalizarUnidad(this.servicioExternoSeleccionado.unidadCobro);

    this.carrito.push({
      tipo: 'Externo',
      idServicio: this.servicioExternoSeleccionado.idServicioProveedor,
      nombre: this.servicioExternoSeleccionado.nombreServicio,
      unidadCobro: unidad,
      cantidad: 1,
      precio: this.servicioExternoSeleccionado.costo,
      subtotal: this.servicioExternoSeleccionado.costo,
      observaciones: ''
    });

    this.servicioExternoSeleccionado = null;
    this.calcularTotal();
  }

  actualizarSubtotal(item: ItemCarrito) {
    if (item.cantidad < 1) item.cantidad = 1;
    if (item.precio < 0) item.precio = 0;
    item.subtotal = item.cantidad * item.precio;
    this.calcularTotal();
  }

  removerDelCarrito(index: number) {
    this.carrito.splice(index, 1);
    this.calcularTotal();
  }

  calcularTotal() {
    this.totalFinal = this.carrito.reduce((acc, item) => acc + item.subtotal, 0);
  }

  guardarCotizacion() {
    if (this.idClienteSeleccionado === 0 || this.carrito.length === 0) {
      alert('Por favor, selecciona un cliente y al menos un servicio.');
      return;
    }

    if (!this.fechaReferencia) {
      const continuarSinFecha = confirm('No estás escogiendo una fecha. ¿Deseas continuar?');
      if (!continuarSinFecha) {
        return;
      }
    }

    this.guardando = true;

    const payload = {
      idCliente: Number(this.idClienteSeleccionado),
      fechaReferencia: this.fechaReferencia || null,
      serviciosInternos: this.carrito
        .filter(i => i.tipo === 'Interno')
        .map(i => ({
          idServicio: i.idServicio,
          cantidad: i.cantidad,
          precioUnitario: i.precio
        })),
      serviciosExternos: this.carrito
        .filter(i => i.tipo === 'Externo')
        .map(i => ({
          idServicioProveedor: i.idServicio,
          cantidad: i.cantidad,
          precioCotizado: i.precio,
          observaciones: i.observaciones
        }))
    };

    this.cotizacionService.crearCotizacion(payload).subscribe({
      next: (res: any) => {
        this.guardando = false;

        if (res && res.advertencia) {
          const aceptarConflicto = confirm(
            res.advertencia + '\n\n¿Deseas continuar guardando la cotización a pesar del conflicto, o cancelar para cambiar la fecha?'
          );

          if (!aceptarConflicto) {
            return;
          }
        } else {
          alert('Cotización guardada exitosamente.');
        }

        this.router.navigate(['/cotizaciones']);
      },
      error: (err) => {
        console.error('Error al crear cotización', err);
        alert('Ocurrió un error al intentar guardar la cotización.');
        this.guardando = false;
      }
    });
  }
}