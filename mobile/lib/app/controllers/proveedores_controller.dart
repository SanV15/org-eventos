import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../data/providers/proveedores_provider.dart';

typedef JsonMap = Map<String, dynamic>;

class ProveedoresController extends GetxController {
  final ProveedoresProvider _provider = ProveedoresProvider();

  final RxList<JsonMap> proveedores = <JsonMap>[].obs;
  final RxList<JsonMap> categoriasDisponibles = <JsonMap>[].obs;
  final RxMap<int, List<JsonMap>> serviciosPorProveedor =
      <int, List<JsonMap>>{}.obs;

  final RxBool isLoading = true.obs;
  final RxString textoBusqueda = ''.obs;
  final RxBool soloDisponibles = false.obs;
  final RxString categoriaSeleccionada = 'Todas'.obs;

  @override
  void onInit() {
    super.onInit();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    isLoading.value = true;
    try {
      final resultados = await Future.wait([
        _provider.obtenerCatalogoProveedores(),
        _provider.obtenerCategorias(),
      ]);

      final listaProv = List<JsonMap>.from(resultados[0]);
      final listaCat = List<JsonMap>.from(resultados[1]);

      final Map<int, List<JsonMap>> mapaServicios = {};
      await Future.wait(
        listaProv.map((p) async {
          final idProv = int.tryParse(p['idProveedor']?.toString() ?? '');
          if (idProv != null) {
            final servs = await _provider.obtenerServiciosPorProveedor(idProv);
            mapaServicios[idProv] = List<JsonMap>.from(servs);
          }
        }),
      );

      proveedores.assignAll(listaProv);
      categoriasDisponibles.assignAll(listaCat);
      serviciosPorProveedor.assignAll(mapaServicios);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el catálogo de proveedores');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recargarServiciosDe(int idProveedor) async {
    final servs = await _provider.obtenerServiciosPorProveedor(idProveedor);
    serviciosPorProveedor[idProveedor] = List<JsonMap>.from(servs);
    serviciosPorProveedor.refresh();
  }

  bool esActivo(dynamic valor) => valor == true || valor == 1;

  List<String> obtenerCategoriasProveedor(JsonMap p) {
    final raw = p['categorias'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['nombre'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<JsonMap> obtenerServiciosDe(JsonMap p) {
    final idProv = int.tryParse(p['idProveedor']?.toString() ?? '');
    if (idProv != null && serviciosPorProveedor.containsKey(idProv)) {
      return serviciosPorProveedor[idProv]!;
    }
    return [];
  }

  List<JsonMap> get proveedoresFiltrados {
    return proveedores.where((p) {
      final activo = esActivo(p['activo']);
      if (soloDisponibles.value && !activo) return false;

      final catsProv = obtenerCategoriasProveedor(p);
      if (categoriaSeleccionada.value != 'Todas' &&
          !catsProv.contains(categoriaSeleccionada.value)) {
        return false;
      }

      if (textoBusqueda.value.isNotEmpty) {
        final q = textoBusqueda.value.toLowerCase();
        final nombre = (p['nombreCompleto'] ?? '').toString().toLowerCase();
        final servicios = obtenerServiciosDe(p);
        final coincideServicio = servicios.any(
          (s) =>
              (s['nombreServicio'] ?? '').toString().toLowerCase().contains(q),
        );
        final coincideCategoria = catsProv.any(
          (c) => c.toLowerCase().contains(q),
        );

        if (!nombre.contains(q) && !coincideServicio && !coincideCategoria) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void copiarDato(String etiqueta, String valor) {
    Clipboard.setData(ClipboardData(text: valor));
    Get.snackbar(
      '$etiqueta copiado',
      valor,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<JsonMap?> obtenerDetalleProveedor(int idProveedor) {
    return _provider.obtenerProveedorPorId(idProveedor);
  }

  Future<bool> guardarProveedor({
    int? idProveedor,
    required JsonMap dto,
    String? rutaImagenNueva,
  }) async {
    final esEdicion = idProveedor != null;
    final ok = esEdicion
        ? await _provider.actualizarProveedor(idProveedor, dto)
        : await _provider.registrarProveedor(dto);

    if (ok && rutaImagenNueva != null && rutaImagenNueva.isNotEmpty) {
      int? idDestino = idProveedor;
      if (idDestino == null) {
        final lista = await _provider.obtenerCatalogoProveedores();
        for (final item in lista) {
          final idItem = int.tryParse(item['idProveedor']?.toString() ?? '');
          if (idItem != null && (idDestino == null || idItem > idDestino)) {
            idDestino = idItem;
          }
        }
      }
      if (idDestino != null) {
        await _provider.subirFotoProveedor(idDestino, rutaImagenNueva);
      }
    }

    if (ok) {
      await cargarDatos();
    }
    return ok;
  }

  Future<void> subirFotoRapida(int idProveedor, String rutaImagen) async {
    Get.snackbar(
      'Subiendo imagen...',
      'Guardando foto del proveedor',
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    final nuevaUrl = await _provider.subirFotoProveedor(
      idProveedor,
      rutaImagen,
    );

    if (nuevaUrl != null) {
      await cargarDatos();
      Get.snackbar(
        'Imagen actualizada',
        'La foto del proveedor se guardó correctamente',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } else {
      Get.snackbar('Error', 'No se pudo subir la imagen del proveedor');
    }
  }

  Future<void> toggleEstadoProveedor(JsonMap prov) async {
    final idProv = int.tryParse(prov['idProveedor']?.toString() ?? '');
    if (idProv == null) return;
    final nuevoEstado = !esActivo(prov['activo']);

    final ok = await _provider.cambiarEstadoProveedor(idProv, nuevoEstado);
    if (ok) {
      await cargarDatos();
      Get.snackbar(
        'Estado actualizado',
        nuevoEstado ? 'Proveedor activado' : 'Proveedor desactivado',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar('Error', 'No se pudo cambiar el estado del proveedor');
    }
  }

  Future<bool> guardarServicio({
    required int idProveedor,
    int? idServicio,
    required JsonMap dto,
  }) async {
    final ok = idServicio != null
        ? await _provider.actualizarServicio(idServicio, dto)
        : await _provider.agregarServicio(idProveedor, dto);

    if (ok) {
      await recargarServiciosDe(idProveedor);
    }
    return ok;
  }

  Future<void> toggleEstadoServicio(int idProveedor, JsonMap serv) async {
    final idServ = int.tryParse(serv['idServicioProveedor']?.toString() ?? '');
    if (idServ == null) return;
    final nuevoEstado = !esActivo(serv['activo']);

    final ok = await _provider.cambiarEstadoServicio(idServ, nuevoEstado);
    if (ok) {
      await recargarServiciosDe(idProveedor);
      Get.snackbar(
        'Servicio actualizado',
        nuevoEstado ? 'Servicio activado' : 'Servicio desactivado',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar('Error', 'No se pudo actualizar el estado del servicio');
    }
  }
}
