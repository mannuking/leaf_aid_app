# Plant Disease Detector App

A Flutter mobile application that helps farmers detect plant diseases using their smartphone's camera and a pre-trained TensorFlow Lite model.

## Features

- Camera integration for leaf image capture
- Real-time plant disease detection using TensorFlow Lite
- Detailed results display with confidence scores
- Scan history tracking
- User profile management
- Dark mode support
- Offline functionality

## Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code with Flutter extensions
- Android Emulator or physical device for testing
- iOS Simulator or physical device (requires macOS)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/plant_disease_detector_app.git
cd plant_disease_detector_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Place your TensorFlow Lite model:
- Create a directory: `assets/models/`
- Place your `.tflite` model file in this directory
- Update the model path in `lib/screens/camera_screen.dart` if needed

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── results_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
├── widgets/
├── models/
├── services/
├── utils/
└── main.dart
```

## Dependencies

- camera: ^0.10.5+4
- tflite_flutter: ^0.9.0
- image: ^4.1.3
- shared_preferences: ^2.2.2
- provider: ^6.0.5
- google_fonts: ^6.1.0
- flutter_svg: ^2.0.7

## Usage

1. Launch the app
2. Tap "Scan Leaf" on the home screen
3. Position the plant leaf in the camera view
4. Tap the "Scan Leaf" button to capture and analyze
5. View the detection results and recommendations
6. Access scan history and profile settings from the home screen

## Model Information

The app uses a pre-trained TensorFlow Lite model with the following specifications:
- Input size: 224x224 pixels
- Output: 38 plant disease classes
- Accuracy: 99.17%

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- TensorFlow Lite team for the model conversion tools
- Flutter team for the excellent framework
- Plant disease dataset contributors 
