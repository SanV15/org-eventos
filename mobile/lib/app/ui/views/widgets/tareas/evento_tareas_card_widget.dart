import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/controllers/tareas_controller.dart';
import 'package:org_eventos/app/data/models/tarea_operativa.dart';
import '../eventos/evento_banner_canvas_widget.dart';
import 'tarea_operativa_card_widget.dart';

class EventoTareasCardWidget extends StatefulWidget {
  final int idEvento;
  final String nombreEvento;
  final List<TareaOperativa> tareas;
  final TareasController controller;
  final void Function(TareaOperativa tarea) onReportarIncidencia;

  const EventoTareasCardWidget({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
    required this.tareas,
    required this.controller,
    required this.onReportarIncidencia,
  });

  @override
  State<EventoTareasCardWidget> createState() => _EventoTareasCardWidgetState();
}

class _EventoTareasCardWidgetState extends State<EventoTareasCardWidget> {
  bool _expandido = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: const Color(0xFFF1F5F9),
        elevation: 2.5,
        shadowColor: Colors.black.withOpacity(0.10),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF93C5FD), width: 1.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final fotoUrl = widget.controller.fotosPorEvento[widget.idEvento];
              final subiendo =
                  widget.controller.subiendoFotoEvento[widget.idEvento] ??
                  false;

              return EventoBannerCanvasWidget(
                idEvento: widget.idEvento,
                titulo: widget.nombreEvento,
                subtitulo:
                    '${widget.tareas.length} ${widget.tareas.length == 1 ? 'hito asignado' : 'hitos asignados'}',
                fotoUrl: fotoUrl,
                subiendoFoto: subiendo,
                mostrarBordeInferior: _expandido,
                alturaConFoto: 135,
                borderRadius: _expandido
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
                trailing: Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onTapCabecera: () => setState(() => _expandido = !_expandido),
                onImagenSeleccionada: (ruta) =>
                    widget.controller.subirFotoEvento(widget.idEvento, ruta),
              );
            }),
            if (_expandido)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                child: Column(
                  children: widget.tareas
                      .map(
                        (tarea) => TareaOperativaCardWidget(
                          tarea: tarea,
                          onCambiarEstado: (nuevoEstado) => widget.controller
                              .cambiarEstado(tarea.idTarea, nuevoEstado),
                          onReportarIncidencia: () =>
                              widget.onReportarIncidencia(tarea),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
