import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/data/models/servicio_propio_model.dart';

class ModalFormServicioPropioWidget extends StatefulWidget {
  final ServicioPropioModel? servicio;
  final Future<bool> Function({
    required String nombre,
    required String descripcion,
    required double precio,
  })
  onGuardar;

  const ModalFormServicioPropioWidget({
    super.key,
    this.servicio,
    required this.onGuardar,
  });

  static void mostrar({
    ServicioPropioModel? servicio,
    required Future<bool> Function({
      required String nombre,
      required String descripcion,
      required double precio,
    })
    onGuardar,
  }) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalFormServicioPropioWidget(servicio: servicio, onGuardar: onGuardar),
    );
  }

  @override
  State<ModalFormServicioPropioWidget> createState() =>
      _ModalFormServicioPropioWidgetState();
}

class _ModalFormServicioPropioWidgetState
    extends State<ModalFormServicioPropioWidget> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _precioCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.servicio?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.servicio?.descripcion ?? '');
    _precioCtrl = TextEditingController(
      text: widget.servicio != null
          ? widget.servicio!.precio.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nombre = _nombreCtrl.text.trim();
    final precioLimpio = _precioCtrl.text.trim().replaceAll(',', '.');
    final precio = double.tryParse(precioLimpio);

    if (nombre.isEmpty) {
      Get.snackbar('Atención', 'El nombre del servicio es obligatorio');
      return;
    }
    if (precio == null || precio < 0) {
      Get.snackbar('Atención', 'Ingresa un precio válido');
      return;
    }

    setState(() => _guardando = true);
    final ok = await widget.onGuardar(
      nombre: nombre,
      descripcion: _descCtrl.text.trim(),
      precio: precio,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.servicio != null;

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
                  child: Text(
                    esEdicion ? 'Editar Servicio' : 'Nuevo Servicio Propio',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
                hintText: 'Ej. Coordinación general en sitio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Alcance o detalles operativos del servicio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio base (\$)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando ? null : _submit,
                child: Text(
                  _guardando
                      ? 'Guardando...'
                      : (esEdicion ? 'Guardar Cambios' : 'Registrar Servicio'),
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
