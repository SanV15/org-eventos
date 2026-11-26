import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  Future<void> init() async {
    if (_inicializado) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Merida'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Solicitar permisos en Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    _inicializado = true;
  }

  NotificationDetails _detallesCanal() {
    const androidDetails = AndroidNotificationDetails(
      'canal_logistica_tareas',
      'Notificaciones de Tareas',
      channelDescription:
          'Alertas de asignación, cambios de estado y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Muestra una notificación al instante
  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    await init();
    await _plugin.show(id, titulo, cuerpo, _detallesCanal());
  }

  /// Programa un recordatorio 30 minutos antes de la fecha límite
  Future<void> programarRecordatorioMediaHora({
    required int idTarea,
    required String nombreTarea,
    required String nombreEvento,
    required DateTime fechaLimite,
  }) async {
    await init();

    final fechaRecordatorio = fechaLimite.subtract(const Duration(minutes: 30));
    final ahora = DateTime.now();

    // Solo programar si aún faltan más de 30 minutos
    if (fechaRecordatorio.isBefore(ahora)) return;

    final tzFecha = tz.TZDateTime.from(fechaRecordatorio, tz.local);

    // Usamos idTarea + 100000 para no colisionar con IDs de notificaciones inmediatas
    await _plugin.zonedSchedule(
      idTarea + 100000,
      '⏰ Hito próximo en 30 min',
      '$nombreTarea ($nombreEvento)',
      tzFecha,
      _detallesCanal(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela el recordatorio si la tarea ya se completó o canceló
  Future<void> cancelarRecordatorio(int idTarea) async {
    await _plugin.cancel(idTarea + 100000);
  }
}
