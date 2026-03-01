import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationMirror.instance.init();
  runApp(const MyApp());
}

class NotificationMirror {
  NotificationMirror._();

  static final NotificationMirror instance = NotificationMirror._();

  static const MethodChannel _methodChannel =
      MethodChannel('maps_notification_bridge/methods');
  static const EventChannel _eventChannel =
      EventChannel('maps_notification_bridge/events');

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<dynamic>? _eventsSubscription;
  final List<String> _history = <String>[];

  List<String> get history => List<String>.unmodifiable(_history);

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    if (Platform.isAndroid) {
      await Permission.notification.request();
      await _methodChannel.invokeMethod<void>('startForegroundGuard');
      _eventsSubscription ??= _eventChannel.receiveBroadcastStream().listen(
        _onNotificationEvent,
      );
    }
  }

  Future<bool> isNotificationAccessGranted() async {
    final granted =
        await _methodChannel.invokeMethod<bool>('isNotificationAccessGranted');
    return granted ?? false;
  }

  Future<void> openNotificationAccessSettings() async {
    await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<void> _onNotificationEvent(dynamic event) async {
    if (event is! Map) return;

    final packageName = (event['packageName'] ?? '').toString();
    if (packageName != 'com.google.android.apps.maps') return;

    final title = (event['title'] ?? 'Google Maps').toString();
    final text = (event['text'] ?? 'Nueva indicación de navegación').toString();
    final timestamp = DateTime.now().toIso8601String();

    _history.insert(0, '[$timestamp] $title: $text');

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Navegación: $title',
      text,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maps_mirror_channel',
          'Maps Mirror Notifications',
          channelDescription:
              'Notificaciones replicadas desde Google Maps para navegación.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  void dispose() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _accessGranted = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final granted = await NotificationMirror.instance.isNotificationAccessGranted();
    if (!mounted) return;
    setState(() {
      _accessGranted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = NotificationMirror.instance.history;

    return MaterialApp(
      title: 'Maps Notification Bridge',
      home: Scaffold(
        appBar: AppBar(title: const Text('Maps Notification Bridge')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accessGranted
                            ? '✅ Acceso a notificaciones concedido'
                            : '⚠️ Debes habilitar acceso a notificaciones',
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          await NotificationMirror.instance
                              .openNotificationAccessSettings();
                        },
                        child: const Text('Abrir ajustes de acceso'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _loadState,
                        child: const Text('Revisar estado'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Historial de notificaciones duplicadas:'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    title: Text(history[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    NotificationMirror.instance.dispose();
    super.dispose();
  }
}
