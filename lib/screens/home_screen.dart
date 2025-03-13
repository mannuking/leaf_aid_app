import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../services/mongodb_service.dart';
import '../config/app_config.dart';
import 'package:mongo_dart/mongo_dart.dart' show where; // Corrected import

class HomeScreen extends StatefulWidget {
  final String userId;
  final Function(bool) toggleDarkMode;

  const HomeScreen({super.key, required this.userId, required this.toggleDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isDarkMode = false;

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      await MongoDBService.connect();
      final usersCollection = MongoDBService.db!.collection(AppConfig.usersCollection); // Corrected _db access
      final userData = await usersCollection.findOne(where.eq('userId', userId));
      return userData;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    widget.toggleDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Plant Disease Detector',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade400,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserData(widget.userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text(
                                'Welcome, User',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!['email'] == null) {
                              return const Text(
                                'Welcome, User',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            }

                            // Extract username from email
                            String email = snapshot.data!['email'];
                            String username = email.substring(0, email.indexOf('@'));

                            return Text(
                              'Welcome, $username',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Detect plant diseases instantly and get expert recommendations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(userId: widget.userId),
          ),
        ),
        label: const Text('Scan Now'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          'Scan History',
          'View your previous scans',
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryScreen(userId: widget.userId),
            ),
          ),
        ),
        _buildFeatureCard(
          'Profile',
          'Manage your account',
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: widget.userId),
            ),
          ),
        ),
        _buildFeatureCard(
          'Disease Guide',
          'Learn about plant diseases',
          Colors.orange,
          () {
            // TODO: Implement disease guide
          },
        ),
        _buildFeatureCard(
          'Tips & Tricks',
          'Farming best practices',
          Colors.purple,
          () {
            // TODO: Implement tips and tricks
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_florist,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
