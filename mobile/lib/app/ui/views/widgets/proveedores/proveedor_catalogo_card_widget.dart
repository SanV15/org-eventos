import 'package:flutter/material.dart';
import 'avatar_proveedor_widget.dart';
import 'fila_contacto_widget.dart';
import 'servicio_proveedor_item_widget.dart';

typedef JsonMap = Map<String, dynamic>;

class ProveedorCatalogoCardWidget extends StatelessWidget {
  final JsonMap proveedor;
  final String nombreCompleto;
  final bool activo;
  final List<String> categorias;
  final List<JsonMap> servicios;
  final void Function(String etiqueta, String valor) onCopiar;
  final void Function(String url) onVerImagen;
  final VoidCallback onCambiarFoto;
  final VoidCallback onEditarProveedor;
  final VoidCallback onToggleEstadoProveedor;
  final VoidCallback onAgregarServicio;
  final void Function(JsonMap servicio) onEditarServicio;
  final void Function(JsonMap servicio) onToggleEstadoServicio;

  const ProveedorCatalogoCardWidget({
    super.key,
    required this.proveedor,
    required this.nombreCompleto,
    required this.activo,
    required this.categorias,
    required this.servicios,
    required this.onCopiar,
    required this.onVerImagen,
    required this.onCambiarFoto,
    required this.onEditarProveedor,
    required this.onToggleEstadoProveedor,
    required this.onAgregarServicio,
    required this.onEditarServicio,
    required this.onToggleEstadoServicio,
  });

  @override
  Widget build(BuildContext context) {
    final telefono = proveedor['telefono']?.toString() ?? '';
    final correo = proveedor['correo']?.toString() ?? '';
    final fotoUrl = proveedor['fotoProveedorUrl']?.toString() ?? '';
    final colorEstado = activo ? const Color(0xFF16A34A) : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: activo
                ? Colors.blueAccent.withOpacity(0.25)
                : Colors.grey.shade300,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: AvatarProveedorWidget(
              fotoUrl: fotoUrl,
              nombreCompleto: nombreCompleto,
              onTapConFoto: () => onVerImagen(fotoUrl),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activo ? 'Disponible' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${servicios.length} ${servicios.length == 1 ? 'servicio registrado' : 'servicios registrados'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (categorias.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: categorias
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            children: [
              const Divider(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCambiarFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 15),
                    label: const Text('Foto', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEditarProveedor,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleEstadoProveedor,
                    icon: Icon(
                      activo
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 15,
                      color: activo ? Colors.redAccent : Colors.green,
                    ),
                    label: Text(
                      activo ? 'Desactivar' : 'Activar',
                      style: TextStyle(
                        fontSize: 12,
                        color: activo ? Colors.redAccent : Colors.green,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (telefono.isNotEmpty)
                FilaContactoWidget(
                  icono: Icons.phone_outlined,
                  texto: telefono,
                  onTap: () => onCopiar('Teléfono', telefono),
                ),
              if (correo.isNotEmpty)
                FilaContactoWidget(
                  icono: Icons.email_outlined,
                  texto: correo,
                  onTap: () => onCopiar('Correo', correo),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Servicios y Tarifas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAgregarServicio,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text(
                      'Agregar servicio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (servicios.isEmpty)
                Text(
                  'Sin servicios cargados en el catálogo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                )
              else
                ...servicios.map(
                  (s) => ServicioProveedorItemWidget(
                    servicio: s,
                    onEditar: () => onEditarServicio(s),
                    onToggleEstado: () => onToggleEstadoServicio(s),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
