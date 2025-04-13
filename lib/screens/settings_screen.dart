import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsBox = Hive.box('settings');

  bool _useBiometrics = true;
  bool _autoLock = true;
  int _autoLockTime = 5; // minutes
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _useBiometrics = _settingsBox.get('useBiometrics', defaultValue: true);
      _autoLock = _settingsBox.get('autoLock', defaultValue: true);
      _autoLockTime = _settingsBox.get('autoLockTime', defaultValue: 5);
      _notificationsEnabled =
          _settingsBox.get('notificationsEnabled', defaultValue: true);
      _darkMode = _settingsBox.get('darkMode', defaultValue: false);
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> _toggleBiometrics(bool value) async {
    setState(() {
      _useBiometrics = value;
    });
    await _saveSetting('useBiometrics', value);
  }

  Future<void> _toggleAutoLock(bool value) async {
    setState(() {
      _autoLock = value;
    });
    await _saveSetting('autoLock', value);
  }

  Future<void> _setAutoLockTime(int minutes) async {
    setState(() {
      _autoLockTime = minutes;
    });
    await _saveSetting('autoLockTime', minutes);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _saveSetting('notificationsEnabled', value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _darkMode = value;
    });
    await _saveSetting('darkMode', value);

    // In a real app, you would update the ThemeMode here
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canUseBiometrics = authService.isBiometricsAvailable();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<bool>(
        future: canUseBiometrics,
        builder: (context, snapshot) {
          final biometricsAvailable = snapshot.data ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Security section
              _buildSectionHeader('Security'),
              if (biometricsAvailable)
                _buildSwitchTile(
                  title: 'Use Biometric Authentication',
                  subtitle:
                      'Use fingerprint or face recognition for quick access',
                  value: _useBiometrics,
                  onChanged: _toggleBiometrics,
                  icon: Icons.fingerprint,
                ),
              _buildSwitchTile(
                title: 'Auto-Lock',
                subtitle: 'Automatically lock the app when not in use',
                value: _autoLock,
                onChanged: _toggleAutoLock,
                icon: Icons.lock_clock,
              ),
              if (_autoLock)
                _buildDropdownTile(
                  title: 'Auto-Lock Time',
                  value: _autoLockTime,
                  items: const [1, 5, 10, 15, 30],
                  labelBuilder: (value) => '$value minutes',
                  onChanged: (int? value) {
                    if (value != null) {
                      _setAutoLockTime(value);
                    }
                  },
                  icon: Icons.timer,
                ),

              const Divider(),

              // Appearance section
              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkMode,
                onChanged: _toggleDarkMode,
                icon: Icons.dark_mode,
              ),

              const Divider(),

              // Notifications section
              _buildSectionHeader('Notifications'),
              _buildSwitchTile(
                title: 'Enable Notifications',
                subtitle: 'Receive notifications about your identity wallet',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                icon: Icons.notifications,
              ),

              const Divider(),

              // Data management section
              _buildSectionHeader('Data Management'),
              _buildActionTile(
                title: 'Clear Cache',
                subtitle: 'Clear temporary data',
                icon: Icons.cleaning_services,
                onTap: () {
                  _showConfirmationDialog(
                    title: 'Clear Cache',
                    message:
                        'Are you sure you want to clear the cache? This won\'t delete your documents.',
                    onConfirm: () {
                      // Clear cache logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    },
                  );
                },
              ),
              _buildActionTile(
                title: 'Export Data',
                subtitle: 'Export your identity data',
                icon: Icons.download,
                onTap: () {
                  // Export data logic
                },
              ),

              const Divider(),

              // About section
              _buildSectionHeader('About'),
              _buildInfoTile(
                title: 'Version',
                value: '1.0.0',
                icon: Icons.info,
              ),
              _buildActionTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.privacy_tip,
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
              _buildActionTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                icon: Icons.description,
                onTap: () {
                  // Navigate to terms of service
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTheme.subheadingStyle.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }
}
