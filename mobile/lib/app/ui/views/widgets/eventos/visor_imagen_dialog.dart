import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VisorImagenDialog extends StatelessWidget {
  final String urlImagen;

  const VisorImagenDialog({super.key, required this.urlImagen});

  static void mostrar(String url) {
    Get.dialog(VisorImagenDialog(urlImagen: url));
  }

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
