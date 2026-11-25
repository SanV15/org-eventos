import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { TemaService } from '../../core/services/tema.service';
import { BreadcrumbsComponent } from '../../shared/components/breadcrumbs/breadcrumbs.component';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './dashboard.component.html'
})
export class DashboardComponent implements OnInit {
  private http = inject(HttpClient);
  private router = inject(Router);
  readonly temaService = inject(TemaService);
  private authService = inject(AuthService);
  
  nombreUsuario: string = this.obtenerNombreUsuario();
rolUsuario: string = this.authService.obtenerRol() ?? '';
esAdministrador: boolean = this.rolUsuario.toLowerCase() === 'administrador';

  resumen: any = {
    eventosActivos: 0,
    eventosEsteMes: 0,
    tareasPendientes: 0,
    cotizacionesPendientes: 0,
    proximosEventos: []
  };
  cargando: boolean = true;

ngOnInit(): void {
  console.log('Rol desde AuthService:', this.authService.obtenerRol());
  console.log('esAdministrador:', this.esAdministrador);
  this.cargarResumen();
}

  private obtenerNombreUsuario(): string {
  const directo = localStorage.getItem('nombreUsuario') || localStorage.getItem('nombre');
  if (directo && directo.trim() && !directo.includes('@')) {
    return directo.trim();
  }

  const usuarioRaw = localStorage.getItem('usuario');
  if (usuarioRaw) {
    try {
      const parsed = JSON.parse(usuarioRaw);
      const full = `${parsed?.nombre ?? ''} ${parsed?.apellidoPaterno ?? ''}`.trim();
      if (full) return full;
      if (parsed?.nombre_completo) return String(parsed.nombre_completo).trim();
    } catch {
      // Ignorar si no es JSON válido
    }
  }

  const token = localStorage.getItem('token');
  if (token && token.split('.').length === 3) {
    try {
      const payloadBase64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
      const payload = JSON.parse(atob(payloadBase64));
      const nombreClaim = payload?.nombre_completo || payload?.nombre || payload?.name || '';
      if (typeof nombreClaim === 'string' && nombreClaim.trim()) {
        return nombreClaim.trim();
      }
    } catch {
      // Ignorar si no se puede decodificar
    }
  }

  return 'Usuario';
}

  private obtenerRolUsuario(): string {
    const directo =
      localStorage.getItem('rol') ||
      localStorage.getItem('role') ||
      localStorage.getItem('nombreRol');

    if (directo && directo.trim()) {
      return directo.trim();
    }

    const usuarioRaw = localStorage.getItem('usuario');
    if (usuarioRaw) {
      try {
        const parsed = JSON.parse(usuarioRaw);
        const rolObj = parsed?.rol ?? parsed?.role ?? parsed?.nombreRol ?? '';
        if (typeof rolObj === 'string' && rolObj.trim()) return rolObj.trim();
        if (typeof rolObj === 'object' && rolObj?.nombre) return String(rolObj.nombre).trim();
      } catch {
        // Ignorar si no es JSON válido
      }
    }

    const token = localStorage.getItem('token');
    if (token && token.split('.').length === 3) {
      try {
        const payloadBase64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
        const payload = JSON.parse(atob(payloadBase64));
        const rolToken =
          payload?.role ||
          payload?.rol ||
          payload?.['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ||
          '';
        if (typeof rolToken === 'string' && rolToken.trim()) {
          return rolToken.trim();
        }
      } catch {
        // Ignorar si el token no es un JWT decodificable
      }
    }

    return '';
  }

  

  cargarResumen() {
    this.cargando = true;
    this.http.get<any>(`${environment.apiUrl}/api/dashboard/resumen`).subscribe({
      next: (data) => {
        this.resumen = {
          eventosActivos: data?.eventosActivos ?? 0,
          eventosEsteMes: data?.eventosEsteMes ?? 0,
          tareasPendientes: data?.tareasPendientes ?? 0,
          cotizacionesPendientes: data?.cotizacionesPendientes ?? 0,
          proximosEventos: Array.isArray(data?.proximosEventos) ? data.proximosEventos : []
        };
        this.cargando = false;
      },
      error: (err) => {
        console.error('Error al cargar datos del dashboard:', err);
        this.cargando = false;
      }
    });
  }

  irAlPlanificador(evento: any): void {
    console.log('Objeto evento recibido del Dashboard:', evento);

    const id = evento.idEvento || evento.IdEvento;
    const idCliente = evento.idCliente || evento.IdCliente;

    if (evento.estado === 'Pendiente') {
      const irAPagos = confirm(
        `El evento "${evento.nombreEvento || evento.nombre}" tiene un contrato pendiente de anticipo.\n\n¿Deseas ir al estado de cuenta para registrar el abono?`
      );
      if (irAPagos) {
        if (!idCliente) {
          alert('El evento no cuenta con un ID de cliente válido. Revisa la consola para ver los datos.');
          return;
        }
        this.router.navigate(['/clientes', idCliente, 'finanzas']);
      }
      return;
    }

    if (evento.estado === 'Cancelado') {
      alert('Este evento se encuentra cancelado y no permite planificación.');
      return;
    }

    this.router.navigate(['/eventos', id, 'planificador']);
  }

  cerrarSesion() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }
}