class AppConfig {
  // Clerk Configuration
  static const String clerkPublishableKey = 'YOUR_CLERK_PUBLISHABLE_KEY';
  static const String clerkSecretKey = 'YOUR_CLERK_SECRET_KEY';

  // MongoDB Configuration
  static const String mongoDbUrl = 'YOUR_MONGODB_CONNECTION_STRING';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String scansCollection = 'scans';
  static const String analyticsCollection = 'analytics';

  // Other API keys or sensitive data can be added here
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';
}

// This is a template file. Copy this file to app_config.dart and replace the placeholder values with your actual credentials.
// DO NOT modify this template with real credentials. 
