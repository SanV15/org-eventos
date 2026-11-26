import 'package:flutter/material.dart';

class AvatarProveedorWidget extends StatefulWidget {
  final String fotoUrl;
  final String nombreCompleto;
  final VoidCallback? onTapConFoto;

  const AvatarProveedorWidget({
    super.key,
    required this.fotoUrl,
    required this.nombreCompleto,
    this.onTapConFoto,
  });

  @override
  State<AvatarProveedorWidget> createState() => _AvatarProveedorWidgetState();
}

class _AvatarProveedorWidgetState extends State<AvatarProveedorWidget> {
  bool _errorCarga = false;

  @override
  void didUpdateWidget(covariant AvatarProveedorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoUrl != widget.fotoUrl) {
      _errorCarga = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneFoto = widget.fotoUrl.isNotEmpty && !_errorCarga;

    return GestureDetector(
      onTap: tieneFoto ? widget.onTapConFoto : null,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.blueAccent.withOpacity(0.12),
        backgroundImage: tieneFoto ? NetworkImage(widget.fotoUrl) : null,
        onBackgroundImageError: tieneFoto
            ? (_, __) {
                if (mounted) setState(() => _errorCarga = true);
              }
            : null,
        child: !tieneFoto
            ? Text(
                widget.nombreCompleto.isNotEmpty
                    ? widget.nombreCompleto[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              )
            : null,
      ),
    );
  }
}
