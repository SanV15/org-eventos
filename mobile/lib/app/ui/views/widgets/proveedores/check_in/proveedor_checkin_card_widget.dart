import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/evento_proveedor_operativo.dart';
import 'package:url_launcher/url_launcher.dart';

class ProveedorCheckinCardWidget extends StatelessWidget {
  final EventoProveedorOperativo item;
  final bool esSoloLectura;
  final bool procesando;
  final VoidCallback onCheckInRapido;
  final VoidCallback onAbrirDetalle;

  const ProveedorCheckinCardWidget({
    super.key,
    required this.item,
    this.esSoloLectura = false,
    this.procesando = false,
    required this.onCheckInRapido,
    required this.onAbrirDetalle,
  });

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'En sitio':
        return const Color(0xFF16A34A);
      case 'Completado':
        return const Color(0xFF0D9488);
      case 'Retrasado':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _hora(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} hrs';
  }

  Future<void> _llamarProveedor() async {
    final limpio = item.telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    if (limpio.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: limpio);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(item.estadoOperativo);
    final alertaHorario = item.estaRetrasadoPorHorario;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alertaHorario
              ? const Color(0xFFEA580C)
              : color.withOpacity(0.45),
          width: alertaHorario ? 1.8 : 1.3,
        ),
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
                  item.nombreServicio,
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
                  item.estadoOperativo,
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
                  item.nombreProveedor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              if (item.telefono.isNotEmpty)
                InkWell(
                  onTap: _llamarProveedor,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.call,
                          size: 13,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.telefono,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (item.horaPactada != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  alertaHorario
                      ? Icons.warning_amber_rounded
                      : Icons.schedule_outlined,
                  size: 14,
                  color: alertaHorario
                      ? const Color(0xFFEA580C)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hora pactada: ${_hora(item.horaPactada)}${alertaHorario ? ' (Fuera de horario)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: alertaHorario
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: alertaHorario
                        ? const Color(0xFFEA580C)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
          if (item.horaLlegada != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.login, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  'Llegada: ${_hora(item.horaLlegada)}${item.recibidoPor != null ? ' · Por ${item.recibidoPor}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
          if (item.horaSalida != null) ...[
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
                  'Entregado / Salida: ${_hora(item.horaSalida)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ],
          if (item.observaciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nota: ${item.observaciones}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
          if (!esSoloLectura) ...[
            const Divider(height: 18, thickness: 0.7),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.estadoOperativo == 'Pendiente' ||
                    item.estadoOperativo == 'Retrasado') ...[
                  OutlinedButton.icon(
                    onPressed: procesando ? null : onCheckInRapido,
                    icon: procesando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Ya llegó',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: procesando ? null : onAbrirDetalle,
                  icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                  label: const Text(
                    'Gestionar',
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
