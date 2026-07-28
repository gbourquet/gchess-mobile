enum Environment {
  development,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://10.0.2.2:8080';
      case Environment.production:
        return 'https://gchess.sur-le-web.fr';
    }
  }

  static String get websocketUrl {
    switch (_environment) {
      case Environment.development:
        return 'ws://10.0.2.2:8080';
      case Environment.production:
        return 'wss://gchess.sur-le-web.fr';
    }
  }

  static bool get isProduction => _environment == Environment.production;
  static bool get isDevelopment => _environment == Environment.development;
}
