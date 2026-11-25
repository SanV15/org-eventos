import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface RegistrarPagoCliente {
  idCuota: number;
  montoPagado: number;
  metodoPago: string;
  fechaPago: string;
}

export interface RegistrarPagoProveedor {
  idEventoProveedor: number;
  montoPagado: number;
  metodoPago: string;
  fechaPago: string;
}

@Injectable({
  providedIn: 'root'
})
export class FinanzasService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/api/finanzas`;

  registrarPagoCliente(pago: RegistrarPagoCliente): Observable<any> {
    return this.http.post(`${this.apiUrl}/cliente`, pago);
  }

  registrarPagoProveedor(pago: RegistrarPagoProveedor): Observable<any> {
    return this.http.post(`${this.apiUrl}/proveedor`, pago);
  }

  obtenerEstadoCuenta(idContrato: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/contrato/${idContrato}/estado-cuenta`);
  }

  obtenerEstadoCuentaPorCliente(idCliente: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/cliente/${idCliente}/estado-cuenta`);
  }

  obtenerTodosLosContratos(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/contratos`);
  }

  obtenerResumenFinanciero(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/resumen`);
  }

  obtenerCobranzaActiva(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/cobranza-activa`);
  }

  obtenerFlujoCaja(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/flujo-caja`);
  }

  obtenerProveedoresPendientes(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/proveedores-pendientes`);
  }
  
crearIntentPago(monto: number): Observable<any> {
  return this.http.post<any>(`${this.apiUrl}/crear-intent-pago`, { monto });
}

obtenerMisEventosCliente(): Observable<any[]> {
  return this.http.get<any[]>(`${this.apiUrl}/mis-eventos`);
}

crearSetupIntent(): Observable<any> {
  return this.http.post<any>(`${this.apiUrl}/crear-setup-intent`, {});
}

}