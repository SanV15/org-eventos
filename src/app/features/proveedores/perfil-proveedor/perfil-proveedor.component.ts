import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ProveedorService, ProveedorRegistro } from '../../../core/services/proveedor.service';
import { ServicioProveedorService, ServicioProveedorListado, ServicioProveedorRegistro } from '../../../core/services/servicio-proveedor.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

export type UnidadCobroServicio = 'Por evento' | 'Por unidad';

@Component({
  selector: 'app-perfil-proveedor',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, BreadcrumbsComponent],
  templateUrl: './perfil-proveedor.component.html'
})
export class PerfilProveedorComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private proveedorService = inject(ProveedorService);
  private servicioService = inject(ServicioProveedorService);

  idProveedor: number = 0;
  proveedor: ProveedorRegistro | null = null;
  servicios: ServicioProveedorListado[] = [];

  cargandoProveedor: boolean = true;
  cargandoServicios: boolean = true;
  guardandoServicio: boolean = false;
  subiendoFoto: boolean = false;
  errorImagen: boolean = false;
  modalImagenAbierto: boolean = false;

  fechasOcupadas: any[] = [];

  readonly unidadesCobro: UnidadCobroServicio[] = ['Por evento', 'Por unidad'];

  // Variables para la modal de detalle del servicio
  modalAbierto: boolean = false;
  servicioSeleccionado: ServicioProveedorListado | null = null;

  // Modelo para el formulario del nuevo servicio
  nuevoServicio: ServicioProveedorRegistro & { unidadCobro: UnidadCobroServicio } = {
    nombreServicio: '',
    descripcion: '',
    costo: 0,
    unidadCobro: 'Por evento'
  };

  // Variables para edición de servicio
  modalEdicionAbierto: boolean = false;
  servicioEnEdicion: any = null;
  guardandoEdicion: boolean = false;

  ngOnInit(): void {
    this.idProveedor = Number(this.route.snapshot.paramMap.get('id'));
    this.cargarProveedor();
    this.cargarServicios();
  }

  cargarProveedor() {
    this.proveedorService.obtenerProveedorPorId(this.idProveedor).subscribe({
      next: (data) => {
        this.proveedor = data;
        this.errorImagen = false;
        this.cargandoProveedor = false;
      },
      error: (err) => console.error(err)
    });
  }

  onSeleccionarFotoPerfil(event: Event) {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0];
    if (!archivo) return;

    const tiposPermitidos = ['image/jpeg', 'image/png', 'image/webp'];
    if (!tiposPermitidos.includes(archivo.type)) {
      alert('Formato no permitido. Usa JPG, PNG o WEBP.');
      input.value = '';
      return;
    }

    this.subiendoFoto = true;
    this.proveedorService.subirFotoProveedor(this.idProveedor, archivo).subscribe({
      next: (res) => {
        if (this.proveedor) {
          this.proveedor.fotoProveedorUrl = res.fotoProveedorUrl;
          this.errorImagen = false;
        }
        this.subiendoFoto = false;
        input.value = '';
      },
      error: (err) => {
        console.error('Error al subir imagen:', err);
        alert(err.error?.mensaje || 'No se pudo subir la imagen del proveedor.');
        this.subiendoFoto = false;
        input.value = '';
      }
    });
  }

  obtenerIniciales(): string {
    if (!this.proveedor?.nombre) return 'P';
    const n = this.proveedor.nombre.charAt(0).toUpperCase();
    const a = this.proveedor.apellidoPaterno ? this.proveedor.apellidoPaterno.charAt(0).toUpperCase() : '';
    return `${n}${a}`;
  }

  cargarCalendarioOcupacion(idProveedor: number) {
    this.proveedorService.obtenerFechasOcupadas(idProveedor).subscribe({
      next: (data) => {
        this.fechasOcupadas = data;
        const modal = document.getElementById('modal_calendario') as HTMLDialogElement;
        if (modal) modal.showModal();
      },
      error: (err) => {
        console.error('Error al cargar fechas ocupadas:', err);
        alert('No se pudo cargar el calendario de ocupación.');
      }
    });
  }

  cargarServicios() {
    this.servicioService.obtenerServiciosPorProveedor(this.idProveedor).subscribe({
      next: (data) => {
        this.servicios = data;
        this.cargandoServicios = false;
      },
      error: (err) => {
        console.error('Error al cargar servicios:', err);
        this.cargandoServicios = false;
      }
    });
  }

  registrarServicio() {
    if (!this.nuevoServicio.nombreServicio || this.nuevoServicio.costo < 0) return;

    this.guardandoServicio = true;
    const payload: ServicioProveedorRegistro & { unidadCobro: UnidadCobroServicio } = {
      nombreServicio: this.nuevoServicio.nombreServicio,
      descripcion: this.nuevoServicio.descripcion,
      costo: this.nuevoServicio.costo,
      unidadCobro: this.nuevoServicio.unidadCobro || 'Por evento'
    };

    this.servicioService.agregarServicio(this.idProveedor, payload).subscribe({
      next: () => {
        this.cargarServicios();
        this.nuevoServicio = {
          nombreServicio: '',
          descripcion: '',
          costo: 0,
          unidadCobro: 'Por evento'
        };
        this.guardandoServicio = false;
      },
      error: (err) => {
        console.error(err);
        this.guardandoServicio = false;
      }
    });
  }

  abrirModalEdicion(servicio: ServicioProveedorListado) {
    this.servicioEnEdicion = {
      ...servicio,
      unidadCobro: (servicio as any).unidadCobro || 'Por evento'
    };
    this.modalEdicionAbierto = true;
  }

  cerrarModalEdicion() {
    this.modalEdicionAbierto = false;
    this.servicioEnEdicion = null;
  }

  guardarEdicion() {
    if (!this.servicioEnEdicion.nombreServicio || this.servicioEnEdicion.costo < 0) return;
    this.guardandoEdicion = true;

    const payload: ServicioProveedorRegistro & { unidadCobro: UnidadCobroServicio } = {
      nombreServicio: this.servicioEnEdicion.nombreServicio,
      descripcion: this.servicioEnEdicion.descripcion,
      costo: this.servicioEnEdicion.costo,
      unidadCobro: this.servicioEnEdicion.unidadCobro || 'Por evento'
    };

    this.servicioService.actualizarServicio(this.servicioEnEdicion.idServicioProveedor, payload).subscribe({
      next: () => {
        this.cargarServicios();
        this.cerrarModalEdicion();
        this.guardandoEdicion = false;
      },
      error: (err) => {
        console.error('Error al actualizar servicio', err);
        this.guardandoEdicion = false;
      }
    });
  }

  abrirModal(servicio: ServicioProveedorListado) {
    this.servicioSeleccionado = servicio;
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
    this.servicioSeleccionado = null;
  }

  confirmarCambioEstado() {
    if (!this.servicioSeleccionado) return;

    const nuevoEstado = !this.servicioSeleccionado.activo;

    this.servicioService.cambiarEstado(this.servicioSeleccionado.idServicioProveedor, nuevoEstado).subscribe({
      next: () => {
        this.servicioSeleccionado!.activo = nuevoEstado;
        this.cerrarModal();
      },
      error: (err) => {
        console.error(err);
        this.cerrarModal();
      }
    });
  }
}