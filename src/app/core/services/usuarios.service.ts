import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface RolItem {
  idRol: number;
  nombre: string;
}

export interface CrearUsuarioPayload {
  nombre: string;
  apellidoPaterno: string;
  apellidoMaterno?: string | null;
  correo: string;
  contrasenia: string;
  idRol: number;
  activo: boolean;
}

export interface UsuarioItem {
  idUsuario: number;
  nombre: string;
  apellidoPaterno: string;
  apellidoMaterno?: string | null;
  correo: string;
  activo: boolean;
  idRol: number;
  nombreRol: string;
  fotoUrl?: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class UsuariosService {
  private http = inject(HttpClient);
  private baseUrl = `${environment.apiUrl}/api/usuarios`;

  obtenerRoles(): Observable<RolItem[]> {
    return this.http.get<RolItem[]>(`${this.baseUrl}/roles`);
  }

  obtenerUsuarios(): Observable<UsuarioItem[]> {
    return this.http.get<UsuarioItem[]>(this.baseUrl);
  }

  crearUsuario(payload: CrearUsuarioPayload): Observable<any> {
    return this.http.post<any>(this.baseUrl, payload);
  }

  cambiarEstadoUsuario(idUsuario: number, activo: boolean): Observable<any> {
    return this.http.patch<any>(`${this.baseUrl}/${idUsuario}/estado`, { activo });
  }

  cambiarContraseniaUsuario(idUsuario: number, nuevaContrasenia: string): Observable<any> {
  return this.http.patch<any>(`${this.baseUrl}/${idUsuario}/contrasenia`, { nuevaContrasenia });
}
}