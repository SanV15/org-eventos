import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

// 1. Agregamos la interfaz para el listado aquí arriba
export interface ClienteListado {
  idCliente: number;
  nombreCompleto: string;
  correoContacto: string;
  telefono: string;
  activo: boolean;
  fechaRegistro: string;
}

@Injectable({
  providedIn: 'root'
})
export class ClienteService {
  private http = inject(HttpClient);
  // Ajusta esta URL a la que estés usando actualmente
  private apiUrl = 'https://localhost:7106/api/clientes'; 

  // ==========================================
  // ESTE ES TU MÉTODO ACTUAL (No lo toques)
  // ==========================================
  registrarCliente(clienteData: any): Observable<any> {
    return this.http.post(`${this.apiUrl}`, clienteData); 
  }

  // ==========================================
  // LOS 2 MÉTODOS NUEVOS PARA LA TABLA
  // ==========================================
  obtenerClientes(): Observable<ClienteListado[]> {
    return this.http.get<ClienteListado[]>(this.apiUrl);
  }

  cambiarEstado(idCliente: number, activo: boolean): Observable<any> {
    // Mandamos el nuevo estado al backend
    return this.http.put(`${this.apiUrl}/${idCliente}/estado`, { activo });
  }

  obtenerClientePorId(idCliente: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/${idCliente}`);
  }

  actualizarCliente(idCliente: number, datos: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idCliente}`, datos);
  }
}