import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/services/esp32_service.dart';
import 'data/services/notification_service.dart';
import 'navigation/bottom_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar and system navigation bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SQLite database
  await AppDatabase.instance.database;

  // Initialize notification service
  await NotificationService.instance.init();

  // Initialize ESP32 service and load last saved IP
  await Esp32Service.instance.init();

  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainBottomNavigation(),
    );
  }
}
