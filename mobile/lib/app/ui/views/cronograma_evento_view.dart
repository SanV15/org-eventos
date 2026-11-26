import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/data/models/plan_operativo_evento_model.dart';
import 'package:org_eventos/app/data/providers/plan_operativo_provider.dart';
import 'package:org_eventos/app/ui/views/widgets/cronograma/banner_solo_lectura_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/cronograma/modal_crear_hito_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/cronograma/tab_run_of_show_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/cronograma/tab_servicios_internos_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/modal_hora_pactada_proveedor_widget.dart';
import 'package:org_eventos/app/ui/views/widgets/proveedores/proveedor_cronograma_card_widget.dart';
import '../../controllers/tareas_controller.dart';
import '../../data/providers/proveedores_provider.dart';
import '../../data/providers/tareas_provider.dart';

class CronogramaEventoView extends StatefulWidget {
  final int idEvento;
  final String nombreEvento;
  final DateTime? fechaEvento;

  const CronogramaEventoView({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
    this.fechaEvento,
  });

  @override
  State<CronogramaEventoView> createState() => _CronogramaEventoViewState();
}

class _CronogramaEventoViewState extends State<CronogramaEventoView>
    with SingleTickerProviderStateMixin {
  final TareasProvider _tareasProvider = TareasProvider();
  final ProveedoresProvider _proveedoresProvider = ProveedoresProvider();
  final PlanOperativoProvider _planProvider = PlanOperativoProvider();

  late TabController _tabController;
  PlanOperativoEventoModel? _plan;
  List<dynamic> tareasEvento = [];
  List<dynamic> proveedoresEvento = [];
  bool isLoading = true;
  bool isLoadingProveedores = true;
  bool isLoadingPlan = true;

  DateTime get _fechaInicioEfectiva =>
      _plan?.fechaEvento ?? widget.fechaEvento ?? DateTime.now();

  DateTime? get _fechaFinEfectiva => _plan?.fechaFin;

  bool get _esEventoPasado {
    final referencia = _fechaFinEfectiva ?? _fechaInicioEfectiva;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaEv = DateTime(referencia.year, referencia.month, referencia.day);
    return fechaEv.isBefore(hoy);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    cargarCronograma();
    cargarPlanOperativo();
    cargarProveedores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> cargarPlanOperativo() async {
    setState(() => isLoadingPlan = true);
    try {
      final plan = await _planProvider.obtenerPlanOperativo(widget.idEvento);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        isLoadingPlan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingPlan = false);
    }
  }

  Future<void> cargarCronograma() async {
    setState(() => isLoading = true);
    try {
      final data = await _tareasProvider.obtenerTareasPorEvento(
        widget.idEvento,
      );
      data.sort((a, b) {
        if (a['fechaLimite'] == null || b['fechaLimite'] == null) return 0;
        return DateTime.parse(
          a['fechaLimite'],
        ).compareTo(DateTime.parse(b['fechaLimite']));
      });
      if (!mounted) return;
      setState(() {
        tareasEvento = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Get.snackbar('Error', 'No se pudo cargar el cronograma del evento');
    }
  }

  Future<void> cargarProveedores() async {
    setState(() => isLoadingProveedores = true);
    try {
      final data = await _proveedoresProvider.obtenerProveedoresPorEvento(
        widget.idEvento,
      );
      if (!mounted) return;
      setState(() {
        proveedoresEvento = data;
        isLoadingProveedores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingProveedores = false);
      Get.snackbar('Error', 'No se pudieron cargar los proveedores asignados');
    }
  }

  void _abrirModalCrearHito({String? tituloSugerido}) async {
    final personal = await _tareasProvider.obtenerPersonalEmpleados();
    if (!mounted) return;

    ModalCrearHitoWidget.mostrar(
      context: context,
      idEvento: widget.idEvento,
      nombreEvento: _plan?.nombreEvento ?? widget.nombreEvento,
      fechaEvento: _fechaFinEfectiva ?? _fechaInicioEfectiva,
      personal: personal,
      onGuardar: (payload) async {
        final payloadFinal = <String, dynamic>{
          ...payload,
          if ((payload['nombre'] ?? '').toString().trim().isEmpty &&
              tituloSugerido != null)
            'nombre': tituloSugerido,
        };
        final exito = await _tareasProvider.crearTarea(payloadFinal);
        if (!exito) {
          Get.snackbar('Error', 'No se pudo crear el hito');
          return false;
        }
        await cargarCronograma();
        final tareasCtrl = Get.isRegistered<TareasController>()
            ? Get.find<TareasController>()
            : Get.put(TareasController());
        await tareasCtrl.cargarMisTareasSilencioso();
        Get.snackbar(
          'Hito Asignado',
          'La tarea se agregó al cronograma',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      },
    );
  }

  void _abrirModalHoraPactadaDesdeModelo(ProveedorHorarioEventoModel prov) {
    ModalHoraPactadaProveedorWidget.mostrar(
      nombreServicio: prov.nombreServicio,
      nombreProveedor: prov.nombreProveedor,
      horaInicial: prov.horaPactada,
      fechaReferenciaEvento: _fechaInicioEfectiva,
      onGuardar: (nuevaHora) async {
        final ok = await _planProvider.actualizarHoraPactadaProveedor(
          idEventoProveedor: prov.idEventoProveedor,
          horaPactada: nuevaHora,
        );
        if (!ok) {
          Get.snackbar('Error', 'No se pudo guardar la hora pactada');
          return false;
        }
        await Future.wait([cargarPlanOperativo(), cargarProveedores()]);
        Get.snackbar(
          'Hora Pactada Actualizada',
          'Se guardó el horario de llegada para ${prov.nombreProveedor}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      },
    );
  }

  void _abrirModalHoraPactada(Map<String, dynamic> item) {
    final prov = item['proveedor'] is Map<String, dynamic>
        ? item['proveedor'] as Map<String, dynamic>
        : <String, dynamic>{};
    final nombreProveedor = (prov['nombreCompleto'] ?? 'Proveedor')
        .toString()
        .trim();

    ModalHoraPactadaProveedorWidget.mostrar(
      nombreServicio: (item['nombreServicio'] ?? 'Servicio').toString(),
      nombreProveedor: nombreProveedor,
      horaInicial: item['horaPactada'] != null
          ? DateTime.tryParse(item['horaPactada'].toString())
          : null,
      fechaReferenciaEvento: _fechaInicioEfectiva,
      onGuardar: (nuevaHora) async {
        final ok = await _proveedoresProvider.actualizarHoraPactada(
          idEventoProveedor: item['idEventoProveedor'],
          horaPactada: nuevaHora,
        );
        if (!ok) {
          Get.snackbar('Error', 'No se pudo guardar la hora pactada');
          return false;
        }
        await Future.wait([cargarProveedores(), cargarPlanOperativo()]);
        Get.snackbar(
          'Hora Pactada Actualizada',
          'Se guardó el horario de llegada para $nombreProveedor',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      },
    );
  }

  void _abrirModalCheckIn(Map<String, dynamic> item) {
    final prov = item['proveedor'] is Map<String, dynamic>
        ? item['proveedor'] as Map<String, dynamic>
        : <String, dynamic>{};
    final nombreProveedor = (prov['nombreCompleto'] ?? 'Proveedor')
        .toString()
        .trim();

    Get.bottomSheet(
      isScrollControlled: true,
      _CheckInRapidoCronogramaSheet(
        idEventoProveedor: item['idEventoProveedor'],
        nombreServicio: (item['nombreServicio'] ?? 'Servicio').toString(),
        nombreProveedor: nombreProveedor,
        estadoInicial: (item['estadoOperativo'] ?? 'Pendiente').toString(),
        observacionesIniciales: (item['observaciones'] ?? '').toString(),
        onConfirmar: ({required estado, required observaciones}) async {
          final ok = await _proveedoresProvider.registrarCheckIn(
            idEventoProveedor: item['idEventoProveedor'],
            estadoOperativo: estado,
            observaciones: observaciones,
            registrarHoraLlegada: true,
          );
          if (!ok) {
            Get.snackbar('Error', 'No se pudo actualizar el proveedor');
            return false;
          }
          await Future.wait([cargarProveedores(), cargarPlanOperativo()]);
          Get.snackbar(
            'Check-in Actualizado',
            'Proveedor marcado como "$estado"',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return true;
        },
      ),
    );
  }

  void _mostrarImagenGrande(String urlImagen) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(urlImagen, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPasado = _esEventoPasado;
    final proveedoresModelo =
        _plan?.proveedores ?? <ProveedorHorarioEventoModel>[];
    final serviciosInternos =
        _plan?.serviciosInternos ?? <ServicioInternoEventoModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _plan?.nombreEvento ?? widget.nombreEvento,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.timeline, size: 18), text: 'Cronograma'),
            Tab(
              icon: Icon(Icons.storefront_outlined, size: 18),
              text: 'Proveedores',
            ),
            Tab(
              icon: Icon(Icons.room_service_outlined, size: 18),
              text: 'Servicios',
            ),
          ],
        ),
      ),
      floatingActionButton: (!esPasado && _tabController.index == 0)
          ? FloatingActionButton.extended(
              onPressed: () => _abrirModalCrearHito(),
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuevo Hito',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          if (esPasado) const BannerSoloLecturaWidget(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TabRunOfShowWidget(
                  tareas: tareasEvento,
                  proveedores: proveedoresModelo,
                  fechaInicio: _fechaInicioEfectiva,
                  fechaFin: _fechaFinEfectiva,
                  isLoading: isLoading || isLoadingPlan,
                  onRefresh: () async {
                    await Future.wait([
                      cargarCronograma(),
                      cargarPlanOperativo(),
                    ]);
                  },
                  onVerImagen: _mostrarImagenGrande,
                  onEditarHoraProveedor: _abrirModalHoraPactadaDesdeModelo,
                ),
                isLoadingProveedores
                    ? const Center(child: CircularProgressIndicator())
                    : proveedoresEvento.isEmpty
                    ? RefreshIndicator(
                        onRefresh: cargarProveedores,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                            ),
                            Icon(
                              Icons.store_mall_directory_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'No hay proveedores asignados a este evento.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: cargarProveedores,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: proveedoresEvento.length,
                          itemBuilder: (context, index) {
                            final item = proveedoresEvento[index];
                            return ProveedorCronogramaCardWidget(
                              item: item,
                              esSoloLectura: esPasado,
                              onEditarHoraPactada: () =>
                                  _abrirModalHoraPactada(item),
                              onCheckIn: () => _abrirModalCheckIn(item),
                            );
                          },
                        ),
                      ),
                isLoadingPlan
                    ? const Center(child: CircularProgressIndicator())
                    : TabServiciosInternosWidget(
                        servicios: serviciosInternos,
                        esSoloLectura: esPasado,
                        onRefresh: cargarPlanOperativo,
                        onCrearHitoDesdeServicio: (servicio) {
                          _tabController.animateTo(0);
                          _abrirModalCrearHito(
                            tituloSugerido: 'Ejecución: ${servicio.nombre}',
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInRapidoCronogramaSheet extends StatefulWidget {
  final int idEventoProveedor;
  final String nombreServicio;
  final String nombreProveedor;
  final String estadoInicial;
  final String observacionesIniciales;
  final Future<bool> Function({
    required String estado,
    required String observaciones,
  })
  onConfirmar;

  const _CheckInRapidoCronogramaSheet({
    required this.idEventoProveedor,
    required this.nombreServicio,
    required this.nombreProveedor,
    required this.estadoInicial,
    required this.observacionesIniciales,
    required this.onConfirmar,
  });

  @override
  State<_CheckInRapidoCronogramaSheet> createState() =>
      _CheckInRapidoCronogramaSheetState();
}

class _CheckInRapidoCronogramaSheetState
    extends State<_CheckInRapidoCronogramaSheet> {
  static const _estados = ['Pendiente', 'En sitio', 'Retrasado', 'Completado'];
  late String _estado;
  late TextEditingController _obsCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estado = _estados.contains(widget.estadoInicial)
        ? widget.estadoInicial
        : 'Pendiente';
    _obsCtrl = TextEditingController(text: widget.observacionesIniciales);
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombreServicio,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.nombreProveedor,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Estado Operativo en Sitio',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _estados.map((estado) {
                final sel = _estado == estado;
                return ChoiceChip(
                  label: Text(estado),
                  selected: sel,
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.blueAccent.shade700 : Colors.black87,
                  ),
                  onSelected: (_) => setState(() => _estado = estado),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones de llegada / entrega',
                hintText: 'Ej. Llegó puntual con equipo completo...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando
                    ? null
                    : () async {
                        setState(() => _guardando = true);
                        final ok = await widget.onConfirmar(
                          estado: _estado,
                          observaciones: _obsCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() => _guardando = false);
                        if (ok && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: const Icon(
                  Icons.how_to_reg_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  _guardando ? 'Guardando...' : 'Confirmar Registro',
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
