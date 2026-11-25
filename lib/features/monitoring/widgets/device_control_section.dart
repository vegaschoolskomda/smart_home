import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/esp32_data_model.dart';

class DeviceControlSection extends StatelessWidget {
  final Esp32DataModel? data;
  final bool isOnline;

  const DeviceControlSection({
    super.key,
    required this.data,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasData = isOnline && data != null;

    final int servoAngle = hasData ? data!.servoAngle : 0;
    final bool ledStatus = hasData && data!.ledStatus;
    final bool buzzerStatus = hasData && data!.buzzerStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.precision_manufacturing_outlined, size: 18, color: AppColors.tealPrimary),
            SizedBox(width: 8),
            Text(
              '3. Automatic Device Control',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Seluruh logika otomatisasi diproses oleh mikrokontroler ESP32.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        // Servo Card
        _buildDeviceCard(
          title: 'Motor Servo Kanopi',
          gpio: 'GPIO13 (PWM)',
          logicDesc: 'Otomatis 90° saat hujan, 0° saat kering',
          currentValue: hasData ? '$servoAngle°' : '--',
          status: hasData
              ? (servoAngle == 90 ? 'Posisi 90° (Tertutup)' : 'Posisi 0° (Terbuka)')
              : 'Tidak Tersedia',
          isActive: hasData && servoAngle == 90,
          icon: Icons.roofing_rounded,
        ),
        const SizedBox(height: 10),
        // LED Card
        _buildDeviceCard(
          title: 'Lampu Penerangan (LED)',
          gpio: 'GPIO25',
          logicDesc: 'Otomatis menyala saat kondisi gelap (LDR)',
          currentValue: hasData ? (ledStatus ? 'ON' : 'OFF') : '--',
          status: hasData
              ? (ledStatus ? 'Aktif (Menyala)' : 'Tidak Aktif (Mati)')
              : 'Tidak Tersedia',
          isActive: ledStatus,
          icon: Icons.lightbulb_outline_rounded,
        ),
        const SizedBox(height: 10),
        // Buzzer Card
        _buildDeviceCard(
          title: 'Buzzer Alarm Peringatan',
          gpio: 'GPIO27',
          logicDesc: 'Otomatis berbunyi jika suhu tinggi atau gas bahaya',
          currentValue: hasData ? (buzzerStatus ? 'ON' : 'OFF') : '--',
          status: hasData
              ? (buzzerStatus ? 'Aktif (Berbunyi)' : 'Tidak Aktif (Normal)')
              : 'Tidak Tersedia',
          isActive: buzzerStatus,
          isAlert: true,
          icon: Icons.volume_up_outlined,
        ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required String gpio,
    required String logicDesc,
    required String currentValue,
    required String status,
    required bool isActive,
    bool isAlert = false,
    required IconData icon,
  }) {
    Color badgeColor;
    Color badgeBg;

    if (!isOnline || data == null) {
      badgeColor = AppColors.textMuted;
      badgeBg = AppColors.background;
    } else if (isActive) {
      badgeColor = isAlert ? AppColors.danger : AppColors.tealDark;
      badgeBg = isAlert ? AppColors.dangerLight : AppColors.tealLight;
    } else {
      badgeColor = AppColors.textMuted;
      badgeBg = AppColors.background;
    }

    return Container(
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      gpio,
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
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    logicDesc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
