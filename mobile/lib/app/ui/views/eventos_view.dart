import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import 'cronograma_evento_view.dart';

class EventosView extends StatefulWidget {
  const EventosView({super.key});

  @override
  State<EventosView> createState() => _EventosViewState();
}

class _EventosViewState extends State<EventosView> {
  final String _baseUrl = '$apiBaseUrl/api/eventos';
  List<dynamic> eventos = [];
  bool isLoading = true;
  String filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          eventos = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar(
          'Error',
          'No se pudieron cargar los eventos (${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Fallo de conexión al obtener eventos');
    }
  }

  List<dynamic> _filtrarEventos(String categoria) {
    return eventos.where((ev) {
      final estado = _EventoHelper.normalizar(ev['estado']?.toString() ?? '');
      final coincideTab = categoria == 'todos' || estado == categoria;

      if (!coincideTab) return false;

      if (filtroBusqueda.isNotEmpty) {
        final q = _EventoHelper.normalizar(filtroBusqueda);
        final titulo = _EventoHelper.normalizar(
          _EventoHelper.obtenerTitulo(ev),
        );
        final cliente = _EventoHelper.normalizar(
          _EventoHelper.obtenerCliente(ev),
        );
        final folio = ev['idEvento'].toString();
        return titulo.contains(q) || cliente.contains(q) || folio.contains(q);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Control de Eventos',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Todos'),
              Tab(text: 'Pendientes'),
              Tab(text: 'En Planificación'),
              Tab(text: 'Cancelados'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _BarraBusquedaEventos(
                    onChanged: (val) => setState(() => filtroBusqueda = val),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListaEventosTab(
                          eventos: _filtrarEventos('todos'),
                          onRefresh: _cargarEventos,
                        ),
                        _ListaEventosTab(
                          eventos: _filtrarEventos('pendiente'),
                          onRefresh: _cargarEventos,
                        ),
                        _ListaEventosTab(
                          eventos: _filtrarEventos('en planificacion'),
                          onRefresh: _cargarEventos,
                        ),
                        _ListaEventosTab(
                          eventos: _filtrarEventos('cancelado'),
                          onRefresh: _cargarEventos,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS ATOMIZADOS DE EVENTOS
// ============================================================================

class _BarraBusquedaEventos extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _BarraBusquedaEventos({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar cliente, tipo de evento o folio...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

class _ListaEventosTab extends StatelessWidget {
  final List<dynamic> eventos;
  final Future<void> Function() onRefresh;

  const _ListaEventosTab({required this.eventos, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const _EstadoVacioEventos(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventos.length,
        itemBuilder: (context, index) => _EventoCard(evento: eventos[index]),
      ),
    );
  }
}

class _EstadoVacioEventos extends StatelessWidget {
  const _EstadoVacioEventos();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No hay eventos en esta categoría.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

class _EventoCard extends StatelessWidget {
  final dynamic evento;

  const _EventoCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final idEvento = evento['idEvento'];
    final tituloEvento = _EventoHelper.obtenerTitulo(evento);
    final cliente = _EventoHelper.obtenerCliente(evento);
    final estado = evento['estado'] ?? 'Pendiente';
    final fechaIso = evento['fechaEvento']?.toString();
    final pasado = _EventoHelper.esPasado(fechaIso);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: pasado ? Colors.grey.shade200 : Colors.white,
        elevation: pasado ? 0 : 1,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: pasado
                ? Colors.grey.shade400
                : Colors.blueAccent.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: _FolioBadge(idEvento: idEvento, pasado: pasado),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  tituloEvento,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: pasado ? Colors.grey.shade700 : Colors.black87,
                  ),
                ),
              ),
              if (pasado) const _BadgePasado(),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: pasado ? Colors.grey.shade600 : Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cliente,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: pasado
                              ? Colors.grey.shade600
                              : Colors.blueGrey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_EventoHelper.formatearFecha(fechaIso)} · $estado',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: pasado ? Colors.grey.shade500 : Colors.blueAccent,
          ),
          onTap: () {
            Get.to(
              () => CronogramaEventoView(
                idEvento: idEvento,
                nombreEvento: '$tituloEvento ($cliente)',
                fechaEvento: fechaIso != null
                    ? DateTime.tryParse(fechaIso)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FolioBadge extends StatelessWidget {
  final dynamic idEvento;
  final bool pasado;

  const _FolioBadge({required this.idEvento, required this.pasado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: pasado
            ? Colors.grey.shade300
            : Colors.blueAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '#${idEvento.toString().padLeft(3, '0')}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: pasado ? Colors.grey.shade700 : Colors.blueAccent,
        ),
      ),
    );
  }
}

class _BadgePasado extends StatelessWidget {
  const _BadgePasado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Pasado',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================================
// UTILIDADES DE FORMATEO Y EXTRACCIÓN DE EVENTOS
// ============================================================================

class _EventoHelper {
  static String normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('ó', 'o')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ú', 'u')
        .trim();
  }

  static String obtenerTitulo(dynamic ev) {
    return ev['tipoEvento'] ??
        ev['nombreEvento'] ??
        ev['nombre'] ??
        'Evento #${ev['idEvento']}';
  }

  static String obtenerCliente(dynamic ev) {
    if (ev['nombreCliente'] != null &&
        ev['nombreCliente'].toString().isNotEmpty) {
      return ev['nombreCliente'];
    }
    if (ev['cliente'] != null && ev['cliente'].toString().isNotEmpty) {
      return ev['cliente'];
    }
    if (ev['idClienteNavigation'] != null) {
      final c = ev['idClienteNavigation'];
      return '${c['nombre'] ?? ''} ${c['apellidoPaterno'] ?? ''}'.trim();
    }
    return 'Cliente sin especificar';
  }

  static bool esPasado(String? fechaIso) {
    if (fechaIso == null) return false;
    final dt = DateTime.tryParse(fechaIso);
    if (dt == null) return false;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaEv = DateTime(dt.year, dt.month, dt.day);
    return fechaEv.isBefore(hoy);
  }

  static String formatearFecha(String? fechaIso) {
    if (fechaIso == null) return 'Sin fecha';
    final dt = DateTime.tryParse(fechaIso);
    if (dt == null) return fechaIso;
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
  }
}
