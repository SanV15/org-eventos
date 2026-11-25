import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface EventoListado {
  idEvento: number;
  cliente: string;
  nombreEvento: string;
  fechaEvento: string;
  estado: string;
  fotoEventoUrl?: string;
}

@Injectable({
  providedIn: 'root'
})
export class EventoService {
  private http = inject(HttpClient);
  private apiUrl = 'https://localhost:7106/api/eventos';

  obtenerEventos(): Observable<EventoListado[]> {
    return this.http.get<EventoListado[]>(this.apiUrl);
  }

  cancelarEvento(idEvento: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/${idEvento}/cancelar`, {});
  }

  subirFotoEvento(
    idEvento: number,
    archivo: File
  ): Observable<{ mensaje: string; fotoEventoUrl: string }> {
    const formData = new FormData();
    formData.append('archivo', archivo);
    return this.http.post<{ mensaje: string; fotoEventoUrl: string }>(
      `${this.apiUrl}/${idEvento}/foto`,
      formData
    );
  }
}