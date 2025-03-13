import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mongodb_service.dart';

class ScanHistory {
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final DateTime timestamp;

  ScanHistory({
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanHistory.fromJson(Map<String, dynamic> json) => ScanHistory(
        imagePath: json['imagePath'],
        diseaseName: json['diseaseName'],
        confidence: json['confidence'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class HistoryScreen extends StatelessWidget {
  final String userId;

  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MongoDBService.getUserScans(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final scans = snapshot.data ?? [];
          if (scans.isEmpty) {
            return const Center(
              child: Text('No scan history available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              final timestamp = scan['timestamp'] as DateTime;
              final location = scan['location']['coordinates'] as List;
              final isHealthy = scan['diseaseName'].toString().toLowerCase().contains('healthy');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(scan['imagePath']),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scan['diseaseName'].toString().replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isHealthy ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Confidence: ${(scan['confidence'] * 100).toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy h:mm a').format(timestamp),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Lat: ${location[1].toStringAsFixed(4)}, Long: ${location[0].toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
