import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'boton_translucido_widget.dart';
import 'visor_imagen_dialog.dart';

class EventoBannerCanvasWidget extends StatefulWidget {
  final int idEvento;
  final String titulo;
  final String subtitulo;
  final String? fotoUrl;
  final bool puedeEditar;
  final bool subiendoFoto;
  final bool mostrarBordeInferior;
  final double alturaConFoto;
  final BorderRadius borderRadius;
  final Widget? trailing;
  final VoidCallback? onTapCabecera;
  final void Function(String rutaImagen)? onImagenSeleccionada;

  const EventoBannerCanvasWidget({
    super.key,
    required this.idEvento,
    required this.titulo,
    required this.subtitulo,
    this.fotoUrl,
    this.puedeEditar = true,
    this.subiendoFoto = false,
    this.mostrarBordeInferior = false,
    this.alturaConFoto = 135,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.trailing,
    this.onTapCabecera,
    this.onImagenSeleccionada,
  });

  @override
  State<EventoBannerCanvasWidget> createState() =>
      _EventoBannerCanvasWidgetState();
}

class _EventoBannerCanvasWidgetState extends State<EventoBannerCanvasWidget> {
  bool _errorCarga = false;

  @override
  void didUpdateWidget(covariant EventoBannerCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoUrl != widget.fotoUrl) {
      _errorCarga = false;
    }
  }

  void _abrirSelectorOrigen() {
    if (widget.onImagenSeleccionada == null) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Imagen de Referencia del Evento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Colors.blueAccent,
              ),
              title: const Text('Elegir de la galería'),
              onTap: () => _pick(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: Colors.blueAccent,
              ),
              title: const Text('Tomar foto con cámara'),
              onTap: () => _pick(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      Get.back();
      widget.onImagenSeleccionada?.call(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.fotoUrl?.trim() ?? '';
    final tieneFoto = url.isNotEmpty && !_errorCarga;

    if (tieneFoto) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.alturaConFoto,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap:
                    widget.onTapCabecera ??
                    () => VisorImagenDialog.mostrar(url),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_errorCarga) {
                        setState(() => _errorCarga = true);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotonTranslucidoWidget(
                      icono: Icons.fullscreen,
                      tooltip: 'Ver imagen completa',
                      onTap: () => VisorImagenDialog.mostrar(url),
                    ),
                    if (widget.puedeEditar &&
                        widget.onImagenSeleccionada != null) ...[
                      const SizedBox(width: 6),
                      BotonTranslucidoWidget(
                        icono: Icons.photo_camera_outlined,
                        label: widget.subiendoFoto ? 'Subiendo...' : 'Foto',
                        onTap: widget.subiendoFoto
                            ? null
                            : _abrirSelectorOrigen,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: GestureDetector(
                  onTap: widget.onTapCabecera,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          '#${widget.idEvento}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.subtitulo.isNotEmpty)
                              Text(
                                widget.subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.trailing != null) ...[
                        const SizedBox(width: 6),
                        IconTheme(
                          data: const IconThemeData(color: Colors.white),
                          child: widget.trailing!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Cabecera resaltada sin imagen
    return InkWell(
      onTap: widget.onTapCabecera,
      borderRadius: widget.borderRadius,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
          ),
          border: widget.mostrarBordeInferior
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFBFDBFE), width: 1),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#${widget.idEvento}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B5998),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.puedeEditar && widget.onImagenSeleccionada != null)
              IconButton(
                tooltip: 'Agregar foto del evento',
                onPressed: widget.subiendoFoto ? null : _abrirSelectorOrigen,
                icon: widget.subiendoFoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        size: 20,
                        color: Color(0xFF1D4ED8),
                      ),
              ),
            if (widget.trailing != null)
              IconTheme(
                data: const IconThemeData(color: Color(0xFF1E3A8A)),
                child: widget.trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
