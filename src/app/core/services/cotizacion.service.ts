import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

// --- INTERFACES DE LECTURA (GET) ---
export interface CotizacionDetalleLectura {
  idDetalle: number;
  idServicio: number;
  nombreServicio: string;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
}

export interface CotizacionProveedorLectura {
  idCotizacionProveedor: number;
  idServicioProveedor: number;
  nombreServicioProveedor: string;
  nombreEmpresaProveedor: string;
  cantidad: number;
  precioCotizado: number;
  observaciones?: string;
  subtotal: number;
}

export interface CotizacionLectura {
  idCotizacion: number;
  idCliente: number;
  nombreClienteCompleto: string;
  fecha: string; // DateOnly llega como string (ej. '2026-10-03')
  estado: string;
  total: number;
  serviciosInternos: CotizacionDetalleLectura[];
  serviciosExternos: CotizacionProveedorLectura[];
}

// --- INTERFACES DE CREACIÓN (POST) ---
export interface CrearCotizacionDetalle {
  idServicio: number;
  cantidad: number;
  precioUnitario: number;
}

export interface CrearCotizacionProveedor {
  idServicioProveedor: number;
  cantidad: number;
  precioCotizado: number;
  observaciones?: string;
}

export interface CrearCotizacion {
  idCliente: number;
  serviciosInternos: CrearCotizacionDetalle[];
  serviciosExternos: CrearCotizacionProveedor[];
}

@Injectable({
  providedIn: 'root'
})
export class CotizacionService {
  private http = inject(HttpClient);
  private apiUrl = 'https://localhost:7106/api/cotizaciones';

  obtenerCotizaciones(): Observable<CotizacionLectura[]> {
    return this.http.get<CotizacionLectura[]>(this.apiUrl);
  }

  obtenerCotizacionPorId(id: number): Observable<CotizacionLectura> {
    return this.http.get<CotizacionLectura>(`${this.apiUrl}/${id}`);
  }

  crearCotizacion(cotizacion: CrearCotizacion): Observable<any> {
    return this.http.post(this.apiUrl, cotizacion);
  }

  aprobarCotizacion(id: number, datos: AprobarCotizacion): Observable<any> {
  return this.http.post(`${this.apiUrl}/${id}/aprobar`, datos);
}

rechazarCotizacion(id: number): Observable<any> {
  return this.http.post(`${this.apiUrl}/${id}/rechazar`, {});
}


obtenerTiposEvento(): Observable<{ idTipoEvento: number; nombre: string }[]> {
  return this.http.get<{ idTipoEvento: number; nombre: string }[]>(`${this.apiUrl}/tipos-evento`);
}
  
}
export interface AprobarCotizacion {
  nombreEvento: string;
  idTipoEvento: number;
  fechaEvento: string;
  lugar: string;
  numeroInvitados: number;
  idUsuarioCoordinador: number;
  numeroCuotas: number;
}