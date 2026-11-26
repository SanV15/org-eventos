import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:org_eventos/app/controllers/proveedores_controller.dart';

class ModalFormularioProveedor extends StatefulWidget {
  final Map<String, dynamic>? proveedorResumen;
  final Map<String, dynamic>? detalle;

  const ModalFormularioProveedor({
    super.key,
    this.proveedorResumen,
    this.detalle,
  });

  @override
  State<ModalFormularioProveedor> createState() =>
      _ModalFormularioProveedorState();
}

class _ModalFormularioProveedorState extends State<ModalFormularioProveedor> {
  final ProveedoresController _ctrl = Get.find<ProveedoresController>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _paternoCtrl;
  late final TextEditingController _maternoCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _dirCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _bancoCtrl;
  late final TextEditingController _clabeCtrl;
  late final TextEditingController _titularCtrl;

  final Set<int> _catsSeleccionadas = {};
  File? _archivoFotoNueva;
  bool _guardando = false;

  bool get _esEdicion => widget.proveedorResumen != null;

  int? get _idProveedor => _esEdicion
      ? int.tryParse(widget.proveedorResumen!['idProveedor']?.toString() ?? '')
      : null;

  String get _fotoUrlActual => (widget.detalle?['fotoProveedorUrl'] ??
          widget.proveedorResumen?['fotoProveedorUrl'] ??
          '')
      .toString();

  @override
  void initState() {
    super.initState();
    final d = widget.detalle;
    final r = widget.proveedorResumen;

_nombreCtrl = TextEditingController(
      text:
          d?['nombre']?.toString() ??
          (_esEdicion ? (r?['nombreCompleto']?.toString() ?? '') : ''),
    );
    _paternoCtrl =
        TextEditingController(text: d?['apellidoPaterno']?.toString() ?? '');
    _maternoCtrl =
        TextEditingController(text: d?['apellidoMaterno']?.toString() ?? '');
    _telCtrl = TextEditingController(
      text: d?['telefono']?.toString() ?? r?['telefono']?.toString() ?? '',
    );
    _correoCtrl = TextEditingController(
      text: d?['correo']?.toString() ?? r?['correo']?.toString() ?? '',
    );
    _dirCtrl = TextEditingController(text: d?['direccion']?.toString() ?? '');
    _descCtrl =
        TextEditingController(text: d?['descripcion']?.toString() ?? '');
    _bancoCtrl = TextEditingController(text: d?['banco']?.toString() ?? '');
    _clabeCtrl = TextEditingController(
      text: d?['clabeInterbancaria']?.toString() ?? '',
    );
    _titularCtrl =
        TextEditingController(text: d?['titularCuenta']?.toString() ?? '');

    if (d != null && d['categoriasIds'] is List) {
      for (final id in d['categoriasIds']) {
        final parsed = int.tryParse(id.toString());
        if (parsed != null) _catsSeleccionadas.add(parsed);
      }
    } else if (_esEdicion && r != null) {
      final nombresCats = _ctrl.obtenerCategoriasProveedor(r);
      for (final cat in _ctrl.categoriasDisponibles) {
        final idCat = int.tryParse(cat['idCategoria']?.toString() ?? '');
        if (idCat != null && nombresCats.contains(cat['nombre']?.toString())) {
          _catsSeleccionadas.add(idCat);
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _paternoCtrl.dispose();
    _maternoCtrl.dispose();
    _telCtrl.dispose();
    _correoCtrl.dispose();
    _dirCtrl.dispose();
    _descCtrl.dispose();
    _bancoCtrl.dispose();
    _clabeCtrl.dispose();
    _titularCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _archivoFotoNueva = File(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      Get.snackbar('Campo requerido', 'Ingresa el nombre del proveedor');
      return;
    }

    setState(() => _guardando = true);

    final dto = {
      'nombre': _nombreCtrl.text.trim(),
      'apellidoPaterno': _paternoCtrl.text.trim(),
      'apellidoMaterno': _maternoCtrl.text.trim(),
      'telefono': _telCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'direccion': _dirCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'banco': _bancoCtrl.text.trim(),
      'clabeInterbancaria': _clabeCtrl.text.trim(),
      'titularCuenta': _titularCtrl.text.trim(),
      'categoriasIds': _catsSeleccionadas.toList(),
    };

    final ok = await _ctrl.guardarProveedor(
      idProveedor: _idProveedor,
      dto: dto,
      rutaImagenNueva: _archivoFotoNueva?.path,
    );

    if (mounted) setState(() => _guardando = false);

    if (ok) {
      Get.back();
      Get.snackbar(
        'Guardado',
        _esEdicion
            ? 'Proveedor actualizado correctamente'
            : 'Proveedor registrado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('Error', 'No se pudo guardar el proveedor');
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? bgImage;
    if (_archivoFotoNueva != null) {
      bgImage = FileImage(_archivoFotoNueva!);
    } else if (_fotoUrlActual.isNotEmpty) {
      bgImage = NetworkImage(_fotoUrlActual);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
                  _esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
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
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blueAccent.withOpacity(0.12),
                    backgroundImage: bgImage,
                    child: bgImage == null
                        ? const Icon(
                            Icons.storefront_outlined,
                            size: 32,
                            color: Colors.blueAccent,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _seleccionarFoto(ImageSource.gallery),
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Galería',
                            style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () => _seleccionarFoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: const Text('Cámara',
                            style: TextStyle(fontSize: 12)),
                      ),
                      if (_archivoFotoNueva != null)
                        IconButton(
                          tooltip: 'Quitar selección',
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              setState(() => _archivoFotoNueva = null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre o Razón Social *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paternoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Paterno',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maternoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Materno',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dirCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción general',
                border: OutlineInputBorder(),
              ),
            ),
            if (_ctrl.categoriasDisponibles.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Categorías',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _ctrl.categoriasDisponibles.map((cat) {
                  final idCat =
                      int.tryParse(cat['idCategoria']?.toString() ?? '') ?? 0;
                  final seleccionada = _catsSeleccionadas.contains(idCat);
                  return FilterChip(
                    label: Text(cat['nombre']?.toString() ?? ''),
                    selected: seleccionada,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _catsSeleccionadas.add(idCat);
                        } else {
                          _catsSeleccionadas.remove(idCat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Datos Bancarios (Opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              children: [
                TextField(
                  controller: _bancoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Banco',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _clabeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CLABE Interbancaria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titularCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titular de la Cuenta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 14),
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
                          ? 'Actualizar Proveedor'
                          : 'Registrar Proveedor'),
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