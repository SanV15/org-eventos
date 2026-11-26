import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/tareas_controller.dart';
import '../../data/models/tarea_operativa.dart';
import 'main_view.dart';

class AgendaDelDiaView extends StatelessWidget {
  final TareasController controller = Get.find<TareasController>();

  AgendaDelDiaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Get.find<MainNavigationController>().abrirMenu(),
        ),
        title: const Text(
          'Agenda de Hoy',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final tareasHoy = controller.tareasDeHoy;
        final total = controller.totalTareasHoy;
        final completadas = controller.tareasHoyCompletadas;
        final progreso = total > 0 ? completadas / total : 0.0;

        return Column(
          children: [
            // Tarjeta de Resumen / Progreso Diario
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progreso Operativo del Día',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$completadas de $total Hitos',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista o Timeline de Hitos de Hoy
            Expanded(
              child: tareasHoy.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => controller.cargarMisTareas(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.22,
                          ),
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 60,
                            color: Colors.amber.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              '¡Día libre! No hay hitos programados para hoy.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.cargarMisTareas(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tareasHoy.length,
                        itemBuilder: (context, index) {
                          final tarea = tareasHoy[index];
                          final esUltimo = index == tareasHoy.length - 1;
                          return _TimelineItem(
                            tarea: tarea,
                            esUltimo: esUltimo,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TareaOperativa tarea;
  final bool esUltimo;

  const _TimelineItem({required this.tarea, required this.esUltimo});

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Completada':
        return const Color(0xFF16A34A);
      case 'En progreso':
        return const Color(0xFFEA580C);
      case 'Cancelada':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora = tarea.fechaLimite != null
        ? '${tarea.fechaLimite!.hour.toString().padLeft(2, '0')}:${tarea.fechaLimite!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final colorEstado = _obtenerColorEstado(tarea.estado);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Column(
              children: [
                Text(
                  hora,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorEstado,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colorEstado.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorEstado.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tarea.nombreEvento,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tarea.estado,
                          style: TextStyle(
                            color: colorEstado,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tarea.nombreTarea,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  if (tarea.descripcion != null &&
                      tarea.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tarea.descripcion!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
