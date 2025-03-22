import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _highQualityImages = true;
  bool _autoSaveHistory = true;
  String _language = 'English';
  String _measurementUnit = 'Metric';
  String? _geminiApiKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? false;
      _highQualityImages = prefs.getBool('high_quality_images') ?? true;
      _autoSaveHistory = prefs.getBool('auto_save_history') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _measurementUnit = prefs.getString('measurement_unit') ?? 'Metric';
      _geminiApiKey = prefs.getString('gemini_api_key');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_enabled', _locationEnabled);
    await prefs.setBool('high_quality_images', _highQualityImages);
    await prefs.setBool('auto_save_history', _autoSaveHistory);
    await prefs.setString('language', _language);
    await prefs.setString('measurement_unit', _measurementUnit);
    if (_geminiApiKey != null) {
      await prefs.setString('gemini_api_key', _geminiApiKey!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scan history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement clear history functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }

  Future<void> _setGeminiApiKey() async {
    final TextEditingController controller = TextEditingController(text: _geminiApiKey);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Gemini API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get your API key from the Google AI Studio website.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _geminiApiKey = result);
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildThemeSection(context),
          const Divider(),
          _buildNotificationsSection(context),
          const Divider(),
          _buildDataSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Theme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeProvider.setThemeMode(mode);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeProvider.setThemeMode(mode);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeProvider.setThemeMode(mode);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive alerts about plant care'),
          value: true, // TODO: Implement notifications logic
          onChanged: (bool value) {
            // TODO: Implement notifications toggle
          },
        ),
        SwitchListTile(
          title: const Text('Disease Alerts'),
          subtitle: const Text('Get notified about potential plant diseases'),
          value: true, // TODO: Implement disease alerts logic
          onChanged: (bool value) {
            // TODO: Implement disease alerts toggle
          },
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Data & Storage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          title: const Text('Clear Scan History'),
          subtitle: const Text('Delete all previous plant scans'),
          leading: const Icon(Icons.delete_outline),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear History'),
                content: const Text('Are you sure you want to clear all scan history?'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Clear'),
                    onPressed: () {
                      // TODO: Implement clear history
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Image Quality'),
          subtitle: const Text('Adjust scan image quality'),
          leading: const Icon(Icons.high_quality),
          onTap: () {
            // TODO: Implement image quality settings
          },
        ),
      ],
    );
  }
} 
