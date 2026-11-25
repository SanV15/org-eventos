import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { EventoService } from '../../../core/services/evento.service'; // 👈 Asegúrate de ajustar la ruta según la ubicación real de tu servicio
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-listado-eventos',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, BreadcrumbsComponent],
  templateUrl: './listado-eventos.component.html'
})
export class ListadoEventosComponent implements OnInit {
  eventosOriginales: any[] = [];
  eventosFiltrados: any[] = [];
  cargando: boolean = true;
  filtroNombre: string = '';
  filtroFecha: string = '';
  filtroEstado: string = 'TODOS';

  // Inyectamos el Router y el nuevo EventoService de forma moderna con inject() o constructor
  private http = inject(HttpClient);
  private router = inject(Router);
  private eventoService = inject(EventoService); // 👈 Inyección del servicio de eventos

  ngOnInit(): void {
    this.cargarEventos();
  }

  cargarEventos(): void {
    this.cargando = true;
    this.eventoService.obtenerEventos().subscribe({
      next: (datos: any[]) => {
        this.eventosOriginales = datos;
        this.eventosFiltrados = datos;
        this.cargando = false;
        this.eventosOriginales = this.ordenarEventosInteligente(datos);
        this.aplicarFiltros();
      },
      error: (err: any) => {
        console.error('Error al cargar eventos', err);
        this.cargando = false;
      }
    });
  }

  // 🧠 Lógica de ordenamiento por prioridad de estado
  ordenarEventosInteligente(lista: any[]): any[] {
    return lista.sort((a, b) => {
      const prioridad = (estado: string) => {
        switch (estado) {
          case 'Pendiente': return 1;
          case 'En planificación': return 2;
          case 'Activo':
          case 'Confirmado': return 3;
          case 'Finalizado': return 4;
          case 'Cancelado': return 5; // Siempre al final
          default: return 6;
        }
      };
      return prioridad(a.estado) - prioridad(b.estado);
    });
  }

  seleccionarFiltroEstado(estado: string) {
    this.filtroEstado = estado;
    this.aplicarFiltros();
  }

cancelarEvento(evento: any) {
    const confirmar = confirm(`¿Estás seguro de cancelar el evento "${evento.nombreEvento}" de ${evento.cliente}?\n\nAl hacerlo, se liberarán de inmediato todos los proveedores y servicios asignados.`);
    
    if (!confirmar) return;

    this.eventoService.cancelarEvento(evento.idEvento).subscribe({
      next: () => {
        alert('Evento cancelado correctamente. Recursos liberados.');
        this.cargarEventos(); 
      },
      error: (err) => {
        console.error('Error al cancelar el evento:', err);
        alert(err.error?.mensaje || 'Ocurrió un error al intentar cancelar el evento.');
      }
    });
  }


aplicarFiltros(): void {
    this.eventosFiltrados = this.eventosOriginales.filter(evento => {
      // 1. Filtro por nombre o cliente
      const nombreOCliente = `${evento.nombreEvento} ${evento.cliente}`.toLowerCase();
      const coincideNombre = nombreOCliente.includes(this.filtroNombre.toLowerCase());
      
      // 2. Filtro por fecha seleccionada
      const coincideFecha = this.filtroFecha ? 
                            evento.fechaEvento.startsWith(this.filtroFecha) : true;

      // 3. Filtro por pestañas (Tabs) limpias
      let coincideEstado = true;
      
      if (this.filtroEstado === 'Pendiente') {
        coincideEstado = evento.estado === 'Pendiente';
      } 
      else if (this.filtroEstado === 'En planificación') {
        coincideEstado = evento.estado === 'En planificación';
      } 
      else if (this.filtroEstado === 'Cancelado') {
        coincideEstado = evento.estado === 'Cancelado';
      }

      return coincideNombre && coincideFecha && coincideEstado;
    });
  }

  limpiarFiltros(): void {
    this.filtroNombre = '';
    this.filtroFecha = '';
    this.filtroEstado = 'TODOS';
    this.eventosFiltrados = [...this.eventosOriginales];
  }

  // LÓGICA DE VALIDACIÓN ANTES DE NAVEGAR AL CRONOGRAMA
irAPlanificador(evento: any): void {
    if (evento.estado === 'Cancelado') return;
    
    if (evento.estado === 'Pendiente') {
      const irAPagos = confirm(
        `El evento "${evento.nombreEvento}" tiene un contrato pendiente de anticipo.\n\n¿Deseas ir al estado de cuenta de ${evento.cliente} para registrar el abono y activar el contrato?`
      );
      
      if (irAPagos) {
        // Redirige a la pantalla de finanzas/estado de cuenta del cliente
        this.router.navigate(['/clientes', evento.idCliente, 'finanzas']);
      }
      return;
    }

    const fechaEvento = new Date(evento.fechaEvento);
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0); 

    if (fechaEvento < hoy) {
      alert('La fecha de este evento ya expiró. No es posible planificar logística en el pasado.');
      return;
    }

    this.router.navigate(['/eventos', evento.idEvento, 'planificador']);
  }
}