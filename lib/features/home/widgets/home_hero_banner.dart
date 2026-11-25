import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/esp32_service.dart';
import 'smart_home_hero_graphic.dart';

class HomeHeroBanner extends StatelessWidget {
  final Esp32Service service;

  const HomeHeroBanner({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    String badgeText;
    IconData badgeIcon;
    Color badgeColor;

    if (service.isSimulationMode) {
      badgeText = 'Mode Demo';
      badgeIcon = Icons.visibility_outlined;
      badgeColor = const Color(0xFF38D3D3);
    } else if (service.isOnline) {
      badgeText = 'ESP32: Online';
      badgeIcon = Icons.wifi_rounded;
      badgeColor = AppColors.success;
    } else if (service.isConnecting) {
      badgeText = 'Menghubungkan...';
      badgeIcon = Icons.sync_rounded;
      badgeColor = AppColors.warning;
    } else {
      badgeText = 'ESP32: Offline';
      badgeIcon = Icons.wifi_off_rounded;
      badgeColor = AppColors.heroSubtitle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.heroNavy,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF13253A),
            Color(0xFF1B3654),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroNavy.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Graphic placed in bottom-right corner
          const Positioned(
            right: -6,
            bottom: -6,
            child: SmartHomeHeroGraphic(
              width: 140,
              height: 125,
            ),
          ),
          // Content on the left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      size: 13,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Big Catchy Headline
              const Text(
                'Smart Living,\nSmarter\nMonitoring.',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.52,
                child: const Text(
                  'Rumah lebih nyaman dengan pemantauan yang selalu dekat.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.heroSubtitle,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
