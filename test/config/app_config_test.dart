import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/config/app_config.dart';

void main() {
  group('AppConfig', () {
    tearDown(() {
      // Reset to development after each test
      AppConfig.setEnvironment(Environment.development);
    });

    test('default environment is development', () {
      AppConfig.setEnvironment(Environment.development);
      expect(AppConfig.environment, Environment.development);
      expect(AppConfig.isDevelopment, isTrue);
      expect(AppConfig.isProduction, isFalse);
    });

    test('development baseUrl and websocketUrl', () {
      AppConfig.setEnvironment(Environment.development);
      expect(AppConfig.baseUrl, contains('10.0.2.2'));
      expect(AppConfig.websocketUrl, contains('ws://'));
    });

    test('production environment', () {
      AppConfig.setEnvironment(Environment.production);
      expect(AppConfig.environment, Environment.production);
      expect(AppConfig.isProduction, isTrue);
      expect(AppConfig.isDevelopment, isFalse);
    });

    test('production baseUrl and websocketUrl', () {
      AppConfig.setEnvironment(Environment.production);
      expect(AppConfig.baseUrl, contains('https://'));
      expect(AppConfig.websocketUrl, contains('wss://'));
    });
  });
}
