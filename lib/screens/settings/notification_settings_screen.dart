import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _jobNotifications = true;
  bool _messageNotifications = true;
  bool _applicationNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jobNotifications = prefs.getBool('job_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _applicationNotifications = prefs.getBool('application_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSection(
            title: 'Tipos de notificaciones',
            children: [
              SwitchListTile(
                title: const Text('Trabajos'),
                subtitle: const Text('Nuevos trabajos, actualizaciones de estado'),
                value: _jobNotifications,
                onChanged: (value) {
                  setState(() => _jobNotifications = value);
                  _saveSetting('job_notifications', value);
                },
              ),
              SwitchListTile(
                title: const Text('Mensajes'),
                subtitle: const Text('Nuevos mensajes de chat'),
                value: _messageNotifications,
                onChanged: (value) {
                  setState(() => _messageNotifications = value);
                  _saveSetting('message_notifications', value);
                },
              ),
              SwitchListTile(
                title: const Text('Solicitudes'),
                subtitle: const Text('Solicitudes de trabajo aceptadas o rechazadas'),
                value: _applicationNotifications,
                onChanged: (value) {
                  setState(() => _applicationNotifications = value);
                  _saveSetting('application_notifications', value);
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Preferencias',
            children: [
              SwitchListTile(
                title: const Text('Sonido'),
                subtitle: const Text('Reproducir sonido al recibir notificaciones'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _saveSetting('sound_enabled', value);
                },
              ),
              SwitchListTile(
                title: const Text('Vibración'),
                subtitle: const Text('Vibrar al recibir notificaciones'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSetting('vibration_enabled', value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
