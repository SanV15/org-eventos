import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { ProveedorService, Categoria } from '../../../core/services/proveedor.service';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-nuevo-proveedor',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './nuevo-proveedor.component.html'
})
export class NuevoProveedorComponent implements OnInit {
  private proveedorService = inject(ProveedorService);
  private http = inject(HttpClient);
  private router = inject(Router);

  categorias: Categoria[] = [];
  cargando: boolean = false;
  mensajeError: string = '';

  archivoFoto: File | null = null;
  previewFotoUrl: string | null = null;

  proveedor: any = {
    nombre: '',
    apellidoPaterno: '',
    apellidoMaterno: '',
    telefono: '',
    correo: '',
    direccion: '',
    descripcion: '',
    banco: '',
    clabeInterbancaria: '',
    titularCuenta: '',
    categoriasIds: []
  };

  ngOnInit(): void {
    this.proveedorService.obtenerCategorias().subscribe({
      next: (data) => this.categorias = data,
      error: (err) => console.error('Error al cargar categorías', err)
    });
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const tiposPermitidos = ['image/jpeg', 'image/png', 'image/webp'];
    if (!tiposPermitidos.includes(file.type)) {
      this.mensajeError = 'Formato de imagen no válido. Usa JPG, PNG o WEBP.';
      input.value = '';
      return;
    }

    this.mensajeError = '';
    this.archivoFoto = file;

    const reader = new FileReader();
    reader.onload = () => {
      this.previewFotoUrl = reader.result as string;
    };
    reader.readAsDataURL(file);
  }

  quitarFoto() {
    this.archivoFoto = null;
    this.previewFotoUrl = null;
  }

  toggleCategoria(idCategoria: number) {
    const index = this.proveedor.categoriasIds.indexOf(idCategoria);
    if (index === -1) {
      this.proveedor.categoriasIds.push(idCategoria);
    } else {
      this.proveedor.categoriasIds.splice(index, 1);
    }
  }

  registrar() {
    if (this.proveedor.categoriasIds.length === 0) {
      this.mensajeError = 'Debes seleccionar al menos una categoría para el proveedor.';
      return;
    }

    this.cargando = true;
    this.mensajeError = '';

    this.proveedorService.registrar(this.proveedor).subscribe({
      next: () => {
        if (!this.archivoFoto) {
          this.router.navigate(['/proveedores']);
          return;
        }

        // Obtenemos el último ID registrado para asociar la imagen
        this.http.get<any[]>(`${environment.apiUrl}/api/proveedores`).subscribe({
          next: (lista) => {
            const ultimoId = lista.reduce(
              (max, item) => (item.idProveedor > max ? item.idProveedor : max),
              0
            );

            if (ultimoId > 0 && this.archivoFoto) {
              this.proveedorService.subirFotoProveedor(ultimoId, this.archivoFoto).subscribe({
                next: () => this.router.navigate(['/proveedores']),
                error: () => this.router.navigate(['/proveedores'])
              });
            } else {
              this.router.navigate(['/proveedores']);
            }
          },
          error: () => this.router.navigate(['/proveedores'])
        });
      },
      error: (err) => {
        this.cargando = false;
        this.mensajeError = err.error?.mensaje || 'Error interno al registrar el proveedor.';
        console.error(err);
      }
    });
  }
}