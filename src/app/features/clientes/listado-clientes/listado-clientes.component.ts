import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ClienteService, ClienteListado } from '../../../core/services/cliente.service';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { TemaService } from '../../../core/services/tema.service';

@Component({
  selector: 'app-listado-clientes',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './listado-clientes.component.html'
})
export class ListadoClientesComponent implements OnInit {
  private clienteService = inject(ClienteService);
  private toastr = inject(ToastrService);
  readonly temaService = inject(TemaService);

  clientes: ClienteListado[] = [];
  clientesFiltrados: ClienteListado[] = [];
  cargando: boolean = true;
  terminoBusqueda: string = '';

  // --- VARIABLES PARA EL MODAL ---
  modalAbierto: boolean = false;
  clienteSeleccionado: ClienteListado | null = null;
  estadoPendiente: boolean = false; // Guarda si lo vamos a activar o desactivar

  ngOnInit(): void {
    this.cargarClientes();
  }

  cargarClientes() {
    this.cargando = true;
    this.clienteService.obtenerClientes().subscribe({
      next: (data) => {
        this.clientes = data;
        this.clientesFiltrados = data;
        this.cargando = false;
      },
      error: (err) => {
        console.error(err);
        this.toastr.error('No se pudieron cargar los clientes.', 'Error');
        this.cargando = false;
      }
    });
  }

  filtrarClientes() {
    const termino = this.terminoBusqueda.toLowerCase().trim();
    if (!termino) {
      this.clientesFiltrados = this.clientes;
    } else {
      this.clientesFiltrados = this.clientes.filter(c =>
        c.nombreCompleto.toLowerCase().includes(termino) ||
        c.correoContacto.toLowerCase().includes(termino)
      );
    }
  }

  // --- MÉTODOS DEL MODAL ---

  abrirModal(cliente: ClienteListado) {
    this.clienteSeleccionado = cliente;
    this.estadoPendiente = !cliente.activo;
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
    this.clienteSeleccionado = null;
  }

  confirmarCambio() {
    if (!this.clienteSeleccionado) return;

    const clienteActual = this.clienteSeleccionado;
    const nuevoEstado = this.estadoPendiente;

    this.clienteService.cambiarEstado(clienteActual.idCliente, nuevoEstado).subscribe({
      next: () => {
        clienteActual.activo = nuevoEstado;
        if (nuevoEstado) {
          this.toastr.success(
            `El cliente ${clienteActual.nombreCompleto} ha sido activado.`,
            'Cliente activado'
          );
        } else {
          this.toastr.warning(
            `El cliente ${clienteActual.nombreCompleto} ha sido desactivado.`,
            'Cliente desactivado'
          );
        }
        this.cerrarModal();
      },
      error: (err) => {
        console.error('Error al cambiar estado', err);
        this.toastr.error('No se pudo actualizar el estado del cliente.', 'Error');
        this.cerrarModal();
      }
    });
  }
}