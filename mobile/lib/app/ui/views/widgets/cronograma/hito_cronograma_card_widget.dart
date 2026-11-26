import 'package:flutter/material.dart';
import 'historial_incidencias_cronograma_widget.dart';

class HitoCronogramaCardWidget extends StatelessWidget {
  final Map<String, dynamic> tarea;
  final void Function(String url) onVerImagen;

  const HitoCronogramaCardWidget({
    super.key,
    required this.tarea,
    required this.onVerImagen,
  });

  Color _obtenerColorEstado(String? estado) {
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

  String _formatearFechaHora(String? fechaIso) {
    if (fechaIso == null) return '--:--';
    final dt = DateTime.tryParse(fechaIso);
    if (dt == null) return '--:--';
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
    final hora =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$hora · ${dt.day}${meses[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final estado = tarea['estado'] ?? 'Pendiente';
    final colorEstado = _obtenerColorEstado(estado);
    final List<dynamic> incidencias = tarea['incidencias'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorEstado.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatearFechaHora(tarea['fechaLimite']),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorEstado,
                  ),
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
                    estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tarea['nombre'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: estado == 'Cancelada' ? Colors.grey : Colors.black87,
                decoration: estado == 'Cancelada'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tarea['descripcion'] ?? 'Sin detalles',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asignado a: ${tarea['personalAsignado']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
            if (incidencias.isNotEmpty) ...[
              const SizedBox(height: 10),
              HistorialIncidenciasCronogramaWidget(
                incidencias: incidencias,
                onVerImagen: onVerImagen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
