import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/itransport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final String _serverUrl = '$apiBaseUrl/hubs/eventos';

  HubConnection? get connection => _hubConnection;

  // Callbacks para Tareas y Walkie
  Function(Map<String, dynamic>)? onTareaActualizada;
  Function(Map<String, dynamic>)? onIncidenciaReportada;
  Function()? onRecargarLista;
  Function(Map<String, dynamic>)? onNotaVozRecibida;

  bool _isConnecting = false;

  /// Extrae el idUsuario del payload del JWT guardado en SharedPreferences
  int? _extraerIdUsuarioDeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payload = json.decode(payloadString);

      final rawId =
          payload['sub'] ??
          payload['nameid'] ??
          payload['idUsuario'] ??
          payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];

      if (rawId == null) return null;
      return int.tryParse(rawId.toString());
    } catch (e) {
      debugPrint(
        'SignalR Flutter: Error al decodificar idUsuario del token: $e',
      );
      return null;
    }
  }

  /// Une la conexión actual a la sala personal del usuario autenticado
  Future<void> _unirseASalaPersonal(int? idUsuario) async {
    if (idUsuario == null ||
        _hubConnection?.state != HubConnectionState.Connected) {
      return;
    }

    try {
      await _hubConnection?.invoke('UnirseAUsuario', args: [idUsuario]);
      debugPrint('SignalR Flutter: Unido exitosamente a Usuario_$idUsuario');
    } catch (e) {
      debugPrint('SignalR Flutter: Error al invocar UnirseAUsuario: $e');
    }
  }

  /// Inicia la conexión una sola vez de forma compartida
  Future<void> conectar() async {
    if (_hubConnection?.state == HubConnectionState.Connected ||
        _isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final idUsuario = _extraerIdUsuarioDeToken(token);

      final httpOptions = HttpConnectionOptions(
        accessTokenFactory: () async => token,
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
        headers: MessageHeaders()
          ..setHeaderValue('X-Tunnel-Skip-AntiPishing-Page', 'true'),
      );

      _hubConnection = HubConnectionBuilder()
          .withUrl(_serverUrl, options: httpOptions)
          .withAutomaticReconnect()
          .build();

      // Re-suscribir a la sala personal si se pierde y recupera la conexión
      _hubConnection?.onreconnected(({connectionId}) async {
        debugPrint(
          'SignalR Flutter: Reconectado ($connectionId). Reuniendo a sala personal...',
        );
        await _unirseASalaPersonal(idUsuario);
      });

      // Listeners de Tareas
      _hubConnection?.on('TareaEstadoActualizada', (arguments) {
        if (arguments != null &&
            arguments.isNotEmpty &&
            onTareaActualizada != null) {
          onTareaActualizada!(Map<String, dynamic>.from(arguments[0] as Map));
        }
      });

      _hubConnection?.on('IncidenciaReportada', (arguments) {
        if (arguments != null &&
            arguments.isNotEmpty &&
            onIncidenciaReportada != null) {
          onIncidenciaReportada!(
            Map<String, dynamic>.from(arguments[0] as Map),
          );
        }
      });

      _hubConnection?.on('TareaEditada', (arguments) {
        if (arguments != null &&
            arguments.isNotEmpty &&
            onTareaActualizada != null) {
          onTareaActualizada!(Map<String, dynamic>.from(arguments[0] as Map));
        }
      });

      _hubConnection?.on('NuevaTareaAsignada', (arguments) {
        debugPrint(
          'SignalR Flutter: Nueva tarea asignada recibida. Recargando y notificando...',
        );
        if (onRecargarLista != null) onRecargarLista!();
      });

      _hubConnection?.on('TareaCreada', (arguments) {
        debugPrint('SignalR Flutter: Tarea nueva detectada. Recargando...');
        if (onRecargarLista != null) onRecargarLista!();
      });

      _hubConnection?.on('TareaEliminada', (arguments) {
        debugPrint('SignalR Flutter: Tarea eliminada detectada. Recargando...');
        if (onRecargarLista != null) onRecargarLista!();
      });

      // Listener de Walkie-Talkie
      _hubConnection?.on('NotaVozRecibida', (arguments) {
        debugPrint('>>> [SIGNALR RECIBIDO] arguments: $arguments');
        if (arguments != null &&
            arguments.isNotEmpty &&
            onNotaVozRecibida != null) {
          onNotaVozRecibida!(Map<String, dynamic>.from(arguments[0] as Map));
        }
      });

      await _hubConnection?.start();
      debugPrint('SignalR Flutter: Conectado con éxito.');

      // Unir al grupo personal Usuario_{id} para recibir asignaciones de cualquier evento
      await _unirseASalaPersonal(idUsuario);
    } catch (e) {
      debugPrint('SignalR Flutter Error al conectar: $e');
    } finally {
      _isConnecting = false;
    }
  }

  // Compatibilidad hacia atrás si tu TareasController llama a initConnection
  Future<void> initConnection({
    required Function(Map<String, dynamic>) onTareaActualizada,
    required Function(Map<String, dynamic>) onIncidenciaReportada,
    required Function() onRecargarLista,
    Function(Map<String, dynamic>)? onNotaVoz,
  }) async {
    this.onTareaActualizada = onTareaActualizada;
    this.onIncidenciaReportada = onIncidenciaReportada;
    this.onRecargarLista = onRecargarLista;
    if (onNotaVoz != null) this.onNotaVozRecibida = onNotaVoz;

    await conectar();
  }

  Future<void> unirseAEvento(int idEvento) async {
    if (_hubConnection == null) {
      await conectar();
    }

    int reintentos = 0;
    while ((_hubConnection?.state != HubConnectionState.Connected) &&
        reintentos < 20) {
      await Future.delayed(const Duration(milliseconds: 300));
      reintentos++;
    }

    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke('UnirseAEvento', args: [idEvento]);
        debugPrint('SignalR Flutter: Unido exitosamente a Evento_$idEvento');
      } catch (e) {
        debugPrint('SignalR Flutter: Error al invocar UnirseAEvento: $e');
      }
    } else {
      debugPrint(
        'SignalR Flutter: No se pudo unir al grupo porque el estado es ${_hubConnection?.state}',
      );
    }
  }

  Future<bool> emitirNotaVoz(
    int idEvento,
    String publicUrl,
    String emisorNombre,
  ) async {
    if (_hubConnection == null ||
        _hubConnection?.state != HubConnectionState.Connected) {
      debugPrint(
        'SignalR Flutter: No conectado, intentando conectar antes de emitir...',
      );
      await conectar();
    }

    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.send(
          'EnviarNotaVoz',
          args: [idEvento, publicUrl, emisorNombre],
        );
        debugPrint(
          'SignalR Flutter: Nota de voz transmitida por el Hub con éxito.',
        );
        return true;
      } catch (e, stack) {
        debugPrint('SignalR Flutter: Error al emitir EnviarNotaVoz: $e');
        debugPrint('SignalR Flutter Stack: $stack');
        return false;
      }
    } else {
      debugPrint(
        'SignalR Flutter Error: HubConnection no conectado (Estado: ${_hubConnection?.state})',
      );
      return false;
    }
  }

  Future<void> desconectar() async {
    await _hubConnection?.stop();
  }
}
