import '../../data/models/tarea_operativa.dart';

abstract class NotificacionesEvent {}

class InicializarNotificacionesEvent extends NotificacionesEvent {}

class TareaAsignadaNotificacionEvent extends NotificacionesEvent {
  final TareaOperativa tarea;
  TareaAsignadaNotificacionEvent(this.tarea);
}

class EstadoTareaCambiadoNotificacionEvent extends NotificacionesEvent {
  final int idTarea;
  final String nombreTarea;
  final String nuevoEstado;

  EstadoTareaCambiadoNotificacionEvent({
    required this.idTarea,
    required this.nombreTarea,
    required this.nuevoEstado,
  });
}

class SincronizarRecordatoriosEvent extends NotificacionesEvent {
  final List<TareaOperativa> tareas;
  SincronizarRecordatoriosEvent(this.tareas);
}
