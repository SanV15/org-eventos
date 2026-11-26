import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/tarea_operativa.dart';
import '../eventos/visor_imagen_dialog.dart';

class HistorialIncidenciasOperativaWidget extends StatelessWidget {
  final List<IncidenciaItem> incidencias;

  const HistorialIncidenciasOperativaWidget({
    super.key,
    required this.incidencias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                'Historial de Reportes (${incidencias.length}):',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...incidencias.map((inc) {
            final horaInc = inc.fechaHora != null
                ? '${inc.fechaHora!.hour.toString().padLeft(2, '0')}:${inc.fechaHora!.minute.toString().padLeft(2, '0')}'
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          inc.observacion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (horaInc.isNotEmpty)
                        Text(
                          horaInc,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (inc.fotoUrl != null && inc.fotoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => VisorImagenDialog.mostrar(inc.fotoUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          inc.fotoUrl!,
                          height: 65,
                          width: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
