import { Injectable, signal, effect } from '@angular/core';

export type TemaOrgEventos = 'corporate' | 'night';

@Injectable({
  providedIn: 'root'
})
export class TemaService {
  private readonly storageKey = 'orgeventos_tema';

  readonly temaActual = signal<TemaOrgEventos>(this.leerTemaInicial());

  constructor() {
    this.aplicarTemaEnDom(this.temaActual());

    effect(() => {
      const tema = this.temaActual();
      if (typeof window !== 'undefined') {
        localStorage.setItem(this.storageKey, tema);
      }
      this.aplicarTemaEnDom(tema);
    });
  }

  private leerTemaInicial(): TemaOrgEventos {
    if (typeof window === 'undefined') {
      return 'corporate';
    }
    const guardado = localStorage.getItem(this.storageKey);
    if (guardado === 'night' || guardado === 'corporate') {
      return guardado;
    }
    return 'corporate';
  }

  private aplicarTemaEnDom(tema: TemaOrgEventos): void {
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', tema);
      document.body?.setAttribute('data-theme', tema);
    }
  }

establecerTema(tema: TemaOrgEventos): void {
  this.temaActual.set(tema);
  if (typeof window !== 'undefined') {
    localStorage.setItem(this.storageKey, tema);
  }
  this.aplicarTemaEnDom(tema);
}

  alternarTema(): void {
    const siguiente: TemaOrgEventos =
      this.temaActual() === 'corporate' ? 'night' : 'corporate';
    this.establecerTema(siguiente);
  }

  esOscuro(): boolean {
    return this.temaActual() === 'night';
  }

  claseBadgeEstadoEvento(estado: string | null | undefined): string {
    const norm = (estado ?? '').trim().toLowerCase();

    switch (norm) {
      case 'en planificación':
      case 'en planificacion':
      case 'planificación':
        return 'badge-info badge-outline';
      case 'confirmado':
      case 'activo':
      case 'en curso':
      case 'liquidado':
        return 'badge-success';
      case 'pendiente':
        return 'badge-warning';
      case 'cancelado':
      case 'cancelada':
        return 'badge-error';
      case 'completado':
      case 'completada':
      case 'finalizado':
        return 'badge-neutral';
      default:
        return 'badge-primary badge-outline';
    }
  }
}