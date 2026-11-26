import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:org_eventos/app/data/models/evento_proveedor_operativo.dart';

class ModalCheckinProveedorWidget extends StatefulWidget {
  final EventoProveedorOperativo item;
  final Future<bool> Function({
    required String nuevoEstado,
    required String observaciones,
    String? rutaEvidencia,
  }) onGuardar;

  const ModalCheckinProveedorWidget({
    super.key,
    required this.item,
    required this.onGuardar,
  });

  static void mostrar({
    required EventoProveedorOperativo item,
    required Future<bool> Function({
      required String nuevoEstado,
      required String observaciones,
      String? rutaEvidencia,
    }) onGuardar,
  }) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalCheckinProveedorWidget(item: item, onGuardar: onGuardar),
    );
  }

  @override
  State<ModalCheckinProveedorWidget> createState() =>
      _ModalCheckinProveedorWidgetState();
}

class _ModalCheckinProveedorWidgetState
    extends State<ModalCheckinProveedorWidget> {
  static const _estados = ['Pendiente', 'En sitio', 'Retrasado', 'Completado'];

  late String _estadoSeleccionado;
  late TextEditingController _obsController;
  String? _rutaEvidencia;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = _estados.contains(widget.item.estadoOperativo)
        ? widget.item.estadoOperativo
        : 'Pendiente';
    _obsController = TextEditingController(text: widget.item.observaciones);
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _adjuntarFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (foto != null && mounted) {
      setState(() => _rutaEvidencia = foto.path);
    }
  }

Future<void> _submit() async {
    setState(() => _guardando = true);
    final exito = await widget.onGuardar(
      nuevoEstado: _estadoSeleccionado,
      observaciones: _obsController.text,
      rutaEvidencia: _rutaEvidencia,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (exito) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.nombreServicio,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.item.nombreProveedor,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Estado Operativo en Sitio',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _estados.map((estado) {
                final seleccionado = _estadoSeleccionado == estado;
                return ChoiceChip(
                  label: Text(estado),
                  selected: seleccionado,
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: seleccionado
                        ? Colors.blueAccent.shade700
                        : Colors.black87,
                  ),
                  onSelected: (_) =>
                      setState(() => _estadoSeleccionado = estado),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones de llegada / entrega',
                hintText: 'Ej. Llegó puntual con equipo completo...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_rutaEvidencia != null)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Fotografía de recepción adjunta',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    onPressed: () => setState(() => _rutaEvidencia = null),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _adjuntarFoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Evidencia fotográfica (Opcional)'),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando ? null : _submit,
                icon: const Icon(
                  Icons.how_to_reg_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  _guardando ? 'Guardando...' : 'Confirmar Registro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}