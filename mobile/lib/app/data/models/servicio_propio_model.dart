class ServicioPropioModel {
  final int idServicio;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool activo;

  ServicioPropioModel({
    required this.idServicio,
    required this.nombre,
    this.descripcion = '',
    required this.precio,
    this.activo = true,
  });

  factory ServicioPropioModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['idServicio'] ?? json['IdServicio'] ?? 0;
    final rawPrecio = json['precio'] ?? json['Precio'] ?? 0;
    final rawActivo = json['activo'] ?? json['Activo'] ?? true;

    return ServicioPropioModel(
      idServicio: int.tryParse(rawId.toString()) ?? 0,
      nombre: (json['nombre'] ?? json['Nombre'] ?? '').toString().trim(),
      descripcion: (json['descripcion'] ?? json['Descripcion'] ?? '')
          .toString()
          .trim(),
      precio: double.tryParse(rawPrecio.toString()) ?? 0.0,
      activo: rawActivo == true || rawActivo.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toRegistroJson() {
    return {
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'precio': precio,
      'activo': activo,
    };
  }
}
