import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Observable, tap } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/api/Auth`;

  login(correo: string, contrasenia: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/login`, { correo, contrasenia }).pipe(
      tap(respuesta => {
        if (respuesta.token) {
          // Guardar el token para usarlo en futuras peticiones
          localStorage.setItem('token', respuesta.token);
        }
      })
    );
  }

  logout(): void {
    localStorage.removeItem('token');
  }

  estaAutenticado(): boolean {
    return !!localStorage.getItem('token');
  }

  // Agrega este método dentro de tu clase AuthService
obtenerRol(): string | null {
  const token = localStorage.getItem('token');
  if (!token) return null;

  try {
    // El token JWT tiene 3 partes separadas por puntos. La del medio (payload) tiene los datos.
    const payload = JSON.parse(atob(token.split('.')[1]));
    
    // C# por defecto guarda los roles bajo esta key larga, o como 'role'
    return payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] || payload.role || null;
  } catch (error) {
    return null;
  }
}

obtenerNombreUsuario(): string {
    const token = localStorage.getItem('token');
    if (!token) return 'Cliente'; // Valor por defecto si no hay token

    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      // Busca el claim "nombre_completo" que inyectamos desde C#
      return payload['nombre_completo'] || payload.unique_name || 'Cliente';
    } catch (error) {
      return 'Cliente';
    }
  }

obtenerIdCliente(): string | null {
    const token = localStorage.getItem('token');
    if (!token) return null;

    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      // Busca el claim donde guardas el id del cliente (puede ser 'id_cliente', 'clienteId' o 'id')
      return payload['id_cliente'] || payload['clienteId'] || payload['id'] || null;
    } catch (error) {
      return null;
    }
  }
}

