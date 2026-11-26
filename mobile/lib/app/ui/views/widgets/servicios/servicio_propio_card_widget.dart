import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/servicio_propio_model.dart';

class ServicioPropioCardWidget extends StatelessWidget {
  final ServicioPropioModel servicio;
  final bool cambiandoEstado;
  final VoidCallback onEditar;
  final VoidCallback onToggleEstado;

  const ServicioPropioCardWidget({
    super.key,
    required this.servicio,
    this.cambiandoEstado = false,
    required this.onEditar,
    required this.onToggleEstado,
  });

  @override
  Widget build(BuildContext context) {
    final colorEstado = servicio.activo
        ? const Color(0xFF16A34A)
        : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: servicio.activo
              ? Colors.blueAccent.withOpacity(0.25)
              : Colors.grey.shade300,
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
                  servicio.nombre,
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
                  color: colorEstado.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  servicio.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorEstado,
                  ),
                ),
              ),
            ],
          ),
          if (servicio.descripcion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              servicio.descripcion,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              Text(
                '\$${servicio.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: cambiandoEstado ? null : onEditar,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Editar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              cambiandoEstado
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: servicio.activo,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (_) => onToggleEstado(),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
