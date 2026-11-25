import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AwsTareasService, TareaAWS } from '../../../core/services/aws-tareas.service';

@Component({
  selector: 'app-tareas-externas',
  standalone: true, 
  imports: [CommonModule, FormsModule], // Asegura que ngModel y ngFor funcionen
  templateUrl: './tareas-externas.component.html'
})
export class TareasExternasComponent implements OnInit {
  tareas: TareaAWS[] = [];
  tareaActual: TareaAWS = { nombre: '', descripcion: '', estado: 'Pendiente' };
  modoEdicion = false;
  cargando = false;

  constructor(private awsService: AwsTareasService) {}

  ngOnInit(): void {
    this.cargarTareas();
  }

  cargarTareas(): void {
    this.cargando = true;
    this.awsService.obtenerTareas().subscribe({
      next: (data: TareaAWS[]) => {
        this.tareas = data;
        this.cargando = false;
      },
      error: (err: unknown) => {
        console.error('Error al cargar tareas AWS', err);
        this.cargando = false;
      }
    });
  }

  guardarTarea(): void {
    if (this.modoEdicion && this.tareaActual.idTarea) {
      this.awsService.actualizarTarea(this.tareaActual.idTarea, this.tareaActual).subscribe({
        next: () => {
          this.cargarTareas();
          this.resetFormulario();
        },
        error: (err: unknown) => console.error('Error al actualizar', err)
      });
    } else {
      this.awsService.crearTarea(this.tareaActual).subscribe({
        next: () => {
          this.cargarTareas();
          this.resetFormulario();
        },
        error: (err: unknown) => console.error('Error al crear', err)
      });
    }
  }

  editarTarea(tarea: TareaAWS): void {
    this.tareaActual = { ...tarea };
    this.modoEdicion = true;
  }

  eliminar(id: string): void {
    if (confirm('¿Eliminar esta tarea de proveedor externo?')) {
      this.awsService.eliminarTarea(id).subscribe({
        next: () => this.cargarTareas(),
        error: (err: unknown) => console.error('Error al eliminar', err)
      });
    }
  }

  resetFormulario(): void {
    this.tareaActual = { nombre: '', descripcion: '', estado: 'Pendiente' };
    this.modoEdicion = false;
  }
}