import 'package:flutter/material.dart';

class FilaContactoWidget extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const FilaContactoWidget({
    super.key,
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icono, size: 15, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
            Icon(Icons.copy, size: 13, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
