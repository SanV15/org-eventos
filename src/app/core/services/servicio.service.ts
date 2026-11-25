import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ServicioRegistro {
  nombre: string;
  descripcion: string;
  precio: number;
}

export interface ServicioListado {
  idServicio: number;
  nombre: string;
  descripcion: string;
  precio: number;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ServicioService {
  private http = inject(HttpClient);
  private apiUrl = 'https://localhost:7106/api/servicios';

  obtenerServicios(): Observable<ServicioListado[]> {
    return this.http.get<ServicioListado[]>(this.apiUrl);
  }

  agregarServicio(servicio: ServicioRegistro): Observable<any> {
    return this.http.post(this.apiUrl, servicio);
  }

  actualizarServicio(idServicio: number, servicio: ServicioRegistro): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idServicio}`, servicio);
  }

  cambiarEstado(idServicio: number, activo: boolean): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idServicio}/estado`, { activo });
  }
}