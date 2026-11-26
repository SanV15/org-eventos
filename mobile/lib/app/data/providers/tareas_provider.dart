import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarea_operativa.dart';
import '../../config/app_config.dart';

class TareasProvider {
  final String baseUrl = '$apiBaseUrl/api/tareas';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      'jwt_token',
    ); // Asegúrate de guardar el token con esta clave en tu Login
  }

  Future<List<TareaOperativa>> obtenerMisTareas() async {
    final token = await _getToken();
    final url = '$baseUrl/mis-tareas';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('--- OBTENER MIS TAREAS ---');
    print('STATUS: ${response.statusCode}');
    print('RESPUESTA API TAREAS: ${response.body}');
    print('--------------------------');

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => TareaOperativa.fromJson(model)).toList();
    } else {
      throw Exception(
        'Fallo al obtener las tareas. Código: ${response.statusCode}',
      );
    }
  }

  Future<bool> actualizarEstado(int idTarea, String nuevoEstado) async {
    final token = await _getToken();
    final url = '$baseUrl/$idTarea/estado';

    print('--- PETICIÓN CAMBIAR ESTADO ---');
    print('URL: $url');
    print('Body enviado: ${json.encode({'estado': nuevoEstado})}');

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'estado': nuevoEstado}),
    );

    print('STATUS CODE PATCH: ${response.statusCode}');
    print('RESPUESTA API: ${response.body}');
    print('-------------------------------');

    return response.statusCode == 200;
  }

  Future<bool> reportarIncidencia(
    int idTarea,
    String observaciones,
    String? rutaImagen,
  ) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/$idTarea/incidencia');

    var request = http.MultipartRequest('PATCH', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['observaciones'] = observaciones;

    // Si hay una foto seleccionada, la adjuntamos
    if (rutaImagen != null && rutaImagen.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('archivo', rutaImagen),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('STATUS CODE PATCH INCIDENCIA: ${response.statusCode}');
    print('RESPUESTA API: ${response.body}');
    print('-------------------------------');

    return response.statusCode == 200;
  }

  Future<List<dynamic>> obtenerTareasPorEvento(int idEvento) async {
    final token = await _getToken();
    final url = '$baseUrl/evento/$idEvento';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fallo al obtener el cronograma del evento');
    }
  }

  Future<List<dynamic>> obtenerPersonalEmpleados() async {
    final token = await _getToken();
    final url = baseUrl.replaceAll('/tareas', '/usuarios/empleados');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }

  //Crear y asignar una nueva tarea
  Future<bool> crearTarea(Map<String, dynamic> nuevaTareaData) async {
    final token = await _getToken();
    final url = Uri.parse(baseUrl);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(nuevaTareaData),
    );
    return response.statusCode == 200;
  }
}
