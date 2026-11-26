import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface RegistrarPagoCliente {
  idCuota: number;
  montoPagado: number;
  metodoPago: string;
  fechaPago: string;
  referencia?: string;
}

export interface RegistrarPagoProveedor {
  idEventoProveedor: number;
  montoPagado: number;
  metodoPago: string;
  fechaPago: string;
  referencia?: string;
}

export interface ResumenFinanciero {
  totalEnCaja: number;
  cuentasPorCobrar: number;
  egresosTotales: number;
  margenBruto?: number;
}

export interface Transaccion {
  fecha: string;
  tipo: 'Ingreso' | 'Egreso' | string;
  entidad: string;
  concepto: string;
  monto: number;
  referencia?: string;
  metodoPago?: string;
}

export interface CobranzaActiva {
  idContrato: number;
  idCliente: number;
  cliente: string;
  nombreEvento: string;
  totalContrato: number;
  saldoPendiente: number;
  proximoVencimiento?: string | null;
  estadoMorosidad?: string;
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

  obtenerResumenFinanciero(): Observable<ResumenFinanciero> {
    return this.http.get<ResumenFinanciero>(`${this.apiUrl}/resumen`);
  }

  obtenerCobranzaActiva(): Observable<CobranzaActiva[]> {
    return this.http.get<CobranzaActiva[]>(`${this.apiUrl}/cobranza-activa`);
  }

  obtenerFlujoCaja(): Observable<Transaccion[]> {
    return this.http.get<Transaccion[]>(`${this.apiUrl}/flujo-caja`);
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