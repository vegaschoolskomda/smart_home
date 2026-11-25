import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/services/esp32_service.dart';
import '../widgets/device_control_section.dart';
import '../widgets/environmental_section.dart';
import '../widgets/notification_history_section.dart';
import '../widgets/security_section.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Esp32Service.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final isOnline = service.isOnline;
        final data = service.lastData;
        final lastUpdated = service.lastUpdated;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitoring IoT'),
            actions: [
              // Online / Offline Status Badge
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.successLight : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isOnline ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 13,
                      color: isOnline ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Perbarui Data',
                onPressed: () => service.refresh(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await service.refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Last updated status bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.tealLight.withValues(alpha: 0.6)
                          : AppColors.dangerLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.access_time_rounded : Icons.info_outline_rounded,
                          size: 15,
                          color: isOnline ? AppColors.tealDark : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastUpdated != null
                                ? (isOnline
                                    ? 'Data sinkron: ${DateFormatter.formatTime(lastUpdated)}'
                                    : 'Terakhir terhubung: ${DateFormatter.formatDateTime(lastUpdated)} (Offline)')
                                : 'ESP32 belum terhubung. Silakan hubungkan dari Beranda.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOnline ? AppColors.tealDark : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Section 1: Environmental Monitoring
                  EnvironmentalSection(
                    data: data,
                    isOnline: isOnline,
                  ),
                  const SizedBox(height: 22),
                  // Section 2: Security Monitoring
                  SecuritySection(
                    data: data,
                    isOnline: isOnline,
                  ),
                  const SizedBox(height: 22),
                  // Section 3: Automatic Device Control
                  DeviceControlSection(
                    data: data,
                    isOnline: isOnline,
                  ),
                  const SizedBox(height: 22),
                  // Section 4: Notification History
                  const NotificationHistorySection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
