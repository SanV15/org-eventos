import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/services/audio_service.dart';
import '../data/services/signalr_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Configuración del cliente HTTP (Dio)
    // Nota: baseUrl sin la barra final para evitar URLs como '//api/...'
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Interceptor para inyectar automáticamente el JWT
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    Get.put<Dio>(dio, permanent: true);

    // 2. Servicios de comunicación globales
    Get.put<SignalRService>(SignalRService(), permanent: true);
    Get.put<AudioService>(AudioService(dio), permanent: true);
  }
}
