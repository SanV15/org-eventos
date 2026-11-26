import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/controllers/proveedores_controller.dart';

class ModalFormularioServicio extends StatefulWidget {
  final int idProveedor;
  final Map<String, dynamic>? servicioExistente;

  const ModalFormularioServicio({
    super.key,
    required this.idProveedor,
    this.servicioExistente,
  });

  @override
  State<ModalFormularioServicio> createState() =>
      _ModalFormularioServicioState();
}

class _ModalFormularioServicioState extends State<ModalFormularioServicio> {
  final ProveedoresController _ctrl = Get.find<ProveedoresController>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _costoCtrl;
  bool _guardando = false;

  bool get _esEdicion => widget.servicioExistente != null;

  int? get _idServicio => _esEdicion
      ? int.tryParse(
          widget.servicioExistente!['idServicioProveedor']?.toString() ?? '',
        )
      : null;

  @override
  void initState() {
    super.initState();
    final s = widget.servicioExistente;
    _nombreCtrl = TextEditingController(
      text: s?['nombreServicio']?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: s?['descripcion']?.toString() ?? '',
    );
    _costoCtrl = TextEditingController(text: s?['costo']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final costo = double.tryParse(_costoCtrl.text.trim());
    if (_nombreCtrl.text.trim().isEmpty || costo == null) {
      Get.snackbar(
        'Datos incompletos',
        'Ingresa nombre y costo válido del servicio',
      );
      return;
    }

    setState(() => _guardando = true);
    final dto = {
      'nombreServicio': _nombreCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'costo': costo,
    };

    final ok = await _ctrl.guardarServicio(
      idProveedor: widget.idProveedor,
      idServicio: _idServicio,
      dto: dto,
    );

    if (mounted) setState(() => _guardando = false);

    if (ok) {
      Get.back();
      Get.snackbar(
        'Guardado',
        _esEdicion ? 'Servicio actualizado' : 'Servicio agregado al proveedor',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('Error', 'No se pudo guardar el servicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _esEdicion ? 'Editar Servicio' : 'Nuevo Servicio',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Servicio *',
                hintText: 'Ej. Banquete 3 tiempos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Costo / Tarifa *',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción / Incluye',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando ? null : _guardar,
                child: Text(
                  _guardando
                      ? 'Guardando...'
                      : (_esEdicion
                            ? 'Actualizar Servicio'
                            : 'Agregar Servicio'),
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
