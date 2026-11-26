import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModalCrearHitoWidget extends StatefulWidget {
  final int idEvento;
  final String nombreEvento;
  final DateTime? fechaEvento;
  final List<dynamic> personal;
  final Future<bool> Function(Map<String, dynamic> payload) onGuardar;

  const ModalCrearHitoWidget({
    super.key,
    required this.idEvento,
    required this.nombreEvento,
    this.fechaEvento,
    required this.personal,
    required this.onGuardar,
  });

  static void mostrar({
    required BuildContext context,
    required int idEvento,
    required String nombreEvento,
    DateTime? fechaEvento,
    required List<dynamic> personal,
    required Future<bool> Function(Map<String, dynamic> payload) onGuardar,
  }) {
    Get.bottomSheet(
      isScrollControlled: true,
      ModalCrearHitoWidget(
        idEvento: idEvento,
        nombreEvento: nombreEvento,
        fechaEvento: fechaEvento,
        personal: personal,
        onGuardar: onGuardar,
      ),
    );
  }

  @override
  State<ModalCrearHitoWidget> createState() => _ModalCrearHitoWidgetState();
}

class _ModalCrearHitoWidgetState extends State<ModalCrearHitoWidget> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  int? _usuarioSeleccionado;
  late DateTime _fechaHoraSeleccionada;
  late DateTime _firstDate;
  late DateTime _lastDate;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    _firstDate = hoy;
    _lastDate = hoy.add(const Duration(days: 365));

    if (widget.fechaEvento != null) {
      final fechaEv = DateTime(
        widget.fechaEvento!.year,
        widget.fechaEvento!.month,
        widget.fechaEvento!.day,
      );
      _lastDate = fechaEv.add(const Duration(days: 1));
      if (_lastDate.isBefore(_firstDate)) {
        _lastDate = _firstDate;
      }
    }

    DateTime base = hoy;
    if (base.isBefore(_firstDate)) base = _firstDate;
    if (base.isAfter(_lastDate)) base = _lastDate;

    _fechaHoraSeleccionada = DateTime(
      base.year,
      base.month,
      base.day,
      ahora.hour,
      ahora.minute,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaHora() async {
    DateTime initialDate = DateTime(
      _fechaHoraSeleccionada.year,
      _fechaHoraSeleccionada.month,
      _fechaHoraSeleccionada.day,
    );
    if (initialDate.isBefore(_firstDate)) initialDate = _firstDate;
    if (initialDate.isAfter(_lastDate)) initialDate = _lastDate;

    final fecha = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHoraSeleccionada),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _fechaHoraSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_nombreController.text.trim().isEmpty) {
      Get.snackbar('Atención', 'El nombre del hito es obligatorio');
      return;
    }

    setState(() => _guardando = true);
    final payload = {
      'idEvento': widget.idEvento,
      'idUsuario': _usuarioSeleccionado,
      'nombre': _nombreController.text.trim(),
      'descripcion': _descController.text.trim(),
      'fechaLimite': _fechaHoraSeleccionada.toIso8601String(),
      'observaciones': '',
    };

    final ok = await widget.onGuardar(payload);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = _fechaHoraSeleccionada;
    final textoFecha =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
                  child: Text(
                    'Nuevo Hito: ${widget.nombreEvento}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Actividad Principal',
                hintText: 'Ej. Montaje de iluminación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Logística y Detalles',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _usuarioSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Asignar a Personal',
                border: OutlineInputBorder(),
              ),
              items: widget.personal.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(
                  value: p['idUsuario'],
                  child: Text(
                    '${p['nombre']} ${p['apellidoPaterno'] ?? ''}'.trim(),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _usuarioSeleccionado = val),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(Icons.access_time, color: Colors.blueAccent),
              label: Text('Fecha y Hora: $textoFecha'),
              onPressed: _seleccionarFechaHora,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando ? null : _submit,
                child: Text(
                  _guardando ? 'Guardando...' : 'Guardar y Asignar Hito',
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
