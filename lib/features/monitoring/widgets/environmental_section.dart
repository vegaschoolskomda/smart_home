import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/sensor_evaluator.dart';
import '../../../data/models/esp32_data_model.dart';
import 'sensor_value_card.dart';

class EnvironmentalSection extends StatelessWidget {
  final Esp32DataModel? data;
  final bool isOnline;

  const EnvironmentalSection({
    super.key,
    required this.data,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasData = isOnline && data != null;

    final double temp = hasData ? data!.temperature : 0.0;
    final bool tempHigh = hasData && SensorEvaluator.isTemperatureHigh(temp);
    final String tempStatus = hasData
        ? SensorEvaluator.getTemperatureStatus(temp)
        : 'Tidak Tersedia';

    final double humidity = hasData ? data!.humidity : 0.0;
    final String humidityStatus = hasData
        ? (humidity > 80 ? 'Lembap' : (humidity < 40 ? 'Kering' : 'Normal'))
        : 'Tidak Tersedia';

    final int gas = hasData ? data!.gasValue : 0;
    final bool gasHigh = hasData && SensorEvaluator.isGasHigh(gas);
    final String gasStatus = hasData
        ? SensorEvaluator.getGasStatus(gas)
        : 'Tidak Tersedia';

    final int ldr = hasData ? data!.ldrValue : 0;
    final bool lightBright = hasData && SensorEvaluator.isLightBright(ldr);
    final String lightStatus = hasData
        ? SensorEvaluator.getLightStatus(ldr)
        : 'Tidak Tersedia';

    final bool rain = hasData && data!.rainStatus;
    final String rainStatus = hasData
        ? SensorEvaluator.getRainStatus(rain)
        : 'Tidak Tersedia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.eco_outlined, size: 18, color: AppColors.tealPrimary),
            SizedBox(width: 8),
            Text(
              '1. Environmental Monitoring',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SensorValueCard(
                title: 'Suhu Lingkungan',
                sensorName: 'DHT11 (GPIO4)',
                value: hasData ? temp.toStringAsFixed(1) : '--',
                unit: '°C',
                status: tempStatus,
                statusColor: hasData
                    ? (tempHigh ? AppColors.danger : AppColors.success)
                    : AppColors.textMuted,
                statusBg: hasData
                    ? (tempHigh ? AppColors.dangerLight : AppColors.successLight)
                    : AppColors.background,
                icon: Icons.thermostat_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SensorValueCard(
                title: 'Kelembapan Udara',
                sensorName: 'DHT11 (GPIO4)',
                value: hasData ? humidity.toStringAsFixed(0) : '--',
                unit: '%',
                status: humidityStatus,
                statusColor: hasData ? AppColors.tealDark : AppColors.textMuted,
                statusBg: hasData ? AppColors.tealLight : AppColors.background,
                icon: Icons.water_drop_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SensorValueCard(
                title: 'Kadar Gas / Asap',
                sensorName: 'MQ-2 (GPIO32)',
                value: hasData ? gas.toString() : '--',
                unit: 'ADC',
                status: gasStatus,
                statusColor: hasData
                    ? (gasHigh ? AppColors.danger : AppColors.success)
                    : AppColors.textMuted,
                statusBg: hasData
                    ? (gasHigh ? AppColors.dangerLight : AppColors.successLight)
                    : AppColors.background,
                icon: Icons.local_fire_department_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SensorValueCard(
                title: 'Intensitas Cahaya',
                sensorName: 'LDR (GPIO35)',
                value: hasData ? ldr.toString() : '--',
                unit: 'ADC',
                status: lightStatus,
                statusColor: hasData
                    ? (lightBright ? AppColors.warning : AppColors.tealDark)
                    : AppColors.textMuted,
                statusBg: hasData
                    ? (lightBright ? AppColors.warningLight : AppColors.tealLight)
                    : AppColors.background,
                icon: Icons.wb_sunny_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Rain Sensor full width
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasData && rain ? AppColors.tealLight : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.thunderstorm_outlined,
                  size: 20,
                  color: hasData && rain ? AppColors.tealDark : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensor Air Hujan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Rain Sensor Module (GPIO34)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasData
                      ? (rain ? AppColors.tealLight : AppColors.successLight)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  rainStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasData
                        ? (rain ? AppColors.tealDark : AppColors.success)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
