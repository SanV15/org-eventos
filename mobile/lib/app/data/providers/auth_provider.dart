import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class AuthProvider {
  final String baseUrl = '$apiBaseUrl/api/auth';

  Future<String?> login(String correo, String contrasenia) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'correo': correo, 'contrasenia': contrasenia}),
    );

    print('STATUS CODE LOGIN: ${response.statusCode}');
    print('BODY LOGIN: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception(
        'Credenciales incorrectas: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<String?> subirFotoPerfil(String rutaArchivo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    // Usa aquí la misma variable de URL base que tienes en tu método login
    final uri = Uri.parse('$baseUrl/foto-perfil');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('archivo', rutaArchivo),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('STATUS FOTO: ${response.statusCode}');
    print('BODY FOTO: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['fotoUrl'];
    }
    return null;
  }
}
