import 'dart:core';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final Dio _dio;

  AudioService(this._dio);

  // /// Solicita a la API en C# la URL prefirmada de S3
  // Future<Map<String, String>?> obtenerUrlsSubida() async {
  //   try {
  //     final response = await _dio.get('/api/audio/presigned-url?extension=m4a');
  //     if (response.statusCode == 200) {
  //       return {
  //         'uploadUrl': response.data['uploadUrl'] as String,
  //         'publicUrl': response.data['publicUrl'] as String,
  //       };
  //     }
  //   } catch (e) {
  //     debugPrint('Error al solicitar presigned URL: $e');
  //   }
  //   return null;
  // }

  /// Realiza la carga directa del archivo hacia el bucket de AWS S3
  // Future<bool> subirArchivoAS3(String uploadUrl, File archivoAudio) async {
  //   try {
  //     final dioS3 = Dio(); // Instancia limpia sin interceptores de autenticación local
  //     final longitud = await archivoAudio.length();
      
  //     final response = await dioS3.put(
  //       uploadUrl,
  //       data: archivoAudio.openRead(),
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'audio/m4a',
  //           'Content-Length': longitud,
  //         },
  //       ),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     debugPrint('Error en la transferencia a S3: $e');
  //     return false;
  //   }
  // }
  Future<Map<String, String>?> obtenerUrlsSubida() async {
    try {
      const endpoint = '/api/audio/presigned-url?extension=m4a';
      print(
        '>>> [AUDIO_SERVICE] Peticion a URL completa: ${_dio.options.baseUrl}$endpoint',
      );

      final response = await _dio.get(endpoint);
      print('>>> [AUDIO_SERVICE] Status presigned-url: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {
          'uploadUrl': response.data['uploadUrl'] as String,
          'publicUrl': response.data['publicUrl'] as String,
        };
      }
    } catch (e) {
      print('>>> [AUDIO_SERVICE ERROR] Error al solicitar presigned URL: $e');
    }
    return null;
  }

  Future<bool> subirArchivoAS3(String uploadUrl, File archivoAudio) async {
    try {
      final dioS3 = Dio();
      final longitud = await archivoAudio.length();

      final response = await dioS3.put(
        uploadUrl,
        data: archivoAudio.openRead(),
        options: Options(
          headers: {
            'Content-Type': 'audio/m4a',
            'Content-Length': longitud,
          },
        ),
      );

      print('>>> [AUDIO_SERVICE] Status subida S3: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('>>> [AUDIO_SERVICE ERROR] Error en la transferencia a S3: $e');
      return false;
    }
  }


  
}