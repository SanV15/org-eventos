import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:org_eventos/app/controllers/tareas_controller.dart';
import 'package:org_eventos/app/data/models/tarea_operativa.dart';

class ModalReportarIncidencia extends StatefulWidget {
  final TareasController controller;
  final TareaOperativa tarea;

  const ModalReportarIncidencia({
    super.key,
    required this.controller,
    required this.tarea,
  });

  static void mostrar(TareasController controller, TareaOperativa tarea) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalReportarIncidencia(controller: controller, tarea: tarea),
    );
  }

  @override
  State<ModalReportarIncidencia> createState() =>
      _ModalReportarIncidenciaState();
}

class _ModalReportarIncidenciaState extends State<ModalReportarIncidencia> {
  final TextEditingController _obsController = TextEditingController();
  String _rutaImagen = '';

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _tomarEvidencia() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (imagen != null && mounted) {
      setState(() => _rutaImagen = imagen.path);
    }
  }

  void _enviar() {
    final texto = _obsController.text.trim();
    if (texto.isEmpty) return;
    Get.back();

    widget.controller.registrarIncidencia(
      widget.tarea.idTarea,
      texto,
      _rutaImagen.isEmpty ? null : _rutaImagen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Wrap(
          children: [
            Text(
              'Incidencia · ${widget.tarea.nombreTarea}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Describa el imprevisto (ej. Retraso de proveedor...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            if (_rutaImagen.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Fotografía de evidencia adjunta'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _rutaImagen = ''),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _tomarEvidencia,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Adjuntar Evidencia Fotográfica'),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _enviar,
                child: const Text(
                  'Enviar Reporte al Centro de Mando',
                  style: TextStyle(
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
