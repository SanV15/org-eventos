import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/notification_service.dart';
import 'notificaciones_event.dart';
import 'notificaciones_state.dart';

class NotificacionesBloc
    extends Bloc<NotificacionesEvent, NotificacionesState> {
  final NotificationService _notificationService;

  NotificacionesBloc({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService(),
      super(NotificacionesInitial()) {
    on<InicializarNotificacionesEvent>(_onInicializar);
    on<TareaAsignadaNotificacionEvent>(_onTareaAsignada);
    on<EstadoTareaCambiadoNotificacionEvent>(_onEstadoCambiado);
    on<SincronizarRecordatoriosEvent>(_onSincronizarRecordatorios);
  }

  Future<void> _onInicializar(
    InicializarNotificacionesEvent event,
    Emitter<NotificacionesState> emit,
  ) async {
    await _notificationService.init();
    emit(NotificacionesActivasState());
  }

  Future<void> _onTareaAsignada(
    TareaAsignadaNotificacionEvent event,
    Emitter<NotificacionesState> emit,
  ) async {
    final t = event.tarea;

    await _notificationService.mostrarNotificacion(
      id: t.idTarea,
      titulo: '📋 Nueva tarea asignada',
      cuerpo: '${t.nombreTarea} · Evento: ${t.nombreEvento}',
    );

    if (t.fechaLimite != null &&
        (t.estado == 'Pendiente' || t.estado == 'En progreso')) {
      await _notificationService.programarRecordatorioMediaHora(
        idTarea: t.idTarea,
        nombreTarea: t.nombreTarea,
        nombreEvento: t.nombreEvento,
        fechaLimite: t.fechaLimite!,
      );
    }

    emit(
      NotificacionesActivasState(ultimoMensaje: 'Asignada: ${t.nombreTarea}'),
    );
  }

  Future<void> _onEstadoCambiado(
    EstadoTareaCambiadoNotificacionEvent event,
    Emitter<NotificacionesState> emit,
  ) async {
    final esCompletada = event.nuevoEstado == 'Completada';
    final esCancelada = event.nuevoEstado == 'Cancelada';

    await _notificationService.mostrarNotificacion(
      id: event.idTarea + 50000,
      titulo: esCompletada
          ? '✅ Tarea completada'
          : '🔄 Actualización de estado',
      cuerpo: '"${event.nombreTarea}" ahora está ${event.nuevoEstado}',
    );

    // Si finalizó, eliminamos la alarma de 30 minutos
    if (esCompletada || esCancelada) {
      await _notificationService.cancelarRecordatorio(event.idTarea);
    }

    emit(
      NotificacionesActivasState(
        ultimoMensaje: '${event.nombreTarea} -> ${event.nuevoEstado}',
      ),
    );
  }

  Future<void> _onSincronizarRecordatorios(
    SincronizarRecordatoriosEvent event,
    Emitter<NotificacionesState> emit,
  ) async {
    for (final tarea in event.tareas) {
      if ((tarea.estado == 'Pendiente' || tarea.estado == 'En progreso') &&
          tarea.fechaLimite != null) {
        await _notificationService.programarRecordatorioMediaHora(
          idTarea: tarea.idTarea,
          nombreTarea: tarea.nombreTarea,
          nombreEvento: tarea.nombreEvento,
          fechaLimite: tarea.fechaLimite!,
        );
      } else {
        await _notificationService.cancelarRecordatorio(tarea.idTarea);
      }
    }
    emit(NotificacionesActivasState());
  }
}
