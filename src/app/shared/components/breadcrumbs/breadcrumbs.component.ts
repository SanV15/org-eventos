import { Component, inject, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  Router,
  RouterLink,
  Routes,
  NavigationEnd
} from '@angular/router';
import { filter, pairwise, startWith, Subscription } from 'rxjs';
import { routes } from '../../../app.routes';

export interface BreadcrumbItem {
  label: string;
  url: string;
}

@Component({
  selector: 'app-breadcrumbs',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './breadcrumbs.component.html',
  styleUrl: './breadcrumbs.component.scss'
})
export class BreadcrumbsComponent implements OnDestroy {
  private router = inject(Router);
  private sub: Subscription;

  readonly items = signal<BreadcrumbItem[]>([]);

  constructor() {
    this.actualizarBreadcrumbs(null, this.router.url);

    this.sub = this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        startWith(null),
        pairwise()
      )
      .subscribe(([anterior, actual]) => {
        if (!actual) return;
        const urlAnterior = anterior ? anterior.urlAfterRedirects : null;
        this.actualizarBreadcrumbs(urlAnterior, actual.urlAfterRedirects);
      });
  }

  private actualizarBreadcrumbs(urlAnteriorRaw: string | null, urlActualRaw: string): void {
    const actual = this.limpiarUrl(urlActualRaw);
    const anterior = urlAnteriorRaw ? this.limpiarUrl(urlAnteriorRaw) : null;

    if (actual === '/dashboard') {
      this.items.set([{ label: 'Panel de Control', url: '/dashboard' }]);
      return;
    }

    const entradaActual = this.buscarRutaPorUrl(routes, actual);
    const etiquetaActual = entradaActual?.data?.['breadcrumb'] ?? this.formatearSegmento(actual);

    const cadena: BreadcrumbItem[] = [
      { label: 'Panel de Control', url: '/dashboard' }
    ];

    // 1. Si venimos de otra pantalla válida dentro de la app (distinta de dashboard, login y la misma actual),
    // usamos esa ruta anterior real como paso intermedio.
    let rutaIntermedia: string | null = null;
    if (
      anterior &&
      anterior !== actual &&
      anterior !== '/dashboard' &&
      anterior !== '/login'
    ) {
      rutaIntermedia = anterior;
    } else {
      // 2. Fallback si se recargó la página o se entró directo por URL
      const parentUrlExplicit = entradaActual?.data?.['parentUrl'] as string | undefined;
      rutaIntermedia = parentUrlExplicit ?? this.deducirRutaPadre(routes, actual);
    }

    if (rutaIntermedia && rutaIntermedia !== actual && rutaIntermedia !== '/dashboard') {
      const entradaIntermedia = this.buscarRutaPorUrl(routes, rutaIntermedia);
      const etiquetaIntermedia =
        entradaIntermedia?.data?.['breadcrumb'] ?? this.formatearSegmento(rutaIntermedia);
      cadena.push({ label: etiquetaIntermedia, url: rutaIntermedia });
    }

    cadena.push({ label: etiquetaActual, url: actual });
    this.items.set(cadena);
  }

  private limpiarUrl(url: string): string {
    const sinQuery = url.split('?')[0].split('#')[0];
    return sinQuery === '/' ? '/dashboard' : sinQuery;
  }

  private buscarRutaPorUrl(lista: Routes, url: string): any {
    const segmentosUrl = url.replace(/^\/+/, '').split('/').filter(Boolean);

    for (const r of lista) {
      if (!r.path) continue;
      const segRuta = r.path.split('/').filter(Boolean);

      if (segRuta.length !== segmentosUrl.length) continue;

      const coincide = segRuta.every((parte, idx) => {
        if (parte.startsWith(':')) return true;
        return parte === segmentosUrl[idx];
      });

      if (coincide) return r;
    }

    return null;
  }

  private deducirRutaPadre(lista: Routes, urlActual: string): string | null {
    const candidatos = lista
      .map((r) => r.path ?? '')
      .filter((p) => p && !p.includes(':') && !p.includes('*') && p !== 'dashboard' && p !== 'login')
      .map((p) => '/' + p.replace(/^\/+/, ''))
      .sort((a, b) => b.length - a.length);

    for (const base of candidatos) {
      if (urlActual.startsWith(base + '/')) {
        return base;
      }
    }

    return null;
  }

  private formatearSegmento(url: string): string {
    const ultimo = url.split('/').filter(Boolean).pop() ?? 'Vista';
    return ultimo
      .replace(/-/g, ' ')
      .replace(/\b\w/g, (letra) => letra.toUpperCase());
  }

  ngOnDestroy(): void {
    this.sub.unsubscribe();
  }
}