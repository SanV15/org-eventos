import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ServicioProveedorRegistro {
  nombreServicio: string;
  descripcion: string;
  costo: number;
}

export interface ServicioProveedorListado {
  idServicioProveedor: number;
  nombreServicio: string;
  descripcion?: string;
  costo: number;
  activo: boolean;
  // 👈 Agrégalas aquí para que TypeScript las reconozca en la tabla:
  estaOcupadoHoy?: boolean;
  nombreEventoActual?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ServicioProveedorService {
  private http = inject(HttpClient);
  private apiUrl = 'https://localhost:7106/api/serviciosproveedor'; // Verifica tu puerto

  obtenerServiciosPorProveedor(idProveedor: number): Observable<ServicioProveedorListado[]> {
    return this.http.get<ServicioProveedorListado[]>(`${this.apiUrl}/proveedor/${idProveedor}`);
  }

  agregarServicio(idProveedor: number, servicio: ServicioProveedorRegistro): Observable<any> {
    return this.http.post(`${this.apiUrl}/proveedor/${idProveedor}`, servicio);
  }

  actualizarServicio(idServicio: number, servicio: ServicioProveedorRegistro): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idServicio}`, servicio);
  }

  cambiarEstado(idServicio: number, activo: boolean): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idServicio}/estado`, { activo });
  }
}