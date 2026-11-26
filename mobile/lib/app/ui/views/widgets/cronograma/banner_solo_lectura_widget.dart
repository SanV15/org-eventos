import 'package:flutter/material.dart';

class BannerSoloLecturaWidget extends StatelessWidget {
  const BannerSoloLecturaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade300,
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: Colors.grey.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Evento finalizado · Modo solo lectura.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
