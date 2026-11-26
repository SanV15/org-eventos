import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/bloc/notificaciones/notificaciones_bloc.dart';
import 'package:org_eventos/app/bloc/notificaciones/notificaciones_event.dart';
import 'package:org_eventos/app/data/services/signalr_service.dart';
import '../data/models/tarea_operativa.dart';
import '../data/providers/eventos_provider.dart';
import '../data/providers/tareas_provider.dart';

typedef BoolEventoMap = Map<int, bool>;

class TareasController extends GetxController {
  final TareasProvider _provider = TareasProvider();
  final EventosProvider _eventosProvider = EventosProvider();
  final SignalRService _signalRService = SignalRService();

  // Variables reactivas
  var tareas = <TareaOperativa>[].obs;
  var isLoading = true.obs;
  final fotosPorEvento = FotoEventoMap().obs;
  final subiendoFotoEvento = BoolEventoMap().obs;

  bool _sincronizando = false;

  NotificacionesBloc? get _notificacionesBloc {
    if (Get.isRegistered<NotificacionesBloc>()) {
      return Get.find<NotificacionesBloc>();
    }
    return null;
  }

  // --- FILTROS REACTIVOS POR PESTAÑA ---
  List<TareaOperativa> get tareasPendientes =>
      tareas.where((t) => t.estado == 'Pendiente').toList();

  List<TareaOperativa> get tareasEnProgreso =>
      tareas.where((t) => t.estado == 'En progreso').toList();

  List<TareaOperativa> get tareasCompletadas =>
      tareas.where((t) => t.estado == 'Completada').toList();

  List<TareaOperativa> get tareasCanceladas =>
      tareas.where((t) => t.estado == 'Cancelada').toList();

  List<TareaOperativa> get tareasDeHoy {
    final hoy = DateTime.now();
    final filtradas = tareas.where((t) {
      if (t.fechaLimite == null) return false;
      return t.fechaLimite!.year == hoy.year &&
          t.fechaLimite!.month == hoy.month &&
          t.fechaLimite!.day == hoy.day;
    }).toList();

    filtradas.sort((a, b) => a.fechaLimite!.compareTo(b.fechaLimite!));
    return filtradas;
  }

  int get totalTareasHoy => tareasDeHoy.length;
  int get tareasHoyCompletadas =>
      tareasDeHoy.where((t) => t.estado == 'Completada').length;

  Map<int, List<TareaOperativa>> agruparPorEvento(List<TareaOperativa> lista) {
    final Map<int, List<TareaOperativa>> agrupadas = {};
    for (final tarea in lista) {
      agrupadas.putIfAbsent(tarea.idEvento, () => []).add(tarea);
    }
    return agrupadas;
  }

  @override
  void onInit() {
    super.onInit();
    cargarMisTareas().then((_) => _iniciarSignalR());
  }

  @override
  void onClose() {
    _signalRService.desconectar();
    super.onClose();
  }

  void _iniciarSignalR() {
    _signalRService
        .initConnection(
          onTareaActualizada: (data) => cargarMisTareasSilencioso(),
          onIncidenciaReportada: (data) => cargarMisTareasSilencioso(),
          onRecargarLista: () => cargarMisTareasSilencioso(),
        )
        .then((_) {
          final idsEventos = tareas.map((t) => t.idEvento).toSet();
          for (final id in idsEventos) {
            _signalRService.unirseAEvento(id);
          }
        });
  }

  Future<void> cargarMisTareasSilencioso() async {
    if (_sincronizando) return;
    _sincronizando = true;

    try {
      final mapaPrevio = {for (var t in tareas) t.idTarea: t.estado};

      final resultados = await Future.wait([
        _provider.obtenerMisTareas(),
        _eventosProvider.obtenerMapaFotosEventos().catchError(
          (_) => FotoEventoMap(),
        ),
      ]);

      final resultado = resultados[0] as List<TareaOperativa>;
      final mapaFotos = resultados[1] as FotoEventoMap;
      final bloc = _notificacionesBloc;

      if (bloc != null) {
        for (final nueva in resultado) {
          if (!mapaPrevio.containsKey(nueva.idTarea)) {
            bloc.add(TareaAsignadaNotificacionEvent(nueva));
          } else if (mapaPrevio[nueva.idTarea] != nueva.estado) {
            bloc.add(
              EstadoTareaCambiadoNotificacionEvent(
                idTarea: nueva.idTarea,
                nombreTarea: nueva.nombreTarea,
                nuevoEstado: nueva.estado,
              ),
            );
          }
        }
        bloc.add(SincronizarRecordatoriosEvent(resultado));
      }

      tareas.assignAll(resultado);
      if (mapaFotos.isNotEmpty) {
        fotosPorEvento.assignAll(mapaFotos);
      }
    } catch (e) {
      debugPrint('Error en recarga silenciosa de tareas: $e');
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> cargarMisTareas() async {
    try {
      isLoading(true);
      final resultados = await Future.wait([
        _provider.obtenerMisTareas(),
        _eventosProvider.obtenerMapaFotosEventos().catchError(
          (_) => FotoEventoMap(),
        ),
      ]);

      final resultado = resultados[0] as List<TareaOperativa>;
      final mapaFotos = resultados[1] as FotoEventoMap;

      tareas.assignAll(resultado);
      fotosPorEvento.assignAll(mapaFotos);

      _notificacionesBloc?.add(SincronizarRecordatoriosEvent(resultado));
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los hitos logísticos');
    } finally {
      isLoading(false);
    }
  }

  Future<void> subirFotoEvento(int idEvento, String rutaImagen) async {
    subiendoFotoEvento[idEvento] = true;
    try {
      final nuevaUrl = await _eventosProvider.subirFotoEvento(
        idEvento,
        rutaImagen,
      );
      if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
        fotosPorEvento[idEvento] = nuevaUrl;
        fotosPorEvento.refresh();
        Get.snackbar(
          'Imagen actualizada',
          'La foto de referencia del evento se guardó correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo subir la imagen del evento',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Fallo de conexión al subir la imagen',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      subiendoFotoEvento[idEvento] = false;
    }
  }

  void cambiarEstado(int idTarea, String nuevoEstado) async {
    try {
      final exito = await _provider.actualizarEstado(idTarea, nuevoEstado);

      if (exito) {
        final index = tareas.indexWhere((t) => t.idTarea == idTarea);
        if (index != -1) {
          final tarea = tareas[index];
          tarea.estado = nuevoEstado;
          tareas.refresh();

          _notificacionesBloc?.add(
            EstadoTareaCambiadoNotificacionEvent(
              idTarea: tarea.idTarea,
              nombreTarea: tarea.nombreTarea,
              nuevoEstado: nuevoEstado,
            ),
          );
        }

        Get.snackbar(
          'Actualizado',
          'Estado cambiado a $nuevoEstado',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar('Error', 'No se pudo actualizar el estado en el servidor');
      }
    } catch (e) {
      Get.snackbar('Error', 'Fallo de conexión al actualizar');
    }
  }

  Future<void> registrarIncidencia(
    int idTarea,
    String observaciones,
    String? rutaImagen,
  ) async {
    try {
      final exito = await _provider.reportarIncidencia(
        idTarea,
        observaciones,
        rutaImagen,
      );
      if (exito) {
        await cargarMisTareasSilencioso();

        Get.snackbar(
          'Incidencia Registrada',
          'Se guardó la observación y evidencia en la base de datos',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade700,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo guardar la incidencia en el servidor',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Fallo de conexión al enviar la incidencia');
    }
  }
}
