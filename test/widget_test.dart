import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/core/utils/sensor_evaluator.dart';
import 'package:smart_home_app/data/models/esp32_data_model.dart';
import 'package:smart_home_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unit Tests: SensorEvaluator & Models', () {
    test('SensorEvaluator detects high temperature correctly', () {
      expect(SensorEvaluator.isTemperatureHigh(32.0), false);
      expect(SensorEvaluator.isTemperatureHigh(33.0), true);
      expect(SensorEvaluator.isTemperatureHigh(36.5), true);
      expect(SensorEvaluator.getTemperatureStatus(34.0), 'Tinggi');
      expect(SensorEvaluator.getTemperatureStatus(26.0), 'Normal');
    });

    test('SensorEvaluator detects gas hazard correctly', () {
      expect(SensorEvaluator.isGasHigh(800), false);
      expect(SensorEvaluator.isGasHigh(1400), true);
      expect(SensorEvaluator.isGasHigh(2000), true);
      expect(SensorEvaluator.getGasStatus(1500), 'Bahaya / Asap Terdeteksi');
      expect(SensorEvaluator.getGasStatus(600), 'Aman');
    });

    test('SensorEvaluator light & rain helpers work correctly', () {
      expect(SensorEvaluator.isLightBright(1000), true);
      expect(SensorEvaluator.isLightBright(2500), false);
      expect(SensorEvaluator.getRainStatus(true), 'Hujan');
      expect(SensorEvaluator.getRainStatus(false), 'Tidak Hujan');
    });

    test('Esp32DataModel parses JSON accurately and gracefully', () {
      final json = {
        'temperature': '29.5',
        'humidity': 70,
        'gas_value': '1200',
        'ldr_value': 2500,
        'rain_status': true,
        'visitor_detected': 'true',
        'visitor_distance': 45.2,
        'vehicle_status': 'Ada',
        'vehicle_distance': 80,
        'servo_angle': 90,
        'led_status': 1,
        'buzzer_status': 0,
      };

      final model = Esp32DataModel.fromJson(json);
      expect(model.temperature, 29.5);
      expect(model.humidity, 70.0);
      expect(model.gasValue, 1200);
      expect(model.ldrValue, 2500);
      expect(model.rainStatus, true);
      expect(model.visitorDetected, true);
      expect(model.visitorDistance, 45.2);
      expect(model.vehicleStatus, 'Ada');
      expect(model.vehicleDistance, 80.0);
      expect(model.servoAngle, 90);
      expect(model.ledStatus, true);
      expect(model.buzzerStatus, false);
    });
  });

  group('Widget Tests: Redesigned UI & Zero Emojis', () {
    testWidgets('App renders Beranda with new greeting, hero banner, bento grid, and tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(const SmartHomeApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Header and greeting
      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(find.text('Penghuni Rumah'), findsOneWidget);

      // Hero banner
      expect(find.text('Smart Living,\nSmarter\nMonitoring.'), findsOneWidget);

      // Bento cards section
      expect(find.text('KONDISI RUMAH'), findsOneWidget);
      expect(find.text('Ringkasan hari ini'), findsOneWidget);
      expect(find.text('DHT11'), findsOneWidget);
      expect(find.text('Gas / asap'), findsOneWidget);
      expect(find.text('Cahaya'), findsOneWidget);
      expect(find.text('LDR'), findsOneWidget);

      // Tabs
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Monitoring'), findsOneWidget);

      // Tap Monitoring tab
      await tester.tap(find.text('Monitoring'));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Monitoring page sections
      expect(find.text('Monitoring IoT'), findsOneWidget);
      expect(find.text('1. Environmental Monitoring'), findsOneWidget);
      expect(find.text('2. Security Monitoring'), findsOneWidget);
      expect(find.text('3. Automatic Device Control'), findsOneWidget);
      expect(find.text('4. Notification History'), findsOneWidget);
    });
  });
}
