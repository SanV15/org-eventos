import { Component, OnInit, OnDestroy, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { SignalRService } from '../../../core/services/signalr.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

export interface ServicioInternoPlan {
  idServicio: number;
  nombre: string;
  descripcion: string;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
}

export interface ProveedorHorarioPlan {
  idEventoProveedor: number;
  idServicioProveedor: number;
  nombreServicio: string;
  nombreProveedor: string;
  telefonoProveedor: string;
  costoAcordado: number | null;
  estadoOperativo: string;
  horaPactada: string | null;
  horaLlegada: string | null;
  horaSalida: string | null;
  idUsuarioCheckin?: number | null;
  observaciones: string;
  evidenciaUrl: string | null;
}

export interface PlanOperativoEvento {
  idEvento: number;
  nombreEvento: string;
  fechaEvento: string;
  fechaFin: string | null;
  lugar: string;
  numeroInvitados: number;
  esEntradaLibre: boolean;
  estado: string;
  serviciosInternos: ServicioInternoPlan[];
  proveedores: ProveedorHorarioPlan[];
}

@Component({
  selector: 'app-planificador-operativo',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, BreadcrumbsComponent],
  templateUrl: './planificador-operativo.component.html'
})
export class PlanificadorOperativoComponent implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private http = inject(HttpClient);
  private signalRService = inject(SignalRService);
  private cdr = inject(ChangeDetectorRef);

  private readonly apiBase = 'https://localhost:7106/api';
  private signalRSub = new Subscription();

  // Pestañas principales: 'cronograma' | 'proveedores' | 'servicios'
  pestanaActiva: 'cronograma' | 'proveedores' | 'servicios' = 'cronograma';

  // Subvista dentro de Cronograma: 'lista' | 'kanban'
  vistaCronograma: 'lista' | 'kanban' = 'lista';

  readonly estadosKanban: string[] = ['Pendiente', 'En proceso', 'Completada', 'Cancelada'];
  readonly estadosProveedor: string[] = ['Pendiente', 'En sitio', 'Retrasado', 'Completado'];

  // Filtro por día para eventos multi-día ('todos' o 'YYYY-MM-DD')
  diaFiltro: string = 'todos';
  diasEvento: { clave: string; etiqueta: string }[] = [];

  planOperativo: PlanOperativoEvento | null = null;
  cargandoPlan: boolean = false;

  tareas: any[] = [];
  cargando: boolean = true;
  idEvento: number = 0;

  personal: any[] = [];
  nuevaTarea = {
    idEvento: 0,
    idUsuario: null as number | null,
    nombre: '',
    descripcion: '',
    fechaLimite: '',
    observaciones: ''
  };
  procesando: boolean = false;

  // Límites del calendario
  minFecha: string = '';
  maxFecha: string = '';

  // Edición de tareas
  modoEdicion: boolean = false;
  idTareaEditando: number = 0;

  // Modal operación completa de proveedor (pactada, llegada, salida, estado, usuario checkin, notas)
  proveedorEditando: ProveedorHorarioPlan | null = null;
  formProveedor = {
    horaPactada: '',
    horaLlegada: '',
    horaSalida: '',
    estadoOperativo: 'Pendiente',
    idUsuarioCheckin: null as number | null,
    observaciones: ''
  };
  guardandoProveedor: boolean = false;

  // Modal de incidencia en tarea
  tareaIncidencia: any = null;
  observacionIncidencia: string = '';
  archivoIncidencia: File | null = null;
  enviandoIncidencia: boolean = false;

  imagenModalUrl: string | null = null;

  ngOnInit(): void {
    const idUrl = this.route.snapshot.paramMap.get('id');
    if (idUrl) {
      this.idEvento = Number(idUrl);
      this.cargarDetalleEvento();
      this.cargarPlanOperativo();
      this.cargarPersonal();
      this.cargarTareas();
      this.iniciarSignalR();
    }
  }

  ngOnDestroy(): void {
    if (this.idEvento > 0) {
      this.signalRService.salirDeEvento(this.idEvento);
    }
    this.signalRSub.unsubscribe();
  }

  private iniciarSignalR(): void {
    const token = localStorage.getItem('token') || '';

    this.signalRService.iniciarConexion(token).then(() => {
      this.signalRService.unirseAEvento(this.idEvento);
    });

    this.signalRSub.add(
      this.signalRService.tareaActualizada$.subscribe((cambio) => {
        if (cambio.idEvento === this.idEvento) {
          const tarea = this.tareas.find((t) => t.idTarea === cambio.idTarea);
          if (tarea) {
            tarea.estado = cambio.nuevoEstado;
            this.cdr.detectChanges();
          }
        }
      })
    );

    this.signalRSub.add(
      this.signalRService.incidenciaReportada$.subscribe((incidencia) => {
        if (incidencia.idEvento === this.idEvento) {
          const tarea = this.tareas.find((t) => t.idTarea === incidencia.idTarea);
          if (tarea) {
            if (!tarea.incidencias) tarea.incidencias = [];
            tarea.incidencias.unshift({
              observacion: incidencia.observaciones,
              fotoUrl: incidencia.fotoUrl,
              fechaHora: incidencia.fechaHora || new Date().toISOString()
            });
            this.cdr.detectChanges();
          }
        }
      })
    );

    this.signalRSub.add(
      this.signalRService.tareaEditada$.subscribe((editada) => {
        if (editada.idEvento === this.idEvento) {
          const index = this.tareas.findIndex((t) => t.idTarea === editada.idTarea);
          if (index !== -1) {
            this.tareas[index].nombre = editada.nombre;
            this.tareas[index].descripcion = editada.descripcion;
            this.tareas[index].fechaLimite = editada.fechaLimite;
            this.tareas[index].estado = editada.estado;
            this.cdr.detectChanges();
          } else {
            this.cargarTareas();
          }
        }
      })
    );
  }

  cargarPlanOperativo(): void {
    this.cargandoPlan = true;
    this.http
      .get<PlanOperativoEvento>(`${this.apiBase}/eventos/${this.idEvento}/plan-operativo`)
      .subscribe({
        next: (plan) => {
          this.planOperativo = plan;
          this.construirDiasEvento(plan.fechaEvento, plan.fechaFin);
          if (plan.fechaEvento) {
            this.configurarLimitesCalendario(plan.fechaEvento, plan.fechaFin);
          }
          this.cargandoPlan = false;
          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error('Error al cargar plan operativo', err);
          this.cargandoPlan = false;
        }
      });
  }

  private construirDiasEvento(fechaInicioStr: string, fechaFinStr: string | null): void {
    const inicio = this.parsearFechaLocal(fechaInicioStr);
    const fin = fechaFinStr ? this.parsearFechaLocal(fechaFinStr) : inicio;

    if (!inicio || !fin || fin <= inicio) {
      this.diasEvento = [];
      this.diaFiltro = 'todos';
      return;
    }

    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    const dias: { clave: string; etiqueta: string }[] = [];
    const cursor = new Date(inicio.getFullYear(), inicio.getMonth(), inicio.getDate());
    const limite = new Date(fin.getFullYear(), fin.getMonth(), fin.getDate());

    let idx = 1;
    while (cursor <= limite && idx <= 14) {
      const y = cursor.getFullYear();
      const m = String(cursor.getMonth() + 1).padStart(2, '0');
      const d = String(cursor.getDate()).padStart(2, '0');
      dias.push({
        clave: `${y}-${m}-${d}`,
        etiqueta: `Día ${idx} (${cursor.getDate()} ${meses[cursor.getMonth()]})`
      });
      cursor.setDate(cursor.getDate() + 1);
      idx++;
    }

    this.diasEvento = dias;
    if (this.diaFiltro !== 'todos' && !this.diasEvento.some((d) => d.clave === this.diaFiltro)) {
      this.diaFiltro = 'todos';
    }
  }

  private parsearFechaLocal(valor: string): Date | null {
    if (!valor) return null;
    const soloFecha = valor.split('T')[0];
    const partes = soloFecha.split('-').map(Number);
    if (partes.length === 3 && partes.every((n) => !isNaN(n))) {
      return new Date(partes[0], partes[1] - 1, partes[2]);
    }
    const dt = new Date(valor);
    return isNaN(dt.getTime()) ? null : dt;
  }

  private claveDiaDesdeFecha(valor: string | null | undefined): string | null {
    if (!valor) return null;
    const dt = new Date(valor);
    if (isNaN(dt.getTime())) return null;
    const y = dt.getFullYear();
    const m = String(dt.getMonth() + 1).padStart(2, '0');
    const d = String(dt.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  get tareasFiltradasPorDia(): any[] {
    if (this.diaFiltro === 'todos') return this.tareas;
    return this.tareas.filter((t) => this.claveDiaDesdeFecha(t.fechaLimite) === this.diaFiltro);
  }

  tareasPorEstado(estado: string): any[] {
    return this.tareasFiltradasPorDia.filter(
      (t) => (t.estado || 'Pendiente').toLowerCase() === estado.toLowerCase()
    );
  }

  get entradasRunOfShow(): {
    tipo: 'tarea' | 'proveedor';
    fechaSort: number;
    tarea?: any;
    proveedor?: ProveedorHorarioPlan;
  }[] {
    const lista: {
      tipo: 'tarea' | 'proveedor';
      fechaSort: number;
      tarea?: any;
      proveedor?: ProveedorHorarioPlan;
    }[] = [];

    for (const t of this.tareasFiltradasPorDia) {
      const ts = t.fechaLimite ? new Date(t.fechaLimite).getTime() : Number.MAX_SAFE_INTEGER;
      lista.push({ tipo: 'tarea', fechaSort: ts, tarea: t });
    }

    const proveedores = this.planOperativo?.proveedores ?? [];
    for (const p of proveedores) {
      if (!p.horaPactada) continue;
      if (this.diaFiltro !== 'todos' && this.claveDiaDesdeFecha(p.horaPactada) !== this.diaFiltro) {
        continue;
      }
      const ts = new Date(p.horaPactada).getTime();
      lista.push({ tipo: 'proveedor', fechaSort: ts, proveedor: p });
    }

    return lista.sort((a, b) => a.fechaSort - b.fechaSort);
  }

  esProveedorRetrasado(p: ProveedorHorarioPlan): boolean {
    if (p.estadoOperativo === 'Retrasado') return true;
    if (p.horaPactada && p.horaLlegada) {
      return new Date(p.horaLlegada).getTime() > new Date(p.horaPactada).getTime();
    }
    return false;
  }

  nombreUsuarioCheckin(idUsuario?: number | null): string {
    if (!idUsuario) return 'Sin registrar';
    const u = this.personal.find((p) => p.idUsuario === idUsuario);
    if (!u) return `Usuario #${idUsuario}`;
    return `${u.nombre || ''} ${u.apellidoPaterno || ''}`.trim();
  }

  // ── Acciones rápidas de estado en tareas (Kanban y Lista) ──
  cambiarEstadoTarea(tarea: any, nuevoEstado: string): void {
    if (!tarea?.idTarea || tarea.estado === nuevoEstado) return;

    const estadoAnterior = tarea.estado;
    tarea.estado = nuevoEstado;

    this.http
      .patch(`${this.apiBase}/tareas/${tarea.idTarea}/estado`, { estado: nuevoEstado })
      .subscribe({
        next: () => this.cdr.detectChanges(),
        error: () => {
          // Fallback a PUT completo si la API usa PUT para actualizar la tarea
          const body = {
            idTarea: tarea.idTarea,
            idEvento: tarea.idEvento ?? this.idEvento,
            idUsuario: tarea.idUsuario,
            nombre: tarea.nombre,
            descripcion: tarea.descripcion,
            fechaLimite: tarea.fechaLimite,
            estado: nuevoEstado,
            observaciones: tarea.observaciones ?? ''
          };
          this.http.put(`${this.apiBase}/tareas/${tarea.idTarea}`, body).subscribe({
            next: () => this.cdr.detectChanges(),
            error: (err) => {
              console.error('Error al actualizar estado de tarea:', err);
              tarea.estado = estadoAnterior;
              alert('No se pudo actualizar el estado de la tarea.');
            }
          });
        }
      });
  }

  // ── Modal de Incidencia en Tarea ──
  abrirModalIncidencia(tarea: any): void {
    this.tareaIncidencia = tarea;
    this.observacionIncidencia = '';
    this.archivoIncidencia = null;
    const modal = document.getElementById('modal_incidencia_tarea') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalIncidencia(): void {
    const modal = document.getElementById('modal_incidencia_tarea') as HTMLDialogElement;
    if (modal) modal.close();
    this.tareaIncidencia = null;
    this.archivoIncidencia = null;
  }

  onArchivoIncidencia(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.archivoIncidencia = input.files?.[0] || null;
  }

  guardarIncidencia(): void {
    if (!this.tareaIncidencia || !this.observacionIncidencia.trim()) return;
    this.enviandoIncidencia = true;

    const obs = this.observacionIncidencia.trim();
    const idTarea = this.tareaIncidencia.idTarea;

    const formData = new FormData();
    formData.append('observaciones', obs);
    if (this.archivoIncidencia) {
      formData.append('foto', this.archivoIncidencia);
    }

    this.http
      .post(`${this.apiBase}/tareas/${idTarea}/incidencias`, formData)
      .subscribe({
        next: (res: any) => {
          this.enviandoIncidencia = false;
          if (!this.tareaIncidencia.incidencias) this.tareaIncidencia.incidencias = [];
          this.tareaIncidencia.incidencias.unshift({
            observacion: obs,
            fotoUrl: res?.fotoUrl || null,
            fechaHora: new Date().toISOString()
          });
          this.cerrarModalIncidencia();
          this.cdr.detectChanges();
        },
        error: () => {
          // Respaldo JSON si el endpoint espera payload JSON
          this.http
            .post(`${this.apiBase}/tareas/${idTarea}/incidencias`, { observaciones: obs })
            .subscribe({
              next: () => {
                this.enviandoIncidencia = false;
                if (!this.tareaIncidencia.incidencias) this.tareaIncidencia.incidencias = [];
                this.tareaIncidencia.incidencias.unshift({
                  observacion: obs,
                  fechaHora: new Date().toISOString()
                });
                this.cerrarModalIncidencia();
                this.cdr.detectChanges();
              },
              error: (err) => {
                console.error('Error al registrar incidencia:', err);
                this.enviandoIncidencia = false;
                alert('No se pudo registrar la incidencia.');
              }
            });
        }
      });
  }

  // ── Operación completa de Proveedor (Hora Pactada, Llegada, Salida, Estado, Usuario Check-in) ──
  abrirModalOperacionProveedor(prov: ProveedorHorarioPlan): void {
    this.proveedorEditando = prov;
    this.formProveedor = {
      horaPactada: prov.horaPactada ? this.formatearParaInput(new Date(prov.horaPactada)) : '',
      horaLlegada: prov.horaLlegada ? this.formatearParaInput(new Date(prov.horaLlegada)) : '',
      horaSalida: prov.horaSalida ? this.formatearParaInput(new Date(prov.horaSalida)) : '',
      estadoOperativo: this.estadosProveedor.includes(prov.estadoOperativo)
        ? prov.estadoOperativo
        : 'Pendiente',
      idUsuarioCheckin: prov.idUsuarioCheckin ?? null,
      observaciones: prov.observaciones || ''
    };

    const modal = document.getElementById('modal_operacion_proveedor') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  marcarLlegadaAhora(): void {
    this.formProveedor.horaLlegada = this.formatearParaInput(new Date());
    if (this.formProveedor.estadoOperativo === 'Pendiente') {
      this.formProveedor.estadoOperativo = 'En sitio';
    }
  }

  marcarSalidaAhora(): void {
    this.formProveedor.horaSalida = this.formatearParaInput(new Date());
    this.formProveedor.estadoOperativo = 'Completado';
  }

  cerrarModalOperacionProveedor(): void {
    const modal = document.getElementById('modal_operacion_proveedor') as HTMLDialogElement;
    if (modal) modal.close();
    this.proveedorEditando = null;
  }

  guardarOperacionProveedor(): void {
    if (!this.proveedorEditando) return;
    this.guardandoProveedor = true;

    const payload = {
      horaPactada: this.formProveedor.horaPactada
        ? new Date(this.formProveedor.horaPactada).toISOString()
        : null,
      horaLlegada: this.formProveedor.horaLlegada
        ? new Date(this.formProveedor.horaLlegada).toISOString()
        : null,
      horaSalida: this.formProveedor.horaSalida
        ? new Date(this.formProveedor.horaSalida).toISOString()
        : null,
      estadoOperativo: this.formProveedor.estadoOperativo,
      idUsuarioCheckin: this.formProveedor.idUsuarioCheckin,
      observaciones: this.formProveedor.observaciones.trim()
    };

    this.http
      .patch(
        `${this.apiBase}/eventos/proveedores/${this.proveedorEditando.idEventoProveedor}/operacion`,
        payload
      )
      .subscribe({
        next: () => {
          this.guardandoProveedor = false;
          this.cerrarModalOperacionProveedor();
          this.cargarPlanOperativo();
        },
        error: () => {
          // Respaldo al endpoint de hora-pactada si aún no agregaste /operacion
          this.http
            .patch(
              `${this.apiBase}/eventos/proveedores/${this.proveedorEditando!.idEventoProveedor}/hora-pactada`,
              {
                horaPactada: payload.horaPactada,
                observaciones: payload.observaciones
              }
            )
            .subscribe({
              next: () => {
                this.guardandoProveedor = false;
                this.cerrarModalOperacionProveedor();
                this.cargarPlanOperativo();
              },
              error: (err) => {
                console.error('Error al guardar operación de proveedor:', err);
                this.guardandoProveedor = false;
                alert('No se pudieron guardar los datos operativos del proveedor.');
              }
            });
        }
      });
  }

  cargarDetalleEvento() {
    this.http.get<any>(`${this.apiBase}/eventos/${this.idEvento}`).subscribe({
      next: (res) => {
        if (res && res.fechaEvento && !this.planOperativo) {
          this.configurarLimitesCalendario(res.fechaEvento, res.fechaFin ?? null);
        }
      },
      error: (err) => console.error('Error al cargar detalle del evento', err)
    });
  }

  configurarLimitesCalendario(fechaEventoStr: string, fechaFinStr: string | null = null) {
    const fechaE = this.parsearFechaLocal(fechaEventoStr) ?? new Date(fechaEventoStr);
    const fechaF = fechaFinStr ? (this.parsearFechaLocal(fechaFinStr) ?? fechaE) : fechaE;

    const min = new Date(fechaE);
    min.setDate(min.getDate() - 7);
    min.setHours(0, 0, 0, 0);
    this.minFecha = this.formatearParaInput(min);

    const max = new Date(fechaF > fechaE ? fechaF : fechaE);
    max.setDate(max.getDate() + 2);
    max.setHours(23, 59, 0, 0);
    this.maxFecha = this.formatearParaInput(max);
  }

  formatearParaInput(fecha: Date): string {
    const offset = fecha.getTimezoneOffset() * 60000;
    return new Date(fecha.getTime() - offset).toISOString().slice(0, 16);
  }

  cargarPersonal() {
    this.http.get<any[]>(`${this.apiBase}/usuarios/empleados`).subscribe({
      next: (res) => (this.personal = res),
      error: (err) => console.error('Error al cargar personal', err)
    });
  }

  abrirModalTarea(tituloSugerido: string = '') {
    this.modoEdicion = false;
    this.idTareaEditando = 0;
    this.nuevaTarea = {
      idEvento: this.idEvento,
      idUsuario: null,
      nombre: tituloSugerido,
      descripcion: '',
      fechaLimite: '',
      observaciones: ''
    };

    const modal = document.getElementById('modal_nueva_tarea') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  programarHitoDesdeServicio(servicio: ServicioInternoPlan) {
    this.pestanaActiva = 'cronograma';
    this.abrirModalTarea(`Ejecución: ${servicio.nombre}`);
  }

  guardarTarea() {
    this.procesando = true;

    if (this.modoEdicion) {
      this.http.put(`${this.apiBase}/tareas/${this.idTareaEditando}`, this.nuevaTarea).subscribe({
        next: () => {
          this.procesando = false;
          (document.getElementById('modal_nueva_tarea') as HTMLDialogElement).close();
          this.cargarTareas();
        },
        error: (err) => {
          console.error(err);
          this.procesando = false;
          alert('Error al actualizar el hito.');
        }
      });
    } else {
      this.http.post(`${this.apiBase}/tareas`, this.nuevaTarea).subscribe({
        next: () => {
          this.procesando = false;
          (document.getElementById('modal_nueva_tarea') as HTMLDialogElement).close();
          this.cargarTareas();
        },
        error: (err) => {
          console.error(err);
          this.procesando = false;
          alert('Error al crear el hito del cronograma.');
        }
      });
    }
  }

  abrirModalEditar(tarea: any) {
    this.modoEdicion = true;
    this.idTareaEditando = tarea.idTarea;

    let fechaFormateada = '';
    if (tarea.fechaLimite) {
      fechaFormateada = this.formatearParaInput(new Date(tarea.fechaLimite));
    }

    this.nuevaTarea = {
      idEvento: tarea.idEvento,
      idUsuario: tarea.idUsuario,
      nombre: tarea.nombre,
      descripcion: tarea.descripcion,
      fechaLimite: fechaFormateada,
      observaciones: tarea.observaciones
    };

    const modal = document.getElementById('modal_nueva_tarea') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  eliminarTarea(idTarea: number) {
    if (confirm('¿Estás seguro de que deseas eliminar este hito de la logística?')) {
      this.http.delete(`${this.apiBase}/tareas/${idTarea}`).subscribe({
        next: () => this.cargarTareas(),
        error: (err) => {
          console.error(err);
          alert('Error al eliminar el hito.');
        }
      });
    }
  }

  abrirModalImagen(url: string) {
    this.imagenModalUrl = url;
    const modal = document.getElementById('modal_ver_imagen') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalImagen() {
    this.imagenModalUrl = null;
    const modal = document.getElementById('modal_ver_imagen') as HTMLDialogElement;
    if (modal) modal.close();
  }

  cargarTareas() {
    this.cargando = true;
    this.http.get<any[]>(`${this.apiBase}/tareas/evento/${this.idEvento}`).subscribe({
      next: (data) => {
        this.tareas = data.sort((a, b) => new Date(a.fechaLimite).getTime() - new Date(b.fechaLimite).getTime());
        this.cargando = false;
      },
      error: (err) => {
        console.error('Error al cargar tareas operativas', err);
        this.cargando = false;
      }
    });
  }

  generarPlantillaBase() {
    alert('Próximamente: Esto llamará a un endpoint en C# para insertar tareas predeterminadas.');
  }

  exportarPDF() {
    alert('Generando PDF del cronograma para impresión...');
  }
}