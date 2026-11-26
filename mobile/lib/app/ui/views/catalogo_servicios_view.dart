import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/ui/views/widgets/servicios/modal_form_servicio_propio_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/servicios/servicio_propio_card_widget.dart';
import '../../controllers/servicios_propios_controller.dart';

class CatalogoServiciosView extends StatelessWidget {
  CatalogoServiciosView({super.key});

  final ServiciosPropiosController ctrl =
      Get.isRegistered<ServiciosPropiosController>()
      ? Get.find<ServiciosPropiosController>()
      : Get.put(ServiciosPropiosController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Servicios de la Empresa',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ModalFormServicioPropioWidget.mostrar(
          onGuardar:
              ({required nombre, required descripcion, required precio}) =>
                  ctrl.guardarServicio(
                    nombre: nombre,
                    descripcion: descripcion,
                    precio: precio,
                  ),
        ),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Servicio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => ctrl.busqueda.value = v,
                  decoration: InputDecoration(
                    hintText: 'Buscar servicio propio...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Row(
                    children: [
                      FilterChip(
                        label: const Text('Solo activos'),
                        selected: ctrl.soloActivos.value,
                        selectedColor: Colors.blueAccent.withOpacity(0.18),
                        onSelected: (v) => ctrl.soloActivos.value = v,
                      ),
                      const Spacer(),
                      Text(
                        '${ctrl.serviciosFiltrados.length} servicios',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.servicios.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final lista = ctrl.serviciosFiltrados;
              if (lista.isEmpty) {
                return RefreshIndicator(
                  onRefresh: ctrl.cargarServicios,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.22,
                      ),
                      Icon(
                        Icons.room_service_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'No hay servicios registrados en este filtro.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: ctrl.cargarServicios,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final item = lista[index];
                    return ServicioPropioCardWidget(
                      servicio: item,
                      cambiandoEstado: ctrl.idsEnCambioEstado.contains(
                        item.idServicio,
                      ),
                      onEditar: () => ModalFormServicioPropioWidget.mostrar(
                        servicio: item,
                        onGuardar:
                            ({
                              required nombre,
                              required descripcion,
                              required precio,
                            }) => ctrl.guardarServicio(
                              servicioExistente: item,
                              nombre: nombre,
                              descripcion: descripcion,
                              precio: precio,
                            ),
                      ),
                      onToggleEstado: () => ctrl.alternarEstado(item),
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
