import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { ProveedorService, Categoria, ProveedorRegistro } from '../../../core/services/proveedor.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-editar-proveedor',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, BreadcrumbsComponent],
  templateUrl: './editar-proveedor.component.html'
})
export class EditarProveedorComponent implements OnInit {
  private proveedorService = inject(ProveedorService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  idProveedor: number = 0;
  categorias: Categoria[] = [];
  cargando: boolean = true;
  guardando: boolean = false;
  mensajeError: string = '';

  archivoFotoNuevo: File | null = null;
  previewFotoUrl: string | null = null;
  errorImagenActual: boolean = false;

  proveedor: ProveedorRegistro = {
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
    this.idProveedor = Number(this.route.snapshot.paramMap.get('id'));

    this.proveedorService.obtenerCategorias().subscribe({
      next: (cats) => {
        this.categorias = cats;
        this.cargarProveedor();
      },
      error: () => this.mensajeError = 'Error al cargar las categorías.'
    });
  }

  cargarProveedor() {
    this.proveedorService.obtenerProveedorPorId(this.idProveedor).subscribe({
      next: (data) => {
        this.proveedor = data;
        this.cargando = false;
      },
      error: () => {
        this.router.navigate(['/proveedores']);
      }
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
    this.archivoFotoNuevo = file;

    const reader = new FileReader();
    reader.onload = () => {
      this.previewFotoUrl = reader.result as string;
    };
    reader.readAsDataURL(file);
  }

  cancelarCambioFoto() {
    this.archivoFotoNuevo = null;
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

  actualizar() {
    if (this.proveedor.categoriasIds.length === 0) {
      this.mensajeError = 'Debes seleccionar al menos una categoría.';
      return;
    }

    this.guardando = true;
    this.mensajeError = '';

    this.proveedorService.actualizarProveedor(this.idProveedor, this.proveedor).subscribe({
      next: () => {
        if (this.archivoFotoNuevo) {
          this.proveedorService.subirFotoProveedor(this.idProveedor, this.archivoFotoNuevo).subscribe({
            next: () => this.router.navigate(['/proveedores']),
            error: () => this.router.navigate(['/proveedores'])
          });
        } else {
          this.router.navigate(['/proveedores']);
        }
      },
      error: (err) => {
        this.guardando = false;
        this.mensajeError = err.error?.mensaje || 'Error interno al actualizar.';
      }
    });
  }
}