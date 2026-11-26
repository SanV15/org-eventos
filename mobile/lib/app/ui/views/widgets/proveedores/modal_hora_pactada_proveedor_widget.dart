import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModalHoraPactadaProveedorWidget extends StatefulWidget {
  final String nombreServicio;
  final String nombreProveedor;
  final DateTime? horaInicial;
  final DateTime? fechaReferenciaEvento;
  final Future<bool> Function(DateTime? nuevaHoraPactada) onGuardar;

  const ModalHoraPactadaProveedorWidget({
    super.key,
    required this.nombreServicio,
    required this.nombreProveedor,
    this.horaInicial,
    this.fechaReferenciaEvento,
    required this.onGuardar,
  });

  static void mostrar({
    required String nombreServicio,
    required String nombreProveedor,
    DateTime? horaInicial,
    DateTime? fechaReferenciaEvento,
    required Future<bool> Function(DateTime? nuevaHoraPactada) onGuardar,
  }) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalHoraPactadaProveedorWidget(
        nombreServicio: nombreServicio,
        nombreProveedor: nombreProveedor,
        horaInicial: horaInicial,
        fechaReferenciaEvento: fechaReferenciaEvento,
        onGuardar: onGuardar,
      ),
    );
  }

  @override
  State<ModalHoraPactadaProveedorWidget> createState() =>
      _ModalHoraPactadaProveedorWidgetState();
}

class _ModalHoraPactadaProveedorWidgetState
    extends State<ModalHoraPactadaProveedorWidget> {
  DateTime? _seleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _seleccionada = widget.horaInicial;
  }

  Future<void> _elegirFechaHora() async {
    final base =
        _seleccionada ?? widget.fechaReferenciaEvento ?? DateTime.now();
    final hoy = DateTime.now();
    final firstDate = DateTime(hoy.year - 1, 1, 1);
    final lastDate = DateTime(hoy.year + 2, 12, 31);

    DateTime initialDate = DateTime(base.year, base.month, base.day);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final fecha = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _seleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  String _textoFechaHora(DateTime? dt) {
    if (dt == null) return 'Sin hora pactada asignada';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} · $h:$min hrs';
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final ok = await widget.onGuardar(_seleccionada);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      Navigator.of(context).pop();
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programar Hora Pactada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.nombreServicio} · ${widget.nombreProveedor}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
            ),
            onPressed: _elegirFechaHora,
            icon: const Icon(Icons.schedule, color: Colors.blueAccent),
            label: Text(_textoFechaHora(_seleccionada)),
          ),
          if (_seleccionada != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _seleccionada = null),
                child: const Text('Quitar hora pactada'),
              ),
            ),
          ],
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
                _guardando ? 'Guardando...' : 'Guardar Hora Pactada',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
