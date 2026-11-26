import 'package:flutter/material.dart';

class ProveedorCronogramaCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool esSoloLectura;
  final VoidCallback onCheckIn;
  final VoidCallback onEditarHoraPactada;

  const ProveedorCronogramaCardWidget({
    super.key,
    required this.item,
    required this.esSoloLectura,
    required this.onCheckIn,
    required this.onEditarHoraPactada,
  });

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'En sitio':
      case 'Completado':
        return const Color(0xFF16A34A);
      case 'Retrasado':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatearHora(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} hrs';
  }

  @override
  Widget build(BuildContext context) {
    final estado = item['estadoOperativo'] ?? 'Pendiente';
    final color = _colorEstado(estado);
    final prov = item['proveedor'] is Map<String, dynamic>
        ? item['proveedor'] as Map<String, dynamic>
        : <String, dynamic>{};
    final nombreProveedor = (prov['nombreCompleto'] ?? 'Proveedor')
        .toString()
        .trim();
    final telefono = prov['telefono']?.toString() ?? '';
    final horaPactada = _formatearHora(item['horaPactada']?.toString());
    final horaLlegada = _formatearHora(item['horaLlegada']?.toString());
    final horaSalida = _formatearHora(item['horaSalida']?.toString());
    final observaciones = item['observaciones']?.toString() ?? '';
    final costo = item['costoAcordado'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['nombreServicio'] ?? 'Servicio contratado',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 15,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nombreProveedor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              if (costo != null)
                Text(
                  '\$$costo',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  telefono,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
          if (horaPactada.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  'Hora pactada: $horaPactada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
          if (horaLlegada.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Text(
                  'Llegada: $horaLlegada',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
          if (horaSalida.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 6),
                Text(
                  'Salida / Entrega: $horaSalida',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ],
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nota: $observaciones',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
          if (!esSoloLectura) ...[
            const Divider(height: 18, thickness: 0.7),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: onEditarHoraPactada,
                  icon: const Icon(Icons.schedule, size: 15),
                  label: Text(
                    horaPactada.isEmpty ? 'Hora pactada' : 'Cambiar hora',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                  label: const Text(
                    'Check-in / Estado',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
