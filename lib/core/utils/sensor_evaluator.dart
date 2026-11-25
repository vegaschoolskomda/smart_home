import '../constants/app_constants.dart';

/// Helper methods to evaluate sensor readings based on thresholds
class SensorEvaluator {
  SensorEvaluator._();

  static bool isTemperatureHigh(double temp) {
    return temp >= AppConstants.tempHighThreshold;
  }

  static String getTemperatureStatus(double temp) {
    if (temp >= AppConstants.tempHighThreshold) {
      return 'Tinggi';
    } else if (temp < 20.0) {
      return 'Dingin';
    }
    return 'Normal';
  }

  static bool isGasHigh(int gasValue) {
    return gasValue >= AppConstants.gasHighThreshold;
  }

  static String getGasStatus(int gasValue) {
    if (gasValue >= AppConstants.gasHighThreshold) {
      return 'Bahaya / Asap Terdeteksi';
    } else if (gasValue > 800) {
      return 'Waspada';
    }
    return 'Aman';
  }

  static bool isLightBright(int ldrValue) {
    // For typical LDR analog reading: lower value = bright, higher = dark (or depending on module ADC)
    // We treat value < 2000 as Terang, >= 2000 as Gelap (adjustable)
    return ldrValue < AppConstants.ldrDarkThreshold;
  }

  static String getLightStatus(int ldrValue) {
    return isLightBright(ldrValue) ? 'Terang' : 'Gelap';
  }

  static String getRainStatus(bool isRaining) {
    return isRaining ? 'Hujan' : 'Tidak Hujan';
  }

  static String getVisitorStatus(bool isDetected) {
    return isDetected ? 'Tamu Terdeteksi' : 'Tidak Ada Tamu';
  }

  static String getVehicleStatus(String vehicleStatus) {
    if (vehicleStatus.trim().toLowerCase() == 'ada') {
      return 'Mobil Ada';
    }
    return 'Mobil Tidak Ada';
  }
}
