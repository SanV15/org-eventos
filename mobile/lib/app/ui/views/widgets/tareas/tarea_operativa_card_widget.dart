import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/tarea_operativa.dart';
import 'package:org_eventos/app/ui/views/widgets/tareas/historial_incidencias_operativa.dart';

class TareaOperativaCardWidget extends StatelessWidget {
  final TareaOperativa tarea;
  final void Function(String nuevoEstado) onCambiarEstado;
  final VoidCallback onReportarIncidencia;

  const TareaOperativaCardWidget({
    super.key,
    required this.tarea,
    required this.onCambiarEstado,
    required this.onReportarIncidencia,
  });

  String _nombreMes(int mes) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return meses[mes - 1];
  }

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

    final fecha = tarea.fechaLimite != null
        ? '${tarea.fechaLimite!.day} ${_nombreMes(tarea.fechaLimite!.month)}'
        : '';

    final colorEstado = _obtenerColorEstado(tarea.estado);
    final esTerminal =
        tarea.estado == 'Completada' || tarea.estado == 'Cancelada';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorEstado.withOpacity(0.45), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hora,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorEstado,
                      ),
                    ),
                    if (fecha.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        fecha,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tarea.estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tarea.nombreTarea,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tarea.descripcion!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            if (tarea.incidencias.isNotEmpty) ...[
              const SizedBox(height: 8),
              HistorialIncidenciasOperativaWidget(
                incidencias: tarea.incidencias,
              ),
            ],
            const Divider(height: 18, thickness: 0.8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (tarea.estado != 'Cancelada')
                  TextButton.icon(
                    onPressed: onReportarIncidencia,
                    icon: Icon(
                      tarea.estado == 'Completada'
                          ? Icons.note_add_outlined
                          : Icons.report_problem_outlined,
                      size: 16,
                      color: tarea.estado == 'Completada'
                          ? Colors.green
                          : Colors.amber.shade800,
                    ),
                    label: Text(
                      tarea.estado == 'Completada'
                          ? 'Nota Post-Evento'
                          : 'Incidencia',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (esTerminal)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      'Estado Finalizado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tarea.estado,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                      items:
                          const [
                            'Pendiente',
                            'En progreso',
                            'Completada',
                            'Cancelada',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (nuevoEstado) {
                        if (nuevoEstado != null &&
                            nuevoEstado != tarea.estado) {
                          onCambiarEstado(nuevoEstado);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
