import 'package:flutter/material.dart';
import 'package:org_eventos/app/controllers/tareas_controller.dart';
import 'package:org_eventos/app/data/models/tarea_operativa.dart';
import 'evento_tareas_card_widget.dart';
import 'modal_reportar_incidencia.dart';

class ListaTareasPestanaWidget extends StatelessWidget {
  final List<TareaOperativa> lista;
  final String mensajeVacio;
  final TareasController controller;

  const ListaTareasPestanaWidget({
    super.key,
    required this.lista,
    required this.mensajeVacio,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.cargarMisTareas(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                mensajeVacio,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    final tareasAgrupadas = controller.agruparPorEvento(lista);
    final idsEventos = tareasAgrupadas.keys.toList();

    return RefreshIndicator(
      onRefresh: () => controller.cargarMisTareas(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: idsEventos.length,
        itemBuilder: (context, index) {
          final idEvento = idsEventos[index];
          final tareasDelEvento = tareasAgrupadas[idEvento]!;

          tareasDelEvento.sort((a, b) {
            if (a.fechaLimite == null || b.fechaLimite == null) return 0;
            return a.fechaLimite!.compareTo(b.fechaLimite!);
          });

          final nombreEvento = tareasDelEvento.first.nombreEvento.isNotEmpty
              ? tareasDelEvento.first.nombreEvento
              : 'Evento #$idEvento';

          return EventoTareasCardWidget(
            idEvento: idEvento,
            nombreEvento: nombreEvento,
            tareas: tareasDelEvento,
            controller: controller,
            onReportarIncidencia: (tarea) =>
                ModalReportarIncidencia.mostrar(controller, tarea),
          );
        },
      ),
    );
  }
}
