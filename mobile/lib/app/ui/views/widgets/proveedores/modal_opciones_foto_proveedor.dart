import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ModalOpcionesFotoProveedor extends StatelessWidget {
  final void Function(String rutaImagen) onImagenSeleccionada;

  const ModalOpcionesFotoProveedor({
    super.key,
    required this.onImagenSeleccionada,
  });

  Future<void> _seleccionar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      Get.back();
      onImagenSeleccionada(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Imagen del Proveedor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: Colors.blueAccent,
            ),
            title: const Text('Elegir de la galería'),
            onTap: () => _seleccionar(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_camera_outlined,
              color: Colors.blueAccent,
            ),
            title: const Text('Tomar foto con cámara'),
            onTap: () => _seleccionar(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class VisorImagenCompletaDialog extends StatelessWidget {
  final String urlImagen;

  const VisorImagenCompletaDialog({super.key, required this.urlImagen});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.92),
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(urlImagen, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}
