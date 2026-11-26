import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/signalr_service.dart';
import '../data/services/audio_service.dart';
import 'auth_controller.dart';

class WalkieController extends GetxController {
  final SignalRService _signalRService = Get.find<SignalRService>();
  final AudioService _audioService = Get.find<AudioService>();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var isRecording = false.obs;
  var isPlaying = false.obs;

  // Variables dinámicas para UI y transmisión
  var nombreUsuario = 'Operador Staff'.obs;
  var emisorActual = ''.obs;
  var idEventoActual = 19.obs;

  String? _rutaAudioLocal;

  @override
  void onInit() {
    super.onInit();
    _cargarDatosOperador();
    _configurarEscuchaAudio();
    _conectarSignalR();
  }

  Future<void> _cargarDatosOperador() async {
    try {
      // 1. Intenta tomar el nombre o correo desde AuthController si existe
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final correo = auth.correoController.text.trim();
        if (correo.isNotEmpty) {
          nombreUsuario.value = correo.split('@').first;
          return;
        }
      }

      // 2. Si no, lo busca en SharedPreferences guardado en el login
      final prefs = await SharedPreferences.getInstance();
      final guardado =
          prefs.getString('user_nombre') ??
          prefs.getString('nombre') ??
          prefs.getString('user_email');

      if (guardado != null && guardado.isNotEmpty) {
        nombreUsuario.value = guardado.contains('@')
            ? guardado.split('@').first
            : guardado;
      }
    } catch (e) {
      debugPrint('>>> [WALKIE] Error al resolver operador: $e');
    }
  }

  void _configurarEscuchaAudio() {
    _signalRService.onNotaVozRecibida = (data) async {
      debugPrint('>>> [WALKIE] Evento procesado en controller: $data');
      final audioUrl = data['audioUrl'] as String?;
      final emisor = data['emisorNombre'] as String? ?? 'Desconocido';

      if (audioUrl != null && audioUrl.isNotEmpty) {
        emisorActual.value = emisor;
        isPlaying.value = true;

        try {
          await _audioPlayer.setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                isSpeakerphoneOn: true,
                stayAwake: true,
                contentType: AndroidContentType.speech,
                usageType: AndroidUsageType.media,
                audioFocus: AndroidAudioFocus.gainTransientExclusive,
              ),
            ),
          );

          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(audioUrl));

          _audioPlayer.onPlayerComplete.listen((_) {
            debugPrint('>>> [WALKIE] Reproducción finalizada.');
            isPlaying.value = false;
            emisorActual.value = '';
          });
        } catch (e) {
          debugPrint('>>> [WALKIE ERROR] Error al reproducir audio: $e');
          isPlaying.value = false;
          emisorActual.value = '';
        }
      }
    };
  }

  Future<void> _conectarSignalR() async {
    try {
      await _signalRService.conectar();
      await _signalRService.unirseAEvento(idEventoActual.value);
    } catch (e) {
      debugPrint('>>> [WALKIE ERROR] Error al enlazar SignalR: $e');
    }
  }

  Future<void> iniciarGrabacion() async {
    try {
      final tienePermiso = await _audioRecorder.hasPermission();
      if (tienePermiso) {
        final dir = await getTemporaryDirectory();
        _rutaAudioLocal =
            '${dir.path}/ptt_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: _rutaAudioLocal!);
        isRecording.value = true;
      }
    } catch (e) {
      debugPrint('>>> [WALKIE ERROR] Error al iniciar grabación: $e');
    }
  }

  Future<void> finalizarYTransmitir() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;

      if (path != null && File(path).existsSync()) {
        final archivo = File(path);
        final credencialesS3 = await _audioService.obtenerUrlsSubida();

        if (credencialesS3 != null) {
          final subidaExitosa = await _audioService.subirArchivoAS3(
            credencialesS3['uploadUrl']!,
            archivo,
          );

          if (subidaExitosa) {
            await _signalRService.emitirNotaVoz(
              idEventoActual.value,
              credencialesS3['publicUrl']!,
              nombreUsuario.value, // Envía el nombre dinámico resuelto
            );
          }
        }
      }
    } catch (e) {
      isRecording.value = false;
      debugPrint('>>> [WALKIE ERROR] Excepción al finalizar: $e');
    }
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }
}
