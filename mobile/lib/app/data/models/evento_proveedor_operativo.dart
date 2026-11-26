class EventoProveedorOperativo {
  final int idEventoProveedor;
  final int idEvento;
  final String nombreEvento;
  final String nombreServicio;
  final String nombreProveedor;
  final String telefono;
  final double? costoAcordado;
  String estadoOperativo;
  DateTime? horaPactada;
  DateTime? horaLlegada;
  DateTime? horaSalida;
  String observaciones;
  String? evidenciaUrl;
  String? recibidoPor;

  EventoProveedorOperativo({
    required this.idEventoProveedor,
    required this.idEvento,
    required this.nombreEvento,
    required this.nombreServicio,
    required this.nombreProveedor,
    this.telefono = '',
    this.costoAcordado,
    this.estadoOperativo = 'Pendiente',
    this.horaPactada,
    this.horaLlegada,
    this.horaSalida,
    this.observaciones = '',
    this.evidenciaUrl,
    this.recibidoPor,
  });

  bool get estaRetrasadoPorHorario {
    if (horaPactada == null) return false;
    if (estadoOperativo == 'En sitio' || estadoOperativo == 'Completado') {
      return false;
    }
    return DateTime.now().isAfter(horaPactada!);
  }

  factory EventoProveedorOperativo.fromJson(Map<String, dynamic> json) {
    final prov = json['proveedor'] is Map<String, dynamic>
        ? json['proveedor'] as Map<String, dynamic>
        : <String, dynamic>{};

    return EventoProveedorOperativo(
      idEventoProveedor: json['idEventoProveedor'] ?? 0,
      idEvento: json['idEvento'] ?? 0,
      nombreEvento: (json['nombreEvento'] ?? '').toString(),
      nombreServicio: (json['nombreServicio'] ?? 'Servicio contratado')
          .toString(),
      nombreProveedor:
          (prov['nombreCompleto'] ?? json['nombreProveedor'] ?? 'Proveedor')
              .toString()
              .trim(),
      telefono: (prov['telefono'] ?? json['telefono'] ?? '').toString().trim(),
      costoAcordado: json['costoAcordado'] != null
          ? double.tryParse(json['costoAcordado'].toString())
          : null,
      estadoOperativo: (json['estadoOperativo'] ?? 'Pendiente').toString(),
      horaPactada: json['horaPactada'] != null
          ? DateTime.tryParse(json['horaPactada'].toString())
          : null,
      horaLlegada: json['horaLlegada'] != null
          ? DateTime.tryParse(json['horaLlegada'].toString())
          : null,
      horaSalida: json['horaSalida'] != null
          ? DateTime.tryParse(json['horaSalida'].toString())
          : null,
      observaciones: (json['observaciones'] ?? '').toString(),
      evidenciaUrl: json['evidenciaUrl']?.toString(),
      recibidoPor: json['recibidoPor']?.toString(),
    );
  }
}
