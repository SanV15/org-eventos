import 'package:flutter/material.dart';

class HistorialIncidenciasCronogramaWidget extends StatelessWidget {
  final List<dynamic> incidencias;
  final void Function(String url) onVerImagen;

  const HistorialIncidenciasCronogramaWidget({
    super.key,
    required this.incidencias,
    required this.onVerImagen,
  });

  String _formatearHora(String? fechaIso) {
    if (fechaIso == null) return '';
    final dt = DateTime.tryParse(fechaIso);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 6),
              Text(
                'Historial de Reportes (${incidencias.length}):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...incidencias.map((inc) {
            final hora = _formatearHora(inc['fechaHora']?.toString());
            final fotoUrl = inc['fotoUrl']?.toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                          inc['observacion'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (hora.isNotEmpty)
                        Text(
                          hora,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => onVerImagen(fotoUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          fotoUrl,
                          height: 80,
                          width: 110,
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
