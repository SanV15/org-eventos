import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_operativo_evento_model.dart';
import '../../config/app_config.dart';

class PlanOperativoProvider {
  final String eventosBaseUrl = '$apiBaseUrl/api/eventos';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<PlanOperativoEventoModel> obtenerPlanOperativo(int idEvento) async {
    final response = await http.get(
      Uri.parse('$eventosBaseUrl/$idEvento/plan-operativo'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return PlanOperativoEventoModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Error al cargar plan operativo (${response.statusCode})');
  }

  Future<bool> actualizarHoraPactadaProveedor({
    required int idEventoProveedor,
    required DateTime? horaPactada,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{
      'horaPactada': horaPactada?.toIso8601String(),
    };
    if (observaciones != null) {
      body['observaciones'] = observaciones.trim();
    }

    final response = await http.patch(
      Uri.parse('$eventosBaseUrl/proveedores/$idEventoProveedor/hora-pactada'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }
}
