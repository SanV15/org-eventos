import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/modal_formulario_proveedor.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/modal_formulario_servicio.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/modal_opciones_foto_proveedor.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/proveedor_catalogo_card_widget.dart';
import '../../controllers/proveedores_controller.dart';

class CatalogoProveedoresView extends StatefulWidget {
  const CatalogoProveedoresView({super.key});

  @override
  State<CatalogoProveedoresView> createState() =>
      _CatalogoProveedoresViewState();
}

class _CatalogoProveedoresViewState extends State<CatalogoProveedoresView> {
  final ProveedoresController _ctrl = Get.put(ProveedoresController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormularioProveedor({
    Map<String, dynamic>? proveedorResumen,
  }) async {
    Map<String, dynamic>? detalle;
    if (proveedorResumen != null) {
      final idProv = int.tryParse(
        proveedorResumen['idProveedor']?.toString() ?? '',
      );
      if (idProv != null) {
        detalle = await _ctrl.obtenerDetalleProveedor(idProv);
      }
    }

    Get.bottomSheet(
      isScrollControlled: true,
      ModalFormularioProveedor(
        proveedorResumen: proveedorResumen,
        detalle: detalle,
      ),
    );
  }

  void _abrirFormularioServicio({
    required int idProveedor,
    Map<String, dynamic>? servicioExistente,
  }) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalFormularioServicio(
        idProveedor: idProveedor,
        servicioExistente: servicioExistente,
      ),
    );
  }

  void _abrirSelectorFotoRapida(int idProveedor) {
    Get.bottomSheet(
      ModalOpcionesFotoProveedor(
        onImagenSeleccionada: (ruta) =>
            _ctrl.subirFotoRapida(idProveedor, ruta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Catálogo de Proveedores',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioProveedor(),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Proveedor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                Obx(
                  () => TextField(
                    controller: _searchController,
                    onChanged: (val) => _ctrl.textoBusqueda.value = val.trim(),
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor, servicio o categoría...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _ctrl.textoBusqueda.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _ctrl.textoBusqueda.value = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Solo disponibles'),
                          selected: _ctrl.soloDisponibles.value,
                          selectedColor: const Color(
                            0xFF16A34A,
                          ).withOpacity(0.18),
                          checkmarkColor: const Color(0xFF16A34A),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ctrl.soloDisponibles.value
                                ? const Color(0xFF16A34A)
                                : Colors.black87,
                          ),
                          onSelected: (val) =>
                              _ctrl.soloDisponibles.value = val,
                        ),
                        if (_ctrl.categoriasDisponibles.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Todas'),
                            selected:
                                _ctrl.categoriaSeleccionada.value == 'Todas',
                            onSelected: (_) =>
                                _ctrl.categoriaSeleccionada.value = 'Todas',
                          ),
                          ..._ctrl.categoriasDisponibles.map((cat) {
                            final nombreCat = cat['nombre']?.toString() ?? '';
                            if (nombreCat.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(nombreCat),
                                selected:
                                    _ctrl.categoriaSeleccionada.value ==
                                    nombreCat,
                                onSelected: (_) =>
                                    _ctrl.categoriaSeleccionada.value =
                                        nombreCat,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtrados = _ctrl.proveedoresFiltrados;
              if (filtrados.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _ctrl.cargarDatos,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.22,
                      ),
                      Icon(
                        Icons.storefront_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'No se encontraron proveedores con ese filtro.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _ctrl.cargarDatos,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 85),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final prov = filtrados[index];
                    final idProv =
                        int.tryParse(prov['idProveedor']?.toString() ?? '') ??
                        0;
                    final nombre = (prov['nombreCompleto'] ?? 'Proveedor')
                        .toString();

                    return ProveedorCatalogoCardWidget(
                      proveedor: prov,
                      nombreCompleto: nombre,
                      activo: _ctrl.esActivo(prov['activo']),
                      categorias: _ctrl.obtenerCategoriasProveedor(prov),
                      servicios: _ctrl.obtenerServiciosDe(prov),
                      onCopiar: _ctrl.copiarDato,
                      onVerImagen: (url) =>
                          Get.dialog(VisorImagenCompletaDialog(urlImagen: url)),
                      onCambiarFoto: () => _abrirSelectorFotoRapida(idProv),
                      onEditarProveedor: () =>
                          _abrirFormularioProveedor(proveedorResumen: prov),
                      onToggleEstadoProveedor: () =>
                          _ctrl.toggleEstadoProveedor(prov),
                      onAgregarServicio: () =>
                          _abrirFormularioServicio(idProveedor: idProv),
                      onEditarServicio: (s) => _abrirFormularioServicio(
                        idProveedor: idProv,
                        servicioExistente: s,
                      ),
                      onToggleEstadoServicio: (s) =>
                          _ctrl.toggleEstadoServicio(idProv, s),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
