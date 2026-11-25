import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/sensor_evaluator.dart';
import '../../../data/models/esp32_data_model.dart';

class SecuritySection extends StatelessWidget {
  final Esp32DataModel? data;
  final bool isOnline;

  const SecuritySection({
    super.key,
    required this.data,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasData = isOnline && data != null;

    final bool visitorDetected = hasData && data!.visitorDetected;
    final double visitorDistance = hasData ? data!.visitorDistance : 0.0;
    final String visitorStatus = hasData
        ? SensorEvaluator.getVisitorStatus(visitorDetected)
        : 'Tidak Tersedia';

    final String rawVehicle = hasData ? data!.vehicleStatus : 'Tidak Ada';
    final bool vehiclePresent = rawVehicle.trim().toLowerCase() == 'ada';
    final double vehicleDistance = hasData ? data!.vehicleDistance : 0.0;
    final String vehicleStatus = hasData
        ? SensorEvaluator.getVehicleStatus(rawVehicle)
        : 'Tidak Tersedia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: AppColors.tealPrimary),
            SizedBox(width: 8),
            Text(
              '2. Security Monitoring',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ultrasonic 1: Visitor
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasData && visitorDetected
                          ? AppColors.warningLight
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_pin_circle_outlined,
                      size: 20,
                      color: hasData && visitorDetected
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deteksi Tamu (Depan Pintu)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Ultrasonic 1: HC-SR04 (TRIG 21, ECHO 22)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasData
                          ? (visitorDetected
                              ? AppColors.warningLight
                              : AppColors.successLight)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visitorStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasData
                            ? (visitorDetected
                                ? AppColors.warning
                                : AppColors.success)
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jarak Deteksi Objek:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    hasData ? '${visitorDistance.toStringAsFixed(1)} cm' : '-- cm',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Ultrasonic 2: Vehicle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasData && vehiclePresent
                          ? AppColors.tealLight
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_car_outlined,
                      size: 20,
                      color: hasData && vehiclePresent
                          ? AppColors.tealDark
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring Kendaraan (Area Parkir)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Ultrasonic 2: HC-SR04 (TRIG 18, ECHO 19)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasData
                          ? (vehiclePresent
                              ? AppColors.tealLight
                              : AppColors.background)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicleStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasData
                            ? (vehiclePresent
                                ? AppColors.tealDark
                                : AppColors.textMuted)
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jarak Sensor ke Kendaraan:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    hasData ? '${vehicleDistance.toStringAsFixed(1)} cm' : '-- cm',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
