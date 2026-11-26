import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/evento_proveedor_operativo.dart';
import '../data/providers/proveedores_provider.dart';

class CheckinProveedoresController extends GetxController {
  final ProveedoresProvider _provider = ProveedoresProvider();

  final proveedores = <EventoProveedorOperativo>[].obs;
  final isLoading = false.obs;
  final filtroEstado = 'Todos'.obs;
  final terminoBusqueda = ''.obs;
  final procesandoIds = <int>{}.obs;
  final idEventoSeleccionado = RxnInt();

  List<EventoProveedorOperativo> get proveedoresFiltrados {
    return proveedores.where((item) {
      final coincideEstado =
          filtroEstado.value == 'Todos' ||
          item.estadoOperativo == filtroEstado.value;

      final query = terminoBusqueda.value.toLowerCase().trim();
      final coincideTexto =
          query.isEmpty ||
          item.nombreProveedor.toLowerCase().contains(query) ||
          item.nombreServicio.toLowerCase().contains(query) ||
          item.nombreEvento.toLowerCase().contains(query);

      return coincideEstado && coincideTexto;
    }).toList();
  }

  int get totalPendientes =>
      proveedores.where((p) => p.estadoOperativo == 'Pendiente').length;
  int get totalEnSitio =>
      proveedores.where((p) => p.estadoOperativo == 'En sitio').length;
  int get totalRetrasados =>
      proveedores.where((p) => p.estadoOperativo == 'Retrasado').length;
  int get totalCompletados =>
      proveedores.where((p) => p.estadoOperativo == 'Completado').length;

  Future<void> cargarPorEvento(int idEvento) async {
    idEventoSeleccionado.value = idEvento;
    try {
      isLoading(true);
      final raw = await _provider.obtenerProveedoresPorEvento(idEvento);
      proveedores.assignAll(
        raw.map((e) => EventoProveedorOperativo.fromJson(e)).toList(),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los proveedores del evento');
    } finally {
      isLoading(false);
    }
  }

  Future<void> marcarEnSitioRapido(EventoProveedorOperativo item) async {
    await actualizarCheckIn(
      item: item,
      nuevoEstado: 'En sitio',
      observaciones: item.observaciones,
    );
  }

  Future<bool> actualizarCheckIn({
    required EventoProveedorOperativo item,
    required String nuevoEstado,
    required String observaciones,
    String? rutaEvidencia,
  }) async {
    procesandoIds.add(item.idEventoProveedor);
    try {
      final ok = await _provider.registrarCheckIn(
        idEventoProveedor: item.idEventoProveedor,
        estadoOperativo: nuevoEstado,
        observaciones: observaciones.trim(),
        registrarHoraLlegada:
            nuevoEstado == 'En sitio' && item.horaLlegada == null,
      );

      if (!ok) {
        
        Get.snackbar('Error', 'No se pudo actualizar el estado del proveedor');
        return false;
      }

      String? urlEvidenciaFinal = item.evidenciaUrl;
      if (rutaEvidencia != null && rutaEvidencia.isNotEmpty) {
        final urlSubida = await _provider.subirEvidenciaCheckIn(
          idEventoProveedor: item.idEventoProveedor,
          rutaImagen: rutaEvidencia,
        );
        if (urlSubida != null && urlSubida.isNotEmpty) {
          urlEvidenciaFinal = urlSubida;
        }
      }

      item.estadoOperativo = nuevoEstado;
      item.observaciones = observaciones.trim();
      item.evidenciaUrl = urlEvidenciaFinal;
      if (nuevoEstado == 'En sitio' && item.horaLlegada == null) {
        item.horaLlegada = DateTime.now();
      }
      if (nuevoEstado == 'Completado' && item.horaSalida == null) {
        item.horaSalida = DateTime.now();
      }
      proveedores.refresh();

      Get.snackbar(
        'Check-in Actualizado',
        '${item.nombreProveedor} → $nuevoEstado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (_) {
      
      Get.snackbar('Error', 'Fallo de conexión con el servidor');
      return false;
    } finally {
      procesandoIds.remove(item.idEventoProveedor);
    }
  }
}
