import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule, Router } from '@angular/router';
import {
  CotizacionService,
  CotizacionLectura,
  AprobarCotizacion
} from '../../../core/services/cotizacion.service';
import { CotizacionPdfService } from '../../../core/services/cotizacion-pdf.service';
import { EventoService } from '../../../core/services/evento.service';
import { TemaService } from '../../../core/services/tema.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-detalle-cotizacion',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, BreadcrumbsComponent],
  templateUrl: './detalle-cotizacion.component.html'
})
export class DetalleCotizacionComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private cotizacionService = inject(CotizacionService);
  private cotizacionPdfService = inject(CotizacionPdfService);
  private eventoService = inject(EventoService);
  readonly temaService = inject(TemaService);
  private ultimoNumeroInvitados: number = 50;

  cotizacion: CotizacionLectura | null = null;
  cargando: boolean = true;
  generandoPDF: boolean = false;
  procesandoAprobacion: boolean = false;
  minFechaEvento: string = '';

  fechaFinEvento: string = '';
  entradaLibre: boolean = false;

  mensajeErrorAprobacion: string | null = null;
  avisoFechaOcupada: string | null = null;

  // Imagen opcional de referencia del evento
  archivoFotoEvento: File | null = null;
  previewFotoEvento: string | null = null;

  // Catálogo de tipos de evento desde la BD
  tiposEvento: { idTipoEvento: number; nombre: string }[] = [];

  // Datos para el formulario del modal vinculados con idTipoEvento
  datosEvento: AprobarCotizacion = {
    nombreEvento: '',
    idTipoEvento: 0,
    fechaEvento: '',
    lugar: '',
    numeroInvitados: 50,
    idUsuarioCoordinador: 1,
    numeroCuotas: 1
  };

  ngOnInit(): void {
    const hoy = new Date();
    const offset = hoy.getTimezoneOffset() * 60000;
    this.minFechaEvento = new Date(hoy.getTime() - offset)
      .toISOString()
      .slice(0, 16);

    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) {
      this.cargarDetalles(id);
    }

    this.cotizacionService.obtenerTiposEvento().subscribe({
      next: (data) => {
        this.tiposEvento = data;
        if (data.length > 0) {
          this.datosEvento.idTipoEvento = data[0].idTipoEvento;
        }
      },
      error: (err: any) => console.error('Error al cargar tipos de evento:', err)
    });
  }

  cargarDetalles(id: number) {
    this.cargando = true;
    this.cotizacionService.obtenerCotizacionPorId(id).subscribe({
      next: (data) => {
        this.cotizacion = data;
        this.cargando = false;

        const debeAbrirAprobar = this.route.snapshot.queryParamMap.get('aprobar') === '1';
        if (debeAbrirAprobar && data?.estado === 'Pendiente') {
          setTimeout(() => this.abrirModalAprobacion(), 50);
        }
      },
      error: (err: any) => {
        console.error('Error al cargar la cotización', err);
        this.cargando = false;
      }
    });
  }

