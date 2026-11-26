import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

typedef HeadersHttp = Map<String, String>;
typedef JsonMap = Map<String, dynamic>;

class ProveedoresProvider {
  final String baseUrl = '$apiBaseUrl/api/proveedores';
  final String serviciosUrl = '$apiBaseUrl/api/serviciosproveedor';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<HeadersHttp> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===========================================================================
  // CHECK-IN OPERATIVO POR EVENTO
  // ===========================================================================

  Future<List<dynamic>> obtenerProveedoresPorEvento(int idEvento) async {
    final response = await http.get(
      Uri.parse('$baseUrl/evento/$idEvento'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Error al cargar proveedores del evento (${response.statusCode})',
      );
    }
  }

  Future<bool> registrarCheckIn({
    required int idEventoProveedor,
    required String estadoOperativo,
    String? observaciones,
    bool registrarHoraLlegada = true,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/checkin/$idEventoProveedor'),
      headers: await _getHeaders(),
      body: json.encode({
        'estadoOperativo': estadoOperativo,
        'observaciones': observaciones ?? '',
        'registrarHoraLlegada': registrarHoraLlegada,
      }),
    );

    return response.statusCode == 200;
  }

  // ===========================================================================
  // CRUD DE PROVEEDORES
  // ===========================================================================

  Future<List<dynamic>> obtenerCatalogoProveedores() async {
    final response = await http.get(
      Uri.parse('$baseUrl/con-estado'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Error al cargar catálogo de proveedores (${response.statusCode})',
      );
    }
  }

  Future<JsonMap?> obtenerProveedorPorId(int idProveedor) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$idProveedor'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as JsonMap;
    }
    return null;
  }

  Future<List<dynamic>> obtenerCategorias() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categorias'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> registrarProveedor(JsonMap dto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrar'),
      headers: await _getHeaders(),
      body: json.encode(dto),
    );
    return response.statusCode == 200;
  }

  Future<bool> actualizarProveedor(int idProveedor, JsonMap dto) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$idProveedor'),
      headers: await _getHeaders(),
      body: json.encode(dto),
    );
    return response.statusCode == 200;
  }

  Future<bool> cambiarEstadoProveedor(int idProveedor, bool activo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$idProveedor/estado'),
      headers: await _getHeaders(),
      body: json.encode({'activo': activo}),
    );
    return response.statusCode == 200;
  }

  // ===========================================================================
  // CRUD DE SERVICIOS POR PROVEEDOR
  // ===========================================================================

  Future<List<dynamic>> obtenerServiciosPorProveedor(int idProveedor) async {
    final response = await http.get(
      Uri.parse('$serviciosUrl/proveedor/$idProveedor'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> agregarServicio(int idProveedor, JsonMap dto) async {
    final response = await http.post(
      Uri.parse('$serviciosUrl/proveedor/$idProveedor'),
      headers: await _getHeaders(),
      body: json.encode(dto),
    );
    return response.statusCode == 200;
  }

  Future<bool> actualizarServicio(int idServicioProveedor, JsonMap dto) async {
    final response = await http.put(
      Uri.parse('$serviciosUrl/$idServicioProveedor'),
      headers: await _getHeaders(),
      body: json.encode(dto),
    );
    return response.statusCode == 200;
  }

  Future<bool> cambiarEstadoServicio(
    int idServicioProveedor,
    bool activo,
  ) async {
    final response = await http.put(
      Uri.parse('$serviciosUrl/$idServicioProveedor/estado'),
      headers: await _getHeaders(),
      body: json.encode({'activo': activo}),
    );
    return response.statusCode == 200;
  }

  // ===========================================================================
  // SUBIR FOTO DEL PROVEEDOR (S3)
  // ===========================================================================

  Future<String?> subirFotoProveedor(int idProveedor, String rutaImagen) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/$idProveedor/foto');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('archivo', rutaImagen));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['fotoProveedorUrl']?.toString();
    }
    return null;
  }

  //Check_in del proveedor
  Future<String?> subirEvidenciaCheckIn({
    required int idEventoProveedor,
    required String rutaImagen,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/checkin/$idEventoProveedor/evidencia');

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('archivo', rutaImagen));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['evidenciaUrl']?.toString();
    }
    return null;
  }

  Future<bool> actualizarHoraPactada({
    required int idEventoProveedor,
    required DateTime? horaPactada,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/evento-proveedor/$idEventoProveedor/hora-pactada'),
      headers: await _getHeaders(),
      body: json.encode({'horaPactada': horaPactada?.toIso8601String()}),
    );
    return response.statusCode == 200;
  }
}
