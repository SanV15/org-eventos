import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

typedef FotoEventoMap = Map<int, String?>;

class EventosProvider {
  final String baseUrl = '$apiBaseUrl/api/eventos';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<FotoEventoMap> obtenerMapaFotosEventos() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = json.decode(response.body);
      final FotoEventoMap mapa = {};
      for (final item in lista) {
        final id = int.tryParse(item['idEvento']?.toString() ?? '');
        if (id != null) {
          mapa[id] = item['fotoEventoUrl']?.toString();
        }
      }
      return mapa;
    }
    return {};
  }

  Future<String?> subirFotoEvento(int idEvento, String rutaArchivo) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$idEvento/foto'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final ext = rutaArchivo.split('.').last.toLowerCase();
    final mimeSubtype = ext == 'png'
        ? 'png'
        : ext == 'webp'
        ? 'webp'
        : 'jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'archivo',
        rutaArchivo,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['fotoEventoUrl']?.toString();
    }
    return null;
  }
}
