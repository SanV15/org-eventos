import 'package:flutter/material.dart';

class BotonTranslucidoWidget extends StatelessWidget {
  final IconData icono;
  final String? label;
  final String? tooltip;
  final VoidCallback? onTap;

  const BotonTranslucidoWidget({
    super.key,
    required this.icono,
    this.label,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 10 : 7,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 15, color: Colors.white),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: child) : child;
  }
}
