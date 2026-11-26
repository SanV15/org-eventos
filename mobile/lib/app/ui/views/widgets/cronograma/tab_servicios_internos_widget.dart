import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/plan_operativo_evento_model.dart';

class TabServiciosInternosWidget extends StatelessWidget {
  final List<ServicioInternoEventoModel> servicios;
  final bool esSoloLectura;
  final Future<void> Function() onRefresh;
  final void Function(ServicioInternoEventoModel servicio)
  onCrearHitoDesdeServicio;

  const TabServiciosInternosWidget({
    super.key,
    required this.servicios,
    required this.esSoloLectura,
    required this.onRefresh,
    required this.onCrearHitoDesdeServicio,
  });

  @override
  Widget build(BuildContext context) {
    if (servicios.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.24),
            Icon(
              Icons.room_service_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'No hay servicios internos registrados en este evento.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servicios.length,
        itemBuilder: (context, index) {
          final s = servicios[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.withOpacity(0.25)),
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
                    const Icon(
                      Icons.room_service_outlined,
                      size: 18,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.nombre,
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
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cant: ${s.cantidad}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
                if (s.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.descripcion,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Subtotal: \$${s.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Spacer(),
                    if (!esSoloLectura)
                      TextButton.icon(
                        onPressed: () => onCrearHitoDesdeServicio(s),
                        icon: const Icon(Icons.add_task, size: 16),
                        label: const Text(
                          'Programar hito',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
