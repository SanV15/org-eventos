import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router'; // NUEVO: Necesario para el botón regresar
import { ServicioService, ServicioListado, ServicioRegistro } from '../../../core/services/servicio.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-listado-servicios',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent], // NUEVO: Agregado aquí
  templateUrl: './listado-servicios.component.html'
})
export class ListadoServiciosComponent implements OnInit {
  private servicioService = inject(ServicioService);

  servicios: ServicioListado[] = [];
  cargando: boolean = true;
  guardando: boolean = false;

  // Control del Modal Principal (Nuevo/Editar)
  modalAbierto: boolean = false;
  esEdicion: boolean = false;
  servicioSeleccionado: any = null;

  // Control del Modal de Confirmación
  modalConfirmacionAbierto: boolean = false;
  servicioACambiar: ServicioListado | null = null;

  ngOnInit(): void {
    this.cargarServicios();
  }

  cargarServicios() {
    this.cargando = true;
    this.servicioService.obtenerServicios().subscribe({
      next: (data) => {
        this.servicios = data;
        this.cargando = false;
      },
      error: (err) => {
        console.error(err);
        this.cargando = false;
      }
    });
  }

  // --- MÉTODOS DEL MODAL (NUEVO / EDITAR) ---
  abrirModalNuevo() {
    this.esEdicion = false;
    this.servicioSeleccionado = { nombre: '', descripcion: '', precio: 0 };
    this.modalAbierto = true;
  }

  abrirModalEdicion(servicio: ServicioListado) {
    this.esEdicion = true;
    this.servicioSeleccionado = { ...servicio }; 
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
    this.servicioSeleccionado = null;
  }

  guardarServicio() {
    if (!this.servicioSeleccionado.nombre || this.servicioSeleccionado.precio < 0) return;
    this.guardando = true;

    const payload: ServicioRegistro = {
      nombre: this.servicioSeleccionado.nombre,
      descripcion: this.servicioSeleccionado.descripcion,
      precio: this.servicioSeleccionado.precio
    };

    if (this.esEdicion) {
      this.servicioService.actualizarServicio(this.servicioSeleccionado.idServicio, payload).subscribe({
        next: () => this.finalizarGuardado(),
        error: (err) => { console.error(err); this.guardando = false; }
      });
    } else {
      this.servicioService.agregarServicio(payload).subscribe({
        next: () => this.finalizarGuardado(),
        error: (err) => { console.error(err); this.guardando = false; }
      });
    }
  }

  private finalizarGuardado() {
    this.cargarServicios();
    this.cerrarModal();
    this.guardando = false;
  }

  // --- MÉTODOS DEL MODAL DE CONFIRMACIÓN (ESTADO) ---
  abrirModalConfirmacion(servicio: ServicioListado) {
    this.servicioACambiar = servicio;
    this.modalConfirmacionAbierto = true;
  }

  cerrarModalConfirmacion() {
    this.modalConfirmacionAbierto = false;
    this.servicioACambiar = null;
  }

  confirmarCambioEstado() {
    if (!this.servicioACambiar) return;
    
    const nuevoEstado = !this.servicioACambiar.activo;
    this.servicioService.cambiarEstado(this.servicioACambiar.idServicio, nuevoEstado).subscribe({
      next: () => {
        this.servicioACambiar!.activo = nuevoEstado; // Actualiza la vista
        this.cerrarModalConfirmacion();
      },
      error: (err) => {
        console.error(err);
        this.cerrarModalConfirmacion();
      }
    });
  }
}