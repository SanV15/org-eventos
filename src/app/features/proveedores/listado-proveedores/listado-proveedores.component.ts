import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ProveedorService } from '../../../core/services/proveedor.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-listado-proveedores',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, BreadcrumbsComponent],
  templateUrl: './listado-proveedores.component.html'
})
export class ListadoProveedoresComponent implements OnInit {
  private proveedorService = inject(ProveedorService);

  proveedores: any[] = [];
  proveedoresFiltrados: any[] = [];
  cargando: boolean = true;
  terminoBusqueda: string = '';

  // Modal cambio de estado
  modalAbierto: boolean = false;
  proveedorSeleccionado: any = null;

  // Modal vista previa de imagen
  imagenModalUrl: string | null = null;
  imagenModalTitulo: string = '';

  ngOnInit(): void {
    this.cargarProveedores();
  }

  cargarProveedores() {
    this.proveedorService.obtenerProveedores().subscribe({
      next: (data: any[]) => {
        this.proveedores = data;
        this.proveedoresFiltrados = data;
        this.cargando = false;
      },
      error: (err: any) => {
        console.error('Error al cargar proveedores', err);
        this.cargando = false;
      }
    });
  }

  filtrarProveedores() {
    const termino = this.terminoBusqueda.toLowerCase().trim();
    if (!termino) {
      this.proveedoresFiltrados = this.proveedores;
    } else {
      this.proveedoresFiltrados = this.proveedores.filter(p =>
        (p.nombreCompleto && p.nombreCompleto.toLowerCase().includes(termino)) ||
        (p.correo && p.correo.toLowerCase().includes(termino)) ||
        (p.categorias && p.categorias.toLowerCase().includes(termino))
      );
    }
  }

  obtenerInicial(nombreCompleto: string): string {
    if (!nombreCompleto || !nombreCompleto.trim()) return 'P';
    return nombreCompleto.trim().charAt(0).toUpperCase();
  }

  abrirVistaPrevia(prov: any) {
    if (!prov.fotoProveedorUrl || prov._errorImg) return;
    this.imagenModalUrl = prov.fotoProveedorUrl;
    this.imagenModalTitulo = prov.nombreCompleto || 'Proveedor';
  }

  cerrarVistaPrevia() {
    this.imagenModalUrl = null;
    this.imagenModalTitulo = '';
  }

  abrirModal(proveedor: any) {
    this.proveedorSeleccionado = proveedor;
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
    this.proveedorSeleccionado = null;
  }

  confirmarCambioEstado() {
    if (!this.proveedorSeleccionado) return;

    const nuevoEstado = !this.proveedorSeleccionado.activo;

    this.proveedorService.cambiarEstado(this.proveedorSeleccionado.idProveedor, nuevoEstado).subscribe({
      next: () => {
        this.proveedorSeleccionado.activo = nuevoEstado;
        this.cerrarModal();
      },
      error: (err: any) => {
        console.error('Error al cambiar estado', err);
        this.cerrarModal();
      }
    });
  }
}