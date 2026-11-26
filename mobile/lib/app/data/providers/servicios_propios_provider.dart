import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/servicio_propio_model.dart';
import '../../config/app_config.dart';

class ServiciosPropiosProvider {
  final String baseUrl = '$apiBaseUrl/api/servicios';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ServicioPropioModel>> obtenerServicios() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .whereType<Map<String, dynamic>>()
          .map(ServicioPropioModel.fromJson)
          .toList();
    }

    throw Exception('Error al obtener servicios (${response.statusCode})');
  }

  Future<bool> crearServicio({
    required String nombre,
    required String descripcion,
    required double precio,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _getHeaders(),
      body: json.encode({
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'precio': precio,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> actualizarServicio({
    required int idServicio,
    required String nombre,
    required String descripcion,
    required double precio,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$idServicio'),
      headers: await _getHeaders(),
      body: json.encode({
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'precio': precio,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> cambiarEstado({
    required int idServicio,
    required bool activo,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$idServicio/estado'),
      headers: await _getHeaders(),
      body: json.encode({'activo': activo}),
    );
    return response.statusCode == 200;
  }
}
