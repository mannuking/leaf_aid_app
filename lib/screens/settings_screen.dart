import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/loading_animation.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _highQualityImages = true;
  bool _autoSaveHistory = true;
  String _language = 'English';
  String _measurementUnit = 'Metric';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationEnabled = prefs.getBool('location') ?? true;
      _highQualityImages = prefs.getBool('highQualityImages') ?? true;
      _autoSaveHistory = prefs.getBool('autoSaveHistory') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _measurementUnit = prefs.getString('measurementUnit') ?? 'Metric';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _isDarkMode);
      await prefs.setBool('notifications', _notificationsEnabled);
      await prefs.setBool('location', _locationEnabled);
      await prefs.setBool('highQualityImages', _highQualityImages);
      await prefs.setBool('autoSaveHistory', _autoSaveHistory);
      await prefs.setString('language', _language);
      await prefs.setString('measurementUnit', _measurementUnit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationEnabled = status.isGranted;
    });
    _saveSettings();
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
      setState(() {
        _isSaving = true;
      });

      try {
        // TODO: Implement history clearing logic
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History cleared successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing history: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingAnimation(message: 'Loading settings...')
          : Stack(
              children: [
                ListView(
                  children: [
                    _buildSectionHeader('Appearance'),
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Enable dark theme for the app'),
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        _saveSettings();
                      },
                    ),
                    ListTile(
                      title: const Text('Language'),
                      subtitle: Text(_language),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Language'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('English'),
                                  onTap: () {
                                    setState(() => _language = 'English');
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                                ListTile(
                                  title: const Text('Spanish'),
                                  onTap: () {
                                    setState(() => _language = 'Spanish');
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSectionHeader('Notifications'),
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive notifications about scan results and updates'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSectionHeader('Location & Camera'),
                    SwitchListTile(
                      title: const Text('Location Services'),
                      subtitle: const Text('Allow app to access your location for better disease detection'),
                      value: _locationEnabled,
                      onChanged: (value) async {
                        if (value) {
                          await _requestLocationPermission();
                        } else {
                          setState(() {
                            _locationEnabled = false;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('High Quality Images'),
                      subtitle: const Text('Capture high resolution images for better accuracy'),
                      value: _highQualityImages,
                      onChanged: (value) {
                        setState(() {
                          _highQualityImages = value;
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSectionHeader('History & Data'),
                    SwitchListTile(
                      title: const Text('Auto-save History'),
                      subtitle: const Text('Automatically save scan results to history'),
                      value: _autoSaveHistory,
                      onChanged: (value) {
                        setState(() {
                          _autoSaveHistory = value;
                        });
                        _saveSettings();
                      },
                    ),
                    ListTile(
                      title: const Text('Clear History'),
                      subtitle: const Text('Delete all your scan history'),
                      leading: const Icon(Icons.delete_forever),
                      onTap: _clearHistory,
                    ),
                    _buildSectionHeader('Units'),
                    ListTile(
                      title: const Text('Measurement Unit'),
                      subtitle: Text(_measurementUnit),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Measurement Unit'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Metric'),
                                  onTap: () {
                                    setState(() => _measurementUnit = 'Metric');
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                                ListTile(
                                  title: const Text('Imperial'),
                                  onTap: () {
                                    setState(() => _measurementUnit = 'Imperial');
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSectionHeader('About'),
                    const ListTile(
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                      leading: Icon(Icons.info),
                    ),
                    ListTile(
                      title: const Text('Terms of Service'),
                      leading: const Icon(Icons.description),
                      onTap: () {
                        // TODO: Implement terms of service
                      },
                    ),
                    ListTile(
                      title: const Text('Privacy Policy'),
                      leading: const Icon(Icons.privacy_tip),
                      onTap: () {
                        // TODO: Implement privacy policy
                      },
                    ),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const LoadingAnimation(message: 'Saving settings...'),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
} 
