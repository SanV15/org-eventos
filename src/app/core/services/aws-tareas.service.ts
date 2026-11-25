import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

// Interfaz adaptada al JSON que devuelve tu Lambda en Python
export interface TareaAWS {
  idTarea?: string;
  nombre: string;
  descripcion: string;
  estado: string;
}

@Injectable({
  providedIn: 'root'
})

export class AwsTareasService {
  private apiUrl = ' https://8m35jbqrga.execute-api.us-west-2.amazonaws.com/etapa-1/tareas'; 

  constructor(private http: HttpClient) {}

  // Consultar todos
  obtenerTareas(): Observable<TareaAWS[]> {
    return this.http.get<TareaAWS[]>(this.apiUrl);
  }

  //Consultar uno
  obtenerTarea(id: string): Observable<TareaAWS> {
    return this.http.get<TareaAWS>(`${this.apiUrl}/${id}`);
  }

  //Crear
  crearTarea(tarea: TareaAWS): Observable<any> {
    return this.http.post(this.apiUrl, tarea);
  }

  //Modificar
  actualizarTarea(id: string, tarea: TareaAWS): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}`, tarea);
  }

  //Eliminar
  eliminarTarea(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}