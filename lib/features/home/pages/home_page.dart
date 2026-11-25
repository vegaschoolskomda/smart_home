import 'package:flutter/material.dart';
import '../../../data/services/esp32_service.dart';
import '../widgets/connection_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_status.dart';
import '../widgets/home_summary_card.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToMonitoring;

  const HomePage({
    super.key,
    required this.onNavigateToMonitoring,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showConnectionCard = false;

  void _toggleConnectionCard() {
    setState(() {
      _showConnectionCard = !_showConnectionCard;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Esp32Service.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await service.refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top greeting & icon
                    HomeHeader(
                      service: service,
                      onSettingsTap: _toggleConnectionCard,
                    ),
                    const SizedBox(height: 16),
                    // Hero Banner Card
                    HomeHeroBanner(service: service),
                    const SizedBox(height: 16),
                    // Connection Card (always available or togglable)
                    ConnectionCard(service: service),
                    const SizedBox(height: 20),
                    // Bento Asymmetric Sensor Grid
                    HomeSummaryCard(
                      data: service.lastData,
                      isOnline: service.isOnline,
                      lastUpdated: service.lastUpdated,
                    ),
                    const SizedBox(height: 20),
                    // Quick Devices Status
                    HomeQuickStatus(
                      data: service.lastData,
                      isOnline: service.isOnline,
                      onNavigateToMonitoring: widget.onNavigateToMonitoring,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
