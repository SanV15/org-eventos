import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/controllers/check_in_proveedores_controller.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/check_in/modal_checkin_proveedor_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/check_in/proveedor_checkin_card_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/check_in/resumen_checkin_evento_widget.dart';
import '../../controllers/tareas_controller.dart';
class CheckinProveedoresView extends StatefulWidget {
  final int? idEventoInicial;

  const CheckinProveedoresView({super.key, this.idEventoInicial});

  @override
  State<CheckinProveedoresView> createState() => _CheckinProveedoresViewState();
}

class _CheckinProveedoresViewState extends State<CheckinProveedoresView> {
  final CheckinProveedoresController checkinCtrl =
      Get.isRegistered<CheckinProveedoresController>()
      ? Get.find<CheckinProveedoresController>()
      : Get.put(CheckinProveedoresController());

  final TareasController tareasCtrl = Get.isRegistered<TareasController>()
      ? Get.find<TareasController>()
      : Get.put(TareasController());

  static const _filtros = [
    'Todos',
    'Pendiente',
    'En sitio',
    'Retrasado',
    'Completado',
  ];

  List<_EventoOpcion> _obtenerEventosDisponibles() {
    final mapa = <int, String>{};
    for (final t in tareasCtrl.tareas) {
      if (t.idEvento > 0) {
        mapa[t.idEvento] = t.nombreEvento.isNotEmpty
            ? t.nombreEvento
            : 'Evento #${t.idEvento}';
      }
    }
    return mapa.entries
        .map((e) => _EventoOpcion(id: e.key, nombre: e.value))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventos = _obtenerEventosDisponibles();
      final idDestino =
          widget.idEventoInicial ??
          checkinCtrl.idEventoSeleccionado.value ??
          (eventos.isNotEmpty ? eventos.first.id : null);
      if (idDestino != null) {
        checkinCtrl.cargarPorEvento(idDestino);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventos = _obtenerEventosDisponibles();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Check-in de Proveedores',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final eventoActualId = checkinCtrl.idEventoSeleccionado.value;

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  if (eventos.isNotEmpty)
                 DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: eventos.any((e) => e.id == eventoActualId)
                          ? eventoActualId
                          : eventos.first.id,
                      decoration: InputDecoration(
                        labelText: 'Evento operativo',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: eventos
                          .map(
                            (ev) => DropdownMenuItem<int>(
                              value: ev.id,
                              child: Text(
                                '${ev.nombre} (#${ev.id})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (nuevoId) {
                        if (nuevoId != null) {
                          checkinCtrl.cargarPorEvento(nuevoId);
                        }
                      },
                    )
                  else
                    const Text(
                      'No hay eventos activos cargados en el itinerario.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => checkinCtrl.terminoBusqueda.value = v,
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor o servicio...',
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filtros.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final estado = _filtros[index];
                        final activo = checkinCtrl.filtroEstado.value == estado;
                        return ChoiceChip(
                          label: Text(estado),
                          selected: activo,
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activo ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) =>
                              checkinCtrl.filtroEstado.value = estado,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: checkinCtrl.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : eventoActualId == null
                  ? const Center(
                      child: Text(
                        'Selecciona o asigna un evento para registrar llegadas.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          checkinCtrl.cargarPorEvento(eventoActualId),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ResumenCheckinEventoWidget(
                            pendientes: checkinCtrl.totalPendientes,
                            enSitio: checkinCtrl.totalEnSitio,
                            retrasados: checkinCtrl.totalRetrasados,
                            completados: checkinCtrl.totalCompletados,
                          ),
                          const SizedBox(height: 14),
                          if (checkinCtrl.proveedoresFiltrados.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  'No hay proveedores en este filtro.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...checkinCtrl.proveedoresFiltrados.map(
                              (item) => ProveedorCheckinCardWidget(
                                item: item,
                                procesando: checkinCtrl.procesandoIds.contains(
                                  item.idEventoProveedor,
                                ),
                                onCheckInRapido: () =>
                                    checkinCtrl.marcarEnSitioRapido(item),
                                onAbrirDetalle: () =>
                                    ModalCheckinProveedorWidget.mostrar(
                                      item: item,
                                      onGuardar:
                                          ({
                                            required nuevoEstado,
                                            required observaciones,
                                            rutaEvidencia,
                                          }) => checkinCtrl.actualizarCheckIn(
                                            item: item,
                                            nuevoEstado: nuevoEstado,
                                            observaciones: observaciones,
                                            rutaEvidencia: rutaEvidencia,
                                          ),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _EventoOpcion {
  final int id;
  final String nombre;

  _EventoOpcion({required this.id, required this.nombre});
}
