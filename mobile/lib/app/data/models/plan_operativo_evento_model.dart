class PlanOperativoEventoModel {
  final int idEvento;
  final String nombreEvento;
  final DateTime fechaEvento;
  final DateTime? fechaFin;
  final String lugar;
  final int numeroInvitados;
  final bool esEntradaLibre;
  final String estado;
  final List<ServicioInternoEventoModel> serviciosInternos;
  final List<ProveedorHorarioEventoModel> proveedores;

  PlanOperativoEventoModel({
    required this.idEvento,
    required this.nombreEvento,
    required this.fechaEvento,
    this.fechaFin,
    required this.lugar,
    required this.numeroInvitados,
    required this.esEntradaLibre,
    required this.estado,
    required this.serviciosInternos,
    required this.proveedores,
  });

  factory PlanOperativoEventoModel.fromJson(Map<String, dynamic> json) {
    final fechaIni =
        DateTime.tryParse((json['fechaEvento'] ?? '').toString()) ??
        DateTime.now();
    final fechaFinRaw = json['fechaFin']?.toString();
    final fechaFinParsed = (fechaFinRaw != null && fechaFinRaw.isNotEmpty)
        ? DateTime.tryParse(fechaFinRaw)
        : null;
    final invitados =
        int.tryParse((json['numeroInvitados'] ?? 0).toString()) ?? 0;

    final rawServicios = json['serviciosInternos'] as List<dynamic>? ?? [];
    final rawProveedores = json['proveedores'] as List<dynamic>? ?? [];

    return PlanOperativoEventoModel(
      idEvento: int.tryParse((json['idEvento'] ?? 0).toString()) ?? 0,
      nombreEvento: (json['nombreEvento'] ?? '').toString(),
      fechaEvento: fechaIni,
      fechaFin: fechaFinParsed,
      lugar: (json['lugar'] ?? '').toString(),
      numeroInvitados: invitados,
      esEntradaLibre: json['esEntradaLibre'] == true || invitados <= 0,
      estado: (json['estado'] ?? '').toString(),
      serviciosInternos: rawServicios
          .whereType<Map<String, dynamic>>()
          .map(ServicioInternoEventoModel.fromJson).toList(),
      proveedores: rawProveedores
          .whereType<Map<String, dynamic>>()
          .map(ProveedorHorarioEventoModel.fromJson).toList(),
    );
  }
}

class ServicioInternoEventoModel {
  final int idServicio;
  final String nombre;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  ServicioInternoEventoModel({
    required this.idServicio,
    required this.nombre,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ServicioInternoEventoModel.fromJson(Map<String, dynamic> json) {
    return ServicioInternoEventoModel(
      idServicio: int.tryParse((json['idServicio'] ?? 0).toString()) ?? 0,
      nombre: (json['nombre'] ?? 'Servicio interno').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      cantidad: int.tryParse((json['cantidad'] ?? 1).toString()) ?? 1,
      precioUnitario:
          double.tryParse((json['precioUnitario'] ?? 0).toString()) ?? 0.0,
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class ProveedorHorarioEventoModel {
  final int idEventoProveedor;
  final int idServicioProveedor;
  final String nombreServicio;
  final String nombreProveedor;
  final String telefonoProveedor;
  final double? costoAcordado;
  final String estadoOperativo;
  final DateTime? horaPactada;
  final DateTime? horaLlegada;
  final DateTime? horaSalida;
  final String observaciones;
  final String? evidenciaUrl;

  ProveedorHorarioEventoModel({
    required this.idEventoProveedor,
    required this.idServicioProveedor,
    required this.nombreServicio,
    required this.nombreProveedor,
    required this.telefonoProveedor,
    this.costoAcordado,
    required this.estadoOperativo,
    this.horaPactada,
    this.horaLlegada,
    this.horaSalida,
    required this.observaciones,
    this.evidenciaUrl,
  });

  factory ProveedorHorarioEventoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return ProveedorHorarioEventoModel(
      idEventoProveedor:
          int.tryParse((json['idEventoProveedor'] ?? 0).toString()) ?? 0,
      idServicioProveedor:
          int.tryParse((json['idServicioProveedor'] ?? 0).toString()) ?? 0,
      nombreServicio: (json['nombreServicio'] ?? 'Servicio externo').toString(),
      nombreProveedor: (json['nombreProveedor'] ?? 'Proveedor').toString(),
      telefonoProveedor: (json['telefonoProveedor'] ?? '').toString(),
      costoAcordado: json['costoAcordado'] != null
          ? double.tryParse(json['costoAcordado'].toString())
          : null,
      estadoOperativo: (json['estadoOperativo'] ?? 'Pendiente').toString(),
      horaPactada: parseDt(json['horaPactada']),
      horaLlegada: parseDt(json['horaLlegada']),
      horaSalida: parseDt(json['horaSalida']),
      observaciones: (json['observaciones'] ?? '').toString(),
      evidenciaUrl: json['evidenciaUrl']?.toString(),
    );
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      'idEventoProveedor': idEventoProveedor,
      'idServicioProveedor': idServicioProveedor,
      'nombreServicio': nombreServicio,
      'costoAcordado': costoAcordado,
      'estadoOperativo': estadoOperativo,
      'horaPactada': horaPactada?.toIso8601String(),
      'horaLlegada': horaLlegada?.toIso8601String(),
      'horaSalida': horaSalida?.toIso8601String(),
      'observaciones': observaciones,
      'evidenciaUrl': evidenciaUrl,
      'proveedor': {
        'nombreCompleto': nombreProveedor,
        'telefono': telefonoProveedor,
      },
    };
  }
}
