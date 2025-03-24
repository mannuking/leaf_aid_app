import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mongodb_service.dart';
import 'package:provider/provider.dart';
import '../providers/plant_stats_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    // Here you would typically load the scan history from your backend or local storage
    // For now, we'll use the example scans you provided
    setState(() {
      _scanResults = [
        ScanResult(
          image: 'path_to_image1',
          result: 'Background without leaves',
          confidence: 99.97,
          timestamp: DateTime(2025, 3, 24, 15, 18),
          isHealthy: false,
        ),
        ScanResult(
          image: 'path_to_image2',
          result: 'Apple healthy',
          confidence: 93.68,
          timestamp: DateTime(2025, 3, 24, 15, 19),
          isHealthy: true,
        ),
      ];
    });

    // Update plant stats based on scan results
    final plantStats = Provider.of<PlantStatsProvider>(context, listen: false);
    for (var scan in _scanResults) {
      if (scan.result.toLowerCase() != 'background without leaves') {
        await plantStats.updateStats(isHealthy: scan.isHealthy);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final scan = _scanResults[index];
          final isHealthyPlant = scan.result.toLowerCase().contains('healthy');
          final isBackground = scan.result.toLowerCase().contains('background');

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBackground ? Icons.image_not_supported : 
                      isHealthyPlant ? Icons.check_circle : Icons.warning,
                      color: isBackground ? Colors.grey :
                      isHealthyPlant ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Scan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.result,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isBackground ? Colors.grey :
                            isHealthyPlant ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${scan.confidence.toStringAsFixed(2)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${scan.timestamp.toString().split('.')[0]}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScanResult {
  final String image;
  final String result;
  final double confidence;
  final DateTime timestamp;
  final bool isHealthy;

  ScanResult({
    required this.image,
    required this.result,
    required this.confidence,
    required this.timestamp,
    required this.isHealthy,
  });
} 
