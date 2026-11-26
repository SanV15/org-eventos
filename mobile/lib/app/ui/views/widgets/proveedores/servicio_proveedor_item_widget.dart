import 'package:flutter/material.dart';

class ServicioProveedorItemWidget extends StatelessWidget {
  final Map<String, dynamic> servicio;
  final VoidCallback onEditar;
  final VoidCallback onToggleEstado;

  const ServicioProveedorItemWidget({
    super.key,
    required this.servicio,
    required this.onEditar,
    required this.onToggleEstado,
  });

  @override
  Widget build(BuildContext context) {
    final servActivo = servicio['activo'] == true || servicio['activo'] == 1;
    final ocupadoHoy =
        servicio['estaOcupadoHoy'] == true || servicio['estaOcupadoHoy'] == 1;
    final eventoActual = servicio['nombreEventoActual']?.toString() ?? '';
    final costo = servicio['costo'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ocupadoHoy ? Colors.orange.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 9,
                color: servActivo ? const Color(0xFF16A34A) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  servicio['nombreServicio']?.toString() ?? 'Servicio',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: servActivo ? null : TextDecoration.lineThrough,
                    color: servActivo ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
              if (costo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$$costo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
            ],
          ),
          if (servicio['descripcion'] != null &&
              servicio['descripcion'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              servicio['descripcion'].toString(),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          if (ocupadoHoy) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                eventoActual.isNotEmpty
                    ? 'Ocupado hoy · $eventoActual'
                    : 'Ocupado hoy en otro evento',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEditar,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onToggleEstado,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    servActivo ? 'Desactivar' : 'Activar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: servActivo ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
