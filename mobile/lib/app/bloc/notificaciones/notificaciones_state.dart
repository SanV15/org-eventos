abstract class NotificacionesState {}

class NotificacionesInitial extends NotificacionesState {}

class NotificacionesActivasState extends NotificacionesState {
  final String? ultimoMensaje;
  NotificacionesActivasState({this.ultimoMensaje});
}
