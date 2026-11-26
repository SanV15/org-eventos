import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/servicio_propio_model.dart';
import '../data/providers/servicios_propios_provider.dart';

class ServiciosPropiosController extends GetxController {
  final ServiciosPropiosProvider _provider = ServiciosPropiosProvider();

  final servicios = <ServicioPropioModel>[].obs;
  final isLoading = false.obs;
  final busqueda = ''.obs;
  final soloActivos = false.obs;
  final idsEnCambioEstado = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    cargarServicios();
  }

  List<ServicioPropioModel> get serviciosFiltrados {
    final query = busqueda.value.toLowerCase().trim();
    return servicios.where((s) {
      if (soloActivos.value && !s.activo) return false;
      if (query.isEmpty) return true;
      return s.nombre.toLowerCase().contains(query) ||
          s.descripcion.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> cargarServicios() async {
    try {
      isLoading(true);
      final lista = await _provider.obtenerServicios();
      servicios.assignAll(lista);
    } catch (_) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los servicios de la empresa',
      );
    } finally {
      isLoading(false);
    }
  }

  Future<bool> guardarServicio({
    ServicioPropioModel? servicioExistente,
    required String nombre,
    required String descripcion,
    required double precio,
  }) async {
    try {
      final ok = servicioExistente == null
          ? await _provider.crearServicio(
              nombre: nombre,
              descripcion: descripcion,
              precio: precio,
            )
          : await _provider.actualizarServicio(
              idServicio: servicioExistente.idServicio,
              nombre: nombre,
              descripcion: descripcion,
              precio: precio,
            );

      if (!ok) {
        Get.snackbar('Error', 'No se pudo guardar el servicio');
        return false;
      }

      await cargarServicios();
      Get.snackbar(
        'Éxito',
        servicioExistente == null
            ? 'Servicio registrado correctamente'
            : 'Servicio actualizado correctamente',
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
      );
      return true;
    } catch (_) {
      Get.snackbar('Error', 'Fallo de conexión al guardar el servicio');
      return false;
    }
  }

  Future<void> alternarEstado(ServicioPropioModel servicio) async {
    final nuevoEstado = !servicio.activo;
    idsEnCambioEstado.add(servicio.idServicio);
    try {
      final ok = await _provider.cambiarEstado(
        idServicio: servicio.idServicio,
        activo: nuevoEstado,
      );
      if (!ok) {
        Get.snackbar('Error', 'No se pudo cambiar el estado del servicio');
        return;
      }
      await cargarServicios();
      Get.snackbar(
        'Estado actualizado',
        nuevoEstado ? 'Servicio activado' : 'Servicio desactivado',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar('Error', 'Fallo de conexión al cambiar estado');
    } finally {
      idsEnCambioEstado.remove(servicio.idServicio);
    }
  }
}
