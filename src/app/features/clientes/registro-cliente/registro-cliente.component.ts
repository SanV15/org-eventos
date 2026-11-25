import { Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ClienteService } from '../../../core/services/cliente.service';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-registro-cliente',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink], // <-- ¡Aquí debe estar RouterLink!
  templateUrl: './registro-cliente.component.html'
})
export class RegistroClienteComponent {
  private fb = inject(FormBuilder);
  private clienteService = inject(ClienteService);

  // Formulario simplificado con un solo correo
  registroForm: FormGroup = this.fb.group({
    nombre: ['', Validators.required],
    apellidoPaterno: ['', Validators.required],
    apellidoMaterno: [''],
    correo: ['', [Validators.required, Validators.email]], // <-- Solo un correo
    telefono: [''],
    direccion: ['']
  });

  mensajeExito: string = '';
  mensajeError: string = '';
  cargando: boolean = false;

  onSubmit() {
    if (this.registroForm.invalid) {
      this.registroForm.markAllAsTouched();
      return;
    }

    this.cargando = true;
    
    // Extraemos los datos del formulario
    const formValues = this.registroForm.value;
    
    // Armamos el objeto tal como lo espera tu API en C#
    const payload = {
      nombre: formValues.nombre,
      apellidoPaterno: formValues.apellidoPaterno,
      apellidoMaterno: formValues.apellidoMaterno,
      correoAcceso: formValues.correo,   // Se envía a la tabla USUARIO
      correoContacto: formValues.correo, // Se envía a la tabla CLIENTE
      telefono: formValues.telefono,
      direccion: formValues.direccion
    };

    this.clienteService.registrarCliente(payload).subscribe({
      next: (res) => {
        this.mensajeExito = res.mensaje;
        this.registroForm.reset();
        this.cargando = false;
        
        // Ocultar mensaje después de 3 segundos
        setTimeout(() => this.mensajeExito = '', 3000);
      },
      error: (err) => {
        this.mensajeError = err.error?.mensaje || 'Error al registrar el cliente.';
        this.cargando = false;
        
        // Ocultar error después de 3 segundos
        setTimeout(() => this.mensajeError = '', 3000);
      }
    });
  }
}