abrirModalAprobacion() {
  if (this.cotizacion && (this.cotizacion as any).fechaReferencia) {
    const refFecha = (this.cotizacion as any).fechaReferencia;
    this.datosEvento.fechaEvento = refFecha.includes('T')
      ? refFecha
      : `${refFecha}T00:00`;
  } else {
    this.datosEvento.fechaEvento = '';
  }

  this.fechaFinEvento = '';
  this.entradaLibre = false;

  // Buscar si algún servicio externo "Por persona" trae cantidad estimada en la cotización
  const serviciosPorPersona = (this.cotizacion?.serviciosExternos || []).filter(
    (se: any) => se.unidadCobro === 'Por persona' && Number(se.cantidad) > 0
  );

  if (serviciosPorPersona.length > 0) {
    const cantidadEstimada = Math.max(
      ...serviciosPorPersona.map((se: any) => Number(se.cantidad))
    );
    this.datosEvento.numeroInvitados = cantidadEstimada;
    this.ultimoNumeroInvitados = cantidadEstimada;
  } else {
    this.datosEvento.numeroInvitados =
      this.ultimoNumeroInvitados > 0 ? this.ultimoNumeroInvitados : 50;
  }

  this.mensajeErrorAprobacion = null;
  this.avisoFechaOcupada = null;
  this.archivoFotoEvento = null;
  this.previewFotoEvento = null;

  const modal = document.getElementById('modal_aprobar') as HTMLDialogElement;
  if (modal) modal.showModal();
}

  cerrarModalAprobacion() {
    const modal = document.getElementById('modal_aprobar') as HTMLDialogElement;
    if (modal) modal.close();
  }

  onSeleccionarFotoEvento(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const tiposPermitidos = ['image/jpeg', 'image/png', 'image/webp'];
    if (!tiposPermitidos.includes(file.type)) {
      alert('Formato no permitido. Selecciona una imagen JPG, PNG o WEBP.');
      input.value = '';
      return;
    }

    this.archivoFotoEvento = file;
    const reader = new FileReader();
    reader.onload = () => {
      this.previewFotoEvento = reader.result as string;
    };
    reader.readAsDataURL(file);
  }

  quitarFotoEvento() {
    this.archivoFotoEvento = null;
    this.previewFotoEvento = null;
  }

  private finalizarAprobacionYRedirigir() {
    this.procesandoAprobacion = false;
    this.cerrarModalAprobacion();

    if (this.cotizacion && this.cotizacion.idCliente) {
      this.router.navigate(['/clientes', this.cotizacion.idCliente, 'finanzas']);
    } else {
      this.router.navigate(['/pagos']);
    }
  }

  confirmarAprobacion() {
    if (!this.cotizacion) return;

    if (!this.datosEvento.fechaEvento) {
      alert('Por favor selecciona una fecha para el evento');
      return;
    }

    const soloFechaInicio = this.datosEvento.fechaEvento.split('T')[0];
    const soloFechaFin = this.fechaFinEvento
      ? this.fechaFinEvento.split('T')[0]
      : null;

    if (soloFechaFin && soloFechaFin < soloFechaInicio) {
      alert('La fecha de fin no puede ser menor que la fecha de inicio.');
      return;
    }

    this.procesandoAprobacion = true;

    const fechaFinNormalizada =
      soloFechaFin && soloFechaFin >= soloFechaInicio ? soloFechaFin : null;

    const payload: any = {
      nombreEvento: this.datosEvento.nombreEvento,
      idTipoEvento: Number(this.datosEvento.idTipoEvento),
      fechaEvento: soloFechaInicio,
      fechaFin: fechaFinNormalizada,
      fechaFinEvento: fechaFinNormalizada,
      lugar: this.datosEvento.lugar,
      numeroInvitados: this.entradaLibre ? 0 : Number(this.datosEvento.numeroInvitados),
      idUsuarioCoordinador: Number(this.datosEvento.idUsuarioCoordinador),
      numeroCuotas: Number(this.datosEvento.numeroCuotas)
    };

    this.cotizacionService
      .aprobarCotizacion(this.cotizacion.idCotizacion, payload)
      .subscribe({
        next: (res: any) => {
          if (!this.archivoFotoEvento) {
            this.finalizarAprobacionYRedirigir();
            return;
          }

          const archivo = this.archivoFotoEvento;
          const idEventoDirecto = Number(
            res?.idEvento ?? res?.evento?.idEvento ?? 0
          );

          if (idEventoDirecto > 0) {
            this.eventoService
              .subirFotoEvento(idEventoDirecto, archivo)
              .subscribe({
                next: () => this.finalizarAprobacionYRedirigir(),
                error: () => this.finalizarAprobacionYRedirigir()
              });
          } else {
            this.eventoService.obtenerEventos().subscribe({
              next: (eventos) => {
                const ultimoId = eventos.reduce(
                  (max, ev) => (ev.idEvento > max ? ev.idEvento : max),
                  0
                );
                if (ultimoId > 0) {
                  this.eventoService
                    .subirFotoEvento(ultimoId, archivo)
                    .subscribe({
                      next: () => this.finalizarAprobacionYRedirigir(),
                      error: () => this.finalizarAprobacionYRedirigir()
                    });
                } else {
                  this.finalizarAprobacionYRedirigir();
                }
              },
              error: () => this.finalizarAprobacionYRedirigir()
            });
          }
        },
        error: (err: any) => {
          console.error('Error completo del servidor:', err);
          this.procesandoAprobacion = false;

          this.avisoFechaOcupada =
            'Esta fecha ya está siendo ocupada por otro evento. Es necesario cambiarla o cotizar otra vez.';

          if (err.error && typeof err.error === 'string') {
            this.mensajeErrorAprobacion = err.error;
          } else if (err.error && err.error.error) {
            this.mensajeErrorAprobacion = err.error.error;
          } else if (err.error && err.error.mensaje) {
            this.mensajeErrorAprobacion = err.error.mensaje;
          } else {
            this.mensajeErrorAprobacion =
              'Ocurrió un error al verificar la disponibilidad de inventario.';
          }

          alert('Atención: ' + this.mensajeErrorAprobacion);
        }
      });
  }

  abrirModalRechazo() {
    const modal = document.getElementById('modal_rechazar') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalRechazo() {
    const modal = document.getElementById('modal_rechazar') as HTMLDialogElement;
    if (modal) modal.close();
  }

  confirmarRechazo() {
    if (!this.cotizacion) return;

    this.cotizacionService
      .rechazarCotizacion(this.cotizacion.idCotizacion)
      .subscribe({
        next: () => {
          this.cerrarModalRechazo();
          this.cargarDetalles(this.cotizacion!.idCotizacion);
        },
        error: (err: any) => {
          console.error('Error al rechazar cotización:', err);
          alert('Hubo un error al rechazar la cotización.');
        }
      });
  }

  descargarPDF() {
    if (!this.cotizacion) return;
    this.generandoPDF = true;
    try {
      this.cotizacionPdfService.generarYDescargar(this.cotizacion);
    } finally {
      this.generandoPDF = false;
    }
  }

  onToggleEntradaLibre() {
    if (this.entradaLibre) {
      if (this.datosEvento.numeroInvitados > 0) {
        this.ultimoNumeroInvitados = this.datosEvento.numeroInvitados;
      }
      this.datosEvento.numeroInvitados = 0;
    } else {
      this.datosEvento.numeroInvitados =
        this.ultimoNumeroInvitados > 0 ? this.ultimoNumeroInvitados : 50;
    }
  }

  get duracionDias(): number {
    if (!this.datosEvento.fechaEvento || !this.fechaFinEvento) return 1;
    const inicio = new Date(this.datosEvento.fechaEvento.split('T')[0] + 'T00:00:00');
    const fin = new Date(this.fechaFinEvento.split('T')[0] + 'T00:00:00');
    if (isNaN(inicio.getTime()) || isNaN(fin.getTime()) || fin < inicio) return 1;
    const diff = Math.round((fin.getTime() - inicio.getTime()) / 86400000);
    return diff + 1;
  }

  get especificacionesCotizacion(): {
    concepto: string;
    cantidad: number;
    observaciones: string;
  }[] {
    if (!this.cotizacion) return [];

    const externos = (this.cotizacion.serviciosExternos || [])
      .filter((se: any) => String(se?.observaciones || '').trim().length > 0 || Number(se?.cantidad || 0) > 1)
      .map((se: any) => ({
        concepto: se.nombreServicioProveedor || 'Servicio externo',
        cantidad: Number(se.cantidad || 1),
        observaciones: String(se.observaciones || '').trim()
      }));

    const internos = (this.cotizacion.serviciosInternos || [])
      .filter((si: any) => Number(si?.cantidad || 0) > 1)
      .map((si: any) => ({
        concepto: si.nombreServicio || 'Servicio interno',
        cantidad: Number(si.cantidad || 1),
        observaciones: ''
      }));

    return [...externos, ...internos];
  }
}