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
  descripcion?: string;
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

  // Filtros de búsqueda
  filtroCliente: string = '';
  filtroServicioInterno: string = '';
  filtroServicioExterno: string = '';

  // Panel desplegable para agregar conceptos sin que se pierda al trabajar en el resumen
  panelConceptosAbierto: boolean = true;

  carrito: ItemCarrito[] = [];
  totalFinal: number = 0;
  guardando: boolean = false;

  servicioInternoSeleccionado: any = null;
  servicioExternoSeleccionado: any = null;

  get clientesFiltrados(): any[] {
    const q = this.filtroCliente.trim().toLowerCase();
    if (!q) return this.clientes;
    return this.clientes.filter(c =>
      String(c?.nombreConDetalle ?? c?.nombre ?? '').toLowerCase().includes(q)
    );
  }

  get serviciosInternosDisponibles(): ServicioListado[] {
    const idsAgregados = this.carrito.filter(i => i.tipo === 'Interno').map(i => i.idServicio);
    const base = this.serviciosInternos.filter(s => !idsAgregados.includes(s.idServicio));
    const q = this.filtroServicioInterno.trim().toLowerCase();
    if (!q) return base;
    return base.filter(s =>
      String(s?.nombre ?? '').toLowerCase().includes(q) ||
      String(s?.descripcion ?? '').toLowerCase().includes(q) ||
      String(s?.precio ?? '').toLowerCase().includes(q)
    );
  }

  get serviciosExternosDisponibles(): any[] {
    const idsAgregados = this.carrito.filter(i => i.tipo === 'Externo').map(i => i.idServicio);
    const base = this.serviciosExternos.filter(se => !idsAgregados.includes(se.idServicioProveedor));
    const q = this.filtroServicioExterno.trim().toLowerCase();
    if (!q) return base;
    return base.filter(se =>
      String(se?.nombreServicio ?? '').toLowerCase().includes(q) ||
      String(se?.nombreProveedor ?? '').toLowerCase().includes(q) ||
      String(se?.unidadCobro ?? '').toLowerCase().includes(q) ||
      String(se?.costo ?? '').toLowerCase().includes(q)
    );
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

  onFiltroClienteChange() {
    if (this.idClienteSeleccionado && !this.clientesFiltrados.some(c => Number(c.idCliente) === Number(this.idClienteSeleccionado))) {
      this.idClienteSeleccionado = 0;
    }
  }

  onFiltroInternoChange() {
    if (this.servicioInternoSeleccionado && !this.serviciosInternosDisponibles.some(s => s.idServicio === this.servicioInternoSeleccionado.idServicio)) {
      this.servicioInternoSeleccionado = null;
    }
  }

  onFiltroExternoChange() {
    if (this.servicioExternoSeleccionado && !this.serviciosExternosDisponibles.some(se => se.idServicioProveedor === this.servicioExternoSeleccionado.idServicioProveedor)) {
      this.servicioExternoSeleccionado = null;
    }
  }

  private normalizarUnidad(unidad?: string): UnidadCobroExterno {
    return unidad === 'Por unidad' ? 'Por unidad' : 'Por evento';
  }

  private obtenerDescripcionExterna(sp: any): string {
    const raw = sp?.descripcion ?? sp?.descripcionServicio ?? sp?.detalles ?? '';
    return String(raw).trim();
  }

  agregarServicioInterno() {
    if (!this.servicioInternoSeleccionado) return;

    const precioFijo = Number(this.servicioInternoSeleccionado.precio ?? 0);
    const descripcion = String(this.servicioInternoSeleccionado.descripcion ?? '').trim();

    this.carrito.push({
      tipo: 'Interno',
      idServicio: this.servicioInternoSeleccionado.idServicio,
      nombre: this.servicioInternoSeleccionado.nombre,
      descripcion,
      cantidad: 1,
      precio: precioFijo,
      subtotal: precioFijo
    });

    this.servicioInternoSeleccionado = null;
    this.calcularTotal();
  }

  agregarServicioExterno() {
    if (!this.servicioExternoSeleccionado) return;

    const unidad = this.normalizarUnidad(this.servicioExternoSeleccionado.unidadCobro);
    const precioFijo = Number(this.servicioExternoSeleccionado.costo ?? 0);
    const descripcion = this.obtenerDescripcionExterna(this.servicioExternoSeleccionado);

    this.carrito.push({
      tipo: 'Externo',
      idServicio: this.servicioExternoSeleccionado.idServicioProveedor,
      nombre: this.servicioExternoSeleccionado.nombreServicio,
      descripcion,
      unidadCobro: unidad,
      cantidad: 1,
      precio: precioFijo,
      subtotal: precioFijo,
      observaciones: ''
    });

    this.servicioExternoSeleccionado = null;
    this.calcularTotal();
  }

  actualizarSubtotal(item: ItemCarrito) {
    if (item.cantidad < 1) item.cantidad = 1;
    const precioFijo = Number(item.precio ?? 0);
    item.subtotal = item.cantidad * precioFijo;
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