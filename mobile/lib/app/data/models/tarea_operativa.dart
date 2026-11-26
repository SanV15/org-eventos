class IncidenciaItem {
  final int? idIncidencia;
  final String observacion;
  final String? fotoUrl;
  final DateTime? fechaHora;

  IncidenciaItem({
    this.idIncidencia,
    required this.observacion,
    this.fotoUrl,
    this.fechaHora,
  });

  factory IncidenciaItem.fromJson(Map<String, dynamic> json) {
    return IncidenciaItem(
      idIncidencia: json['idIncidencia'],
      observacion: json['observacion']?.toString() ?? '',
      fotoUrl: json['fotoUrl']?.toString(),
      fechaHora: json['fechaHora'] != null
          ? DateTime.tryParse(json['fechaHora'].toString())
          : null,
    );
  }
}

class TareaOperativa {
  final int idTarea;
  final int idEvento;
  final String nombreEvento;
  final String nombreTarea;
  final String? descripcion;
  final DateTime? fechaLimite;
  String estado;
  final List<IncidenciaItem> incidencias;

  TareaOperativa({
    required this.idTarea,
    required this.idEvento,
    required this.nombreEvento,
    required this.nombreTarea,
    this.descripcion,
    this.fechaLimite,
    required this.estado,
    this.incidencias = const [],
  });

  factory TareaOperativa.fromJson(Map<String, dynamic> json) {
    final rawIncidencias = json['incidencias'];
    final List<IncidenciaItem> listaIncidencias = rawIncidencias is List
        ? rawIncidencias
              .map((i) => IncidenciaItem.fromJson(Map<String, dynamic>.from(i)))
              .toList()
        : <IncidenciaItem>[];

    return TareaOperativa(
      idTarea: json['idTarea'],
      idEvento: json['idEvento'],
      nombreEvento: json['nombreEvento'] ?? '',
      nombreTarea: json['nombreTarea'] ?? '',
      descripcion: json['descripcion'],
      fechaLimite: json['fechaLimite'] != null
          ? DateTime.tryParse(json['fechaLimite'].toString())
          : null,
      estado: json['estado'] ?? 'Pendiente',
      incidencias: listaIncidencias,
    );
  }
}
