import 'package:flutter/material.dart';
import 'package:org_eventos/app/data/models/plan_operativo_evento_model.dart';
import 'package:org_eventos/app/ui/views/widgets/cronograma/hito_cronograma_card_widget.dart';

class TabRunOfShowWidget extends StatefulWidget {
  final List<dynamic> tareas;
  final List<ProveedorHorarioEventoModel> proveedores;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(String url) onVerImagen;
  final void Function(ProveedorHorarioEventoModel prov) onEditarHoraProveedor;

  const TabRunOfShowWidget({
    super.key,
    required this.tareas,
    required this.proveedores,
    required this.fechaInicio,
    this.fechaFin,
    required this.isLoading,
    required this.onRefresh,
    required this.onVerImagen,
    required this.onEditarHoraProveedor,
  });

  @override
  State<TabRunOfShowWidget> createState() => _TabRunOfShowWidgetState();
}

class _TabRunOfShowWidgetState extends State<TabRunOfShowWidget> {
  /// null = Todos los días; de lo contrario, clave YYYY-MM-DD
  String? _diaFiltro;

  String _claveDia(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  String _etiquetaDia(DateTime dt, int indice) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return 'Día $indice (${dt.day} ${meses[dt.month - 1]})';
  }

  List<DateTime> _obtenerDiasEvento() {
    final inicio = DateTime(
      widget.fechaInicio.year,
      widget.fechaInicio.month,
      widget.fechaInicio.day,
    );
    final finRaw = widget.fechaFin ?? widget.fechaInicio;
    final fin = DateTime(finRaw.year, finRaw.month, finRaw.day);

    if (!fin.isAfter(inicio)) return [inicio];

    final dias = <DateTime>[];
    var actual = inicio;
    while (!actual.isAfter(fin) && dias.length < 14) {
      dias.add(actual);
      actual = actual.add(const Duration(days: 1));
    }
    return dias;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final diasEvento = _obtenerDiasEvento();
    final esMultidia = diasEvento.length > 1;

    // Construimos ítems unificados: {'tipo': 'tarea' | 'proveedor', 'fecha': DateTime?, 'data': ...}
    final List<Map<String, dynamic>> entradas = [];

    for (final t in widget.tareas) {
      final dt = t['fechaLimite'] != null
          ? DateTime.tryParse(t['fechaLimite'].toString())
          : null;
      entradas.add({'tipo': 'tarea', 'fecha': dt, 'data': t});
    }

    for (final p in widget.proveedores) {
      if (p.horaPactada != null) {
        entradas.add({'tipo': 'proveedor', 'fecha': p.horaPactada, 'data': p});
      }
    }

    if (_diaFiltro != null) {
      entradas.retainWhere((e) {
        final dt = e['fecha'] as DateTime?;
        return dt != null && _claveDia(dt) == _diaFiltro;
      });
    }

    entradas.sort((a, b) {
      final fa = a['fecha'] as DateTime?;
      final fb = b['fecha'] as DateTime?;
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;
      return fa.compareTo(fb);
    });

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
        children: [
          if (esMultidia) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos los días'),
                    selected: _diaFiltro == null,
                    onSelected: (_) => setState(() => _diaFiltro = null),
                  ),
                  const SizedBox(width: 8),
                  ...diasEvento.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final dia = entry.value;
                    final clave = _claveDia(dia);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_etiquetaDia(dia, idx)),
                        selected: _diaFiltro == clave,
                        onSelected: (_) => setState(() => _diaFiltro = clave),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (entradas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  _diaFiltro != null
                      ? 'Sin actividades ni llegadas programadas para este día.'
                      : 'No hay hitos ni horarios pactados registrados aún.',
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...entradas.map((entry) {
              if (entry['tipo'] == 'tarea') {
                return HitoCronogramaCardWidget(
                  tarea: entry['data'] as Map<String, dynamic>,
                  onVerImagen: widget.onVerImagen,
                );
              }
              final prov = entry['data'] as ProveedorHorarioEventoModel;
              return _BloqueLlegadaProveedorRunOfShow(
                proveedor: prov,
                onEditarHora: () => widget.onEditarHoraProveedor(prov),
              );
            }),
        ],
      ),
    );
  }
}

class _BloqueLlegadaProveedorRunOfShow extends StatelessWidget {
  final ProveedorHorarioEventoModel proveedor;
  final VoidCallback onEditarHora;

  const _BloqueLlegadaProveedorRunOfShow({
    required this.proveedor,
    required this.onEditarHora,
  });

  String _formatoHoraFecha(DateTime? dt) {
    if (dt == null) return '--:--';
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${dt.day}${meses[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final llegada = proveedor.horaLlegada;
    final pactada = proveedor.horaPactada;
    final llegoTarde = proveedor.estadoOperativo == 'Retrasado' ||
        (pactada != null && llegada != null && llegada.isAfter(pactada));

    final colorAccent = llegoTarde
        ? const Color(0xFFEA580C)
        : (proveedor.estadoOperativo == 'Completado' ||
                proveedor.estadoOperativo == 'En sitio'
            ? const Color(0xFF16A34A)
            : Colors.teal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorAccent.withOpacity(0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 17, color: colorAccent),
              const SizedBox(width: 6),
              Text(
                'Pactado: ${_formatoHoraFecha(pactada)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorAccent,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  proveedor.estadoOperativo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Llegada / Montaje: ${proveedor.nombreServicio}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Proveedor: ${proveedor.nombreProveedor}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          if (llegada != null) ...[
            const SizedBox(height: 6),
            Text(
              llegoTarde
                  ? 'Llegada real: ${_formatoHoraFecha(llegada)} (Fuera de hora)'
                  : 'Llegada real: ${_formatoHoraFecha(llegada)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: llegoTarde
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF16A34A),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditarHora,
              icon: const Icon(Icons.schedule, size: 15),
              label: const Text('Ajustar hora', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}