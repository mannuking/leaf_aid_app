import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/mongodb_service.dart';
import 'results_screen.dart';
import 'dart:math' as math;

class CameraScreen extends StatefulWidget {
  final String userId;
  
  const CameraScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isDetecting = false;
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  String? _modelLoadError;
  bool _isDbInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    await Future.wait([
      _initializeCamera(),
      _loadModel(),
      _initializeDatabase(),
      _checkLocationPermission(),
    ]);
  }

  Future<void> _initializeDatabase() async {
    try {
      await MongoDBService.initialize();
      if (mounted) {
        setState(() => _isDbInitialized = MongoDBService.isInitialized);
      }
    } catch (e) {
      debugPrint('Error initializing database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to database: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () async {
                await _initializeDatabase();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Changed from bgra8888 to yuv420
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/plant_disease_model.tflite',
        options: options,
      );
      setState(() {
        _isModelLoaded = true;
        _modelLoadError = null;
      });
      debugPrint('Model loaded successfully');
    } catch (e) {
      setState(() {
        _isModelLoaded = false;
        _modelLoadError = e.toString();
      });
      debugPrint('Error loading model: $e');
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    // Read and decode image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    // Resize image to 224x224
    final resized = img.copyResize(image, width: 224, height: 224);

    // Create input array in NCHW format [1, 3, 224, 224] as expected by the model
    // The model expects [batch, channels, height, width] format
    var input = List.generate(
      1, // batch size
      (_) => List.generate(
        3, // channels (RGB)
        (c) => List.generate(
          224, // height
          (y) => List.generate(
            224, // width
            (x) {
              final pixel = resized.getPixel(x, y);
              double pixelValue;
              
              // Get RGB values and normalize using the same values as in training
              if (c == 0) {
                // R channel
                pixelValue = (pixel.r / 255.0 - 0.485) / 0.229;
              } else if (c == 1) {
                // G channel
                pixelValue = (pixel.g / 255.0 - 0.456) / 0.224;
              } else {
                // B channel
                pixelValue = (pixel.b / 255.0 - 0.406) / 0.225;
              }
              return pixelValue;
            },
          ),
        ),
      ),
    );
    
    return input;
  }

  Future<void> _detectDisease(File imageFile) async {
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model not loaded. Please wait or restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDbInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database not initialized. Please wait or restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDetecting = true);

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Preprocess image
      final input = await _preprocessImage(imageFile);

      // Create output tensor
      var output = List.filled(1 * 39, 0.0).reshape([1, 39]); // 39 classes total

      // Run inference
      _interpreter!.run(input, output);

      // Apply softmax to get probabilities
      final probabilities = _applySoftmax(output[0]);

      // Find the class with highest probability
      var maxIndex = 0;
      var maxProbability = 0.0;
      for (var i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          maxIndex = i;
        }
      }

      // Only proceed if confidence is above threshold
      if (maxProbability < 0.5) {
        maxIndex = 4; // Background_without_leaves class index
        maxProbability = 1.0;
      }

      final diseaseName = _getDiseaseName(maxIndex);

      // Save image to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy(path.join(appDir.path, fileName));

      // Save scan result to MongoDB
      await MongoDBService.saveScanResult({
        'userId': widget.userId,
        'plantName': diseaseName,
        'diseaseDetected': diseaseName,
        'confidence': maxProbability,
        'imageUrl': savedImage.path,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              imageFile: savedImage,
              diseaseName: diseaseName,
              confidence: maxProbability,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during detection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  List<double> _applySoftmax(List<double> input) {
    double max = input.reduce((curr, next) => curr > next ? curr : next);
    List<double> exp = input.map((x) => math.exp(x - max)).toList();
    double sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
  }

  String _getDiseaseName(int index) {
    final diseases = [
      'Apple___Apple_scab',
      'Apple___Black_rot',
      'Apple___Cedar_apple_rust',
      'Apple___healthy',
      'Background_without_leaves',
      'Blueberry___healthy',
      'Cherry___Powdery_mildew',
      'Cherry___healthy',
      'Corn___Cercospora_leaf_spot Gray_leaf_spot',
      'Corn___Common_rust',
      'Corn___Northern_Leaf_Blight',
      'Corn___healthy',
      'Grape___Black_rot',
      'Grape___Esca_(Black_Measles)',
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
      'Grape___healthy',
      'Orange___Haunglongbing_(Citrus_greening)',
      'Peach___Bacterial_spot',
      'Peach___healthy',
      'Pepper,_bell___Bacterial_spot',
      'Pepper,_bell___healthy',
      'Potato___Early_blight',
      'Potato___Late_blight',
      'Potato___healthy',
      'Raspberry___healthy',
      'Soybean___healthy',
      'Squash___Powdery_mildew',
      'Strawberry___Leaf_scorch',
      'Strawberry___healthy',
      'Tomato___Bacterial_spot',
      'Tomato___Early_blight',
      'Tomato___Late_blight',
      'Tomato___Leaf_Mold',
      'Tomato___Septoria_leaf_spot',
      'Tomato___Spider_mites Two-spotted_spider_mite',
      'Tomato___Target_Spot',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
      'Tomato___Tomato_mosaic_virus',
      'Tomato___healthy'
    ];
    
    return index >= 0 && index < diseases.length ? diseases[index] : 'Unknown';
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them in settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied. Please enable them in settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Leaf'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_modelLoadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Leaf'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Model',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_modelLoadError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadModel,
                child: const Text('Retry Loading Model'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isDbInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Leaf'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Database Not Connected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Unable to connect to the database.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeDatabase,
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Leaf'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _isDetecting
                    ? null
                    : () async {
                        try {
                          final image = await _controller!.takePicture();
                          await _detectDisease(File(image.path));
                        } catch (e) {
                          debugPrint('Error capturing image: $e');
                          if (mounted) {
                            setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error capturing image. Please try again.'),
                                ),
                              );
                            }
                          }
                        }
                      },
                child: _isDetecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Scan Leaf'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
