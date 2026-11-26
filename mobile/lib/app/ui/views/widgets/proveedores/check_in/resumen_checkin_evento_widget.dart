import 'package:flutter/material.dart';

class ResumenCheckinEventoWidget extends StatelessWidget {
  final int pendientes;
  final int enSitio;
  final int retrasados;
  final int completados;

  const ResumenCheckinEventoWidget({
    super.key,
    required this.pendientes,
    required this.enSitio,
    required this.retrasados,
    required this.completados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _MetricaPill(
            label: 'Pendientes',
            valor: pendientes,
            color: const Color(0xFF2563EB),
          ),
          _MetricaPill(
            label: 'En sitio',
            valor: enSitio,
            color: const Color(0xFF16A34A),
          ),
          _MetricaPill(
            label: 'Retraso',
            valor: retrasados,
            color: const Color(0xFFEA580C),
          ),
          _MetricaPill(
            label: 'Listos',
            valor: completados,
            color: const Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }
}

class _MetricaPill extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;

  const _MetricaPill({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
