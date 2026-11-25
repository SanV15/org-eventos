import { Injectable } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { Subject } from 'rxjs';

export interface CambioEstadoTarea {
  idTarea: number;
  idEvento: number;
  nuevoEstado: string;
}

export interface IncidenciaReportada {
  idTarea: number;
  idEvento: number;
  nombreTarea: string;
  observaciones: string;
  fotoUrl?: string;
  fechaHora?: string;
}

export interface TareaDetalleEditada {
  idTarea: number;
  idEvento: number;
  nombre: string;
  descripcion: string;
  fechaLimite: string;
  estado: string;
  observaciones?: string;
}

@Injectable({
  providedIn: 'root'
})
export class SignalRService {
  private hubConnection!: signalR.HubConnection;

  // Observables para que los componentes se suscriban a los eventos
  public tareaActualizada$ = new Subject<CambioEstadoTarea>();
  public incidenciaReportada$ = new Subject<IncidenciaReportada>();
  public tareaEditada$ = new Subject<TareaDetalleEditada>(); // <-- NUEVO CANAL DE EVENTOS
  // 1. Añade estos dos Subjects junto a los que ya tienes
  public tareaCreada$ = new Subject<void>();
  public tareaEliminada$ = new Subject<void>();

  public iniciarConexion(token: string): Promise<void> {
    // Apunta a localhost en el navegador web para evitar problemas de túneles caídos
    const hubUrl = 'https://localhost:7106/hubs/eventos';

    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, {
        accessTokenFactory: () => token,
        skipNegotiation: false,
        transport: signalR.HttpTransportType.WebSockets
      })
      .withAutomaticReconnect()
      .build();

    this.registrarEscuchadores();

    return this.hubConnection
      .start()
      .then(() => console.log('Conexión con SignalR establecida exitosamente.'))
      .catch(err => console.error('Error al conectar con SignalR:', err));
  }

  public unirseAEvento(idEvento: number): void {
    if (this.hubConnection && this.hubConnection.state === signalR.HubConnectionState.Connected) {
      this.hubConnection.invoke('UnirseAEvento', idEvento)
        .catch(err => console.error('Error al unirse al grupo del evento:', err));
    }
  }

  public salirDeEvento(idEvento: number): void {
    if (this.hubConnection && this.hubConnection.state === signalR.HubConnectionState.Connected) {
      this.hubConnection.invoke('SalirDeEvento', idEvento)
        .catch(err => console.error('Error al salir del grupo del evento:', err));
    }
  }

  private registrarEscuchadores(): void {

    // 2. Añade los nuevos escuchadores de Hub
    this.hubConnection.on('TareaCreada', () => {
      this.tareaCreada$.next();
    });

    this.hubConnection.on('TareaEliminada', () => {
      this.tareaEliminada$.next();
    });

    // 1. Escuchar actualización de estado
    this.hubConnection.on('TareaEstadoActualizada', (data: CambioEstadoTarea) => {
      this.tareaActualizada$.next(data);
    });

    // 2. Escuchar reportes de incidencias
    this.hubConnection.on('IncidenciaReportada', (data: IncidenciaReportada) => {
      this.incidenciaReportada$.next(data);
    });

    // 3. NUEVO: Escuchar cambios de edición (nombre, descripción, fecha, etc.)
    this.hubConnection.on('TareaEditada', (data: TareaDetalleEditada) => {
      this.tareaEditada$.next(data);
    });
  }

  public desconectar(): void {
    if (this.hubConnection) {
      this.hubConnection.stop();
    }
  }

  
}