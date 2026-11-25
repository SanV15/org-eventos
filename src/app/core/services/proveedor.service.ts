import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Categoria {
  idCategoria: number;
  nombre: string;
}

export interface ProveedorRegistro {
  nombre: string;
  apellidoPaterno?: string;
  apellidoMaterno?: string;
  telefono?: string;
  correo?: string;
  direccion?: string;
  descripcion?: string;
  banco?: string;
  clabeInterbancaria?: string;
  titularCuenta?: string;
  categoriasIds: number[];
  fotoProveedorUrl?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ProveedorService {
  private http = inject(HttpClient);
  // Asegúrate de que el puerto coincida con tu API
  private apiUrl = 'https://localhost:7106/api/proveedores'; 

  obtenerCategorias(): Observable<Categoria[]> {
    return this.http.get<Categoria[]>(`${this.apiUrl}/categorias`);
  }

  registrar(proveedor: ProveedorRegistro): Observable<any> {
    return this.http.post(`${this.apiUrl}/registrar`, proveedor);
  }

  obtenerProveedores(): Observable<any[]> {
    return this.http.get<any[]>(this.apiUrl);
  }

  cambiarEstado(idProveedor: number, activo: boolean): Observable<any> {
  return this.http.put(`${this.apiUrl}/${idProveedor}/estado`, { activo });
}

obtenerProveedorPorId(idProveedor: number): Observable<ProveedorRegistro> {
  return this.http.get<ProveedorRegistro>(`${this.apiUrl}/${idProveedor}`);
}

actualizarProveedor(idProveedor: number, proveedor: ProveedorRegistro): Observable<any> {
  return this.http.put(`${this.apiUrl}/${idProveedor}`, proveedor);
}

obtenerFechasOcupadas(idProveedor: number):Observable<any[]> {
  return this.http.get<any[]>(`${this.apiUrl}/${idProveedor}/fechas-ocupadas`);
}

subirFotoProveedor(idProveedor: number, archivo: File): Observable<{ mensaje: string; fotoProveedorUrl: string }> {
  const formData = new FormData();
  formData.append('archivo', archivo);
  return this.http.post<{ mensaje: string; fotoProveedorUrl: string }>(
    `${environment.apiUrl}/api/proveedores/${idProveedor}/foto`,
    formData
  );
}
}