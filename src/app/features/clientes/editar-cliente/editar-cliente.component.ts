import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { ClienteService } from '../../../core/services/cliente.service';

@Component({
  selector: 'app-editar-cliente',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './editar-cliente.component.html'
})
export class EditarClienteComponent implements OnInit {
  private clienteService = inject(ClienteService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  idCliente: number = 0;
  cargando: boolean = true;
  modalAbierto: boolean = false;
  mensajeError: string = '';

  // Objeto enlazado al formulario
  cliente: any = {
    nombre: '', apellidoPaterno: '', apellidoMaterno: '',
    correoContacto: '', telefono: '', direccion: ''
  };

  ngOnInit(): void {
    // Obtener el ID de la URL
    this.idCliente = Number(this.route.snapshot.paramMap.get('id'));
    
    this.clienteService.obtenerClientePorId(this.idCliente).subscribe({
      next: (data) => {
        this.cliente = data;
        this.cargando = false;
      },
      error: (err) => {
        console.error(err);
        this.router.navigate(['/clientes']); // Regresar si hay error
      }
    });
  }

  abrirModal() {
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
  }

confirmarActualizacion() {
    this.mensajeError = ''; // Limpiamos errores previos

    this.clienteService.actualizarCliente(this.idCliente, this.cliente).subscribe({
      next: () => {
        this.cerrarModal();
        this.router.navigate(['/clientes']);
      },
      error: (err) => {
        console.error('Error al actualizar', err);
        this.cerrarModal();
        
        // Atrapamos el mensaje que manda tu API en C#
        if (err.error && err.error.mensaje) {
          this.mensajeError = err.error.mensaje;
        } else {
          this.mensajeError = 'Ocurrió un error inesperado al guardar los datos.';
        }
      }
    });
  }
}