import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/sensor_evaluator.dart';
import '../../../data/models/esp32_data_model.dart';

class HomeQuickStatus extends StatelessWidget {
  final Esp32DataModel? data;
  final bool isOnline;
  final VoidCallback onNavigateToMonitoring;

  const HomeQuickStatus({
    super.key,
    required this.data,
    required this.isOnline,
    required this.onNavigateToMonitoring,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS PERANGKAT OTOMATIS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.tealPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ringkasan Aktuator & Sensor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          _buildDeviceRow(
            icon: Icons.lightbulb_outline_rounded,
            name: 'Lampu LED',
            desc: 'Otomatis aktif saat gelap',
            status: isOnline && data != null
                ? (data!.ledStatus ? 'Aktif' : 'Mati')
                : 'Offline',
            isActive: isOnline && data != null && data!.ledStatus,
          ),
          const Divider(height: 20),
          _buildDeviceRow(
            icon: Icons.volume_up_outlined,
            name: 'Buzzer Alarm',
            desc: 'Aktif saat suhu/gas tinggi',
            status: isOnline && data != null
                ? (data!.buzzerStatus ? 'Bunyi' : 'Normal')
                : 'Offline',
            isActive: isOnline && data != null && data!.buzzerStatus,
            isAlarm: true,
          ),
          const Divider(height: 20),
          _buildDeviceRow(
            icon: Icons.roofing_rounded,
            name: 'Servo Kanopi',
            desc: '0° Terbuka, 90° Tertutup',
            status: isOnline && data != null
                ? '${data!.servoAngle}°'
                : 'Offline',
            isActive: isOnline && data != null && data!.servoAngle == 90,
          ),
          const Divider(height: 20),
          _buildDeviceRow(
            icon: Icons.thunderstorm_outlined,
            name: 'Sensor Hujan',
            desc: 'Deteksi tetesan air hujan',
            status: isOnline && data != null
                ? SensorEvaluator.getRainStatus(data!.rainStatus)
                : 'Offline',
            isActive: isOnline && data != null && data!.rainStatus,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNavigateToMonitoring,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Buka Halaman Monitoring Lengkap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tealDark,
                side: const BorderSide(color: AppColors.tealPrimary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow({
    required IconData icon,
    required String name,
    required String desc,
    required String status,
    required bool isActive,
    bool isAlarm = false,
  }) {
    Color badgeColor;
    Color badgeBg;

    if (!isOnline || data == null) {
      badgeColor = AppColors.textMuted;
      badgeBg = AppColors.background;
    } else if (isActive) {
      badgeColor = isAlarm ? AppColors.danger : AppColors.tealDark;
      badgeBg = isAlarm ? AppColors.dangerLight : AppColors.tealLight;
    } else {
      badgeColor = AppColors.textMuted;
      badgeBg = AppColors.background;
    }

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: badgeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: const TextStyle(
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
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}
