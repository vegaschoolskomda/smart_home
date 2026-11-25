/// System-wide constants for Smart Home IoT
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Home';
  static const String appDescription = 'Monitoring IoT Real-time ESP32';

  // Sensor threshold defaults
  static const double tempHighThreshold = 33.0; // °C
  static const int gasHighThreshold = 1400; // ppm/analog
  static const int ldrDarkThreshold = 1800; // Analog value (higher = darker or vice versa depending on module)
  static const double visitorDetectDistance = 50.0; // cm
  static const double vehicleDetectDistance = 120.0; // cm

  // Notification cooldown (in seconds)
  static const int notificationCooldownSeconds = 30;

  // Polling interval
  static const Duration pollingInterval = Duration(milliseconds: 1500);

  // Database retention limit
  static const int maxLogEntries = 200;
}
