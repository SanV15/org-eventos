import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { CotizacionService, CotizacionLectura } from '../../../core/services/cotizacion.service';
import { TemaService } from '../../../core/services/tema.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

type FiltroCotizacion = 'Todas' | 'Pendiente' | 'Aprobada' | 'Rechazada';

@Component({
  selector: 'app-listado-cotizaciones',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './listado-cotizaciones.component.html'
})
export class ListadoCotizacionesComponent implements OnInit {
  private cotizacionService = inject(CotizacionService);
  private router = inject(Router);
  private toastr = inject(ToastrService);
  readonly temaService = inject(TemaService);

  cotizaciones: CotizacionLectura[] = [];
  cargando: boolean = true;
  errorMensaje: string | null = null;

  filtroEstado: FiltroCotizacion = 'Todas';
  busqueda: string = '';

  // Días sin revisarse para marcar que requiere seguimiento
  private readonly diasUmbralSeguimiento = 7;

  ngOnInit(): void {
    this.cargarCotizaciones();
  }

  cargarCotizaciones(): void {
    this.cargando = true;
    this.errorMensaje = null;

    this.cotizacionService.obtenerCotizaciones().subscribe({
      next: (data: CotizacionLectura[]) => {
        this.cotizaciones = Array.isArray(data) ? data : [];
        this.cargando = false;
      },
      error: (err: any) => {
        console.error('Error al cargar el historial de cotizaciones', err);
        this.errorMensaje = err?.error?.mensaje || 'No se pudo cargar el historial de cotizaciones.';
        this.cargando = false;
      }
    });
  }

  normalizarEstado(estado: string | null | undefined): string {
    return (estado ?? '').trim().toLowerCase();
  }

  get pendientes(): CotizacionLectura[] {
    return this.cotizaciones.filter(c => this.normalizarEstado(c.estado) === 'pendiente');
  }

  get aprobadas(): CotizacionLectura[] {
    return this.cotizaciones.filter(c => this.normalizarEstado(c.estado) === 'aprobada');
  }

  get rechazadas(): CotizacionLectura[] {
    return this.cotizaciones.filter(c => this.normalizarEstado(c.estado) === 'rechazada');
  }

  get cotizacionesSeguimiento(): CotizacionLectura[] {
    return this.pendientes.filter(c => this.requiereSeguimiento(c));
  }

  diasTranscurridos(fecha: string | null | undefined): number {
    if (!fecha) return 0;
    const ms = new Date(fecha).getTime();
    if (Number.isNaN(ms)) return 0;
    const diffDias = Math.floor((Date.now() - ms) / (1000 * 60 * 60 * 24));
    return Math.max(0, diffDias);
  }

  requiereSeguimiento(cot: CotizacionLectura): boolean {
    if (this.normalizarEstado(cot.estado) !== 'pendiente') return false;
    return this.diasTranscurridos(cot.fecha) >= this.diasUmbralSeguimiento;
  }

  mensajeSeguimiento(cot: CotizacionLectura): string | null {
    const estado = this.normalizarEstado(cot.estado);
    const dias = this.diasTranscurridos(cot.fecha);

    if (estado === 'pendiente') {
      if (dias >= this.diasUmbralSeguimiento) {
        return `Hace ${dias} días sin revisarse · Requiere seguimiento`;
      }
      return dias === 0 ? 'Registrada hoy · Pendiente de revisión' : `Hace ${dias}d · Pendiente de revisión`;
    }

    if (estado === 'aprobada') {
      return 'Lista para crear evento';
    }

    return null;
  }

  get cotizacionesFiltradas(): CotizacionLectura[] {
    const q = this.busqueda.trim().toLowerCase();

    const pesoEstado = (estado: string): number => {
      const n = this.normalizarEstado(estado);
      if (n === 'pendiente') return 1;
      if (n === 'aprobada') return 2;
      if (n === 'rechazada') return 3;
      return 4;
    };

    return this.cotizaciones
      .filter(c => {
        const coincideEstado =
          this.filtroEstado === 'Todas' ||
          this.normalizarEstado(c.estado) === this.filtroEstado.toLowerCase();

        const folioStr = String(c.idCotizacion ?? '').padStart(3, '0');
        const coincideTexto =
          !q ||
          folioStr.includes(q) ||
          `#${folioStr}`.includes(q) ||
          String(c.nombreClienteCompleto ?? '').toLowerCase().includes(q);

        return coincideEstado && coincideTexto;
      })
      .sort((a, b) => {
        const segA = this.requiereSeguimiento(a) ? 0 : 1;
        const segB = this.requiereSeguimiento(b) ? 0 : 1;
        if (segA !== segB) return segA - segB;

        const estA = pesoEstado(a.estado);
        const estB = pesoEstado(b.estado);
        if (estA !== estB) return estA - estB;

        return new Date(b.fecha).getTime() - new Date(a.fecha).getTime();
      });
  }

  aprobarYCrearEvento(cot: CotizacionLectura): void {
    const folio = `#${String(cot.idCotizacion).padStart(3, '0')}`;
    this.router.navigate(['/cotizaciones', cot.idCotizacion], {
      queryParams: {
        idCliente: cot.idCliente,
        aprobar: '1'
      }
    });
  }

  crearEvento(cot: CotizacionLectura): void {
    this.router.navigate(['/eventos'], {
      queryParams: {
        idCotizacion: cot.idCotizacion,
        idCliente: cot.idCliente
      }
    });
  }
}