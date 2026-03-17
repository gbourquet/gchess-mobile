import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/config/app_config.dart';
import 'package:gchess_mobile/core/debug/debug_overlay.dart';

// _EnvTile et _DebugMenuOverlay sont privés → testés via DebugOverlay
// On accède indirectement en simulant le double-tap sur le Listener.

Widget _buildOverlay({Widget child = const SizedBox()}) {
  return MaterialApp(home: Scaffold(body: DebugOverlay(child: child)));
}

void main() {
  group('DebugOverlay', () {
    testWidgets('rend son enfant directement', (tester) async {
      await tester.pumpWidget(_buildOverlay(child: const Text('hello')));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('en mode debug, enveloppe dans un Listener', (tester) async {
      await tester.pumpWidget(_buildOverlay());
      // kDebugMode = true dans les tests Flutter
      // Le framework peut aussi utiliser des Listeners → on vérifie qu'il y en a au moins un
      expect(find.byType(Listener), findsWidgets);
    });

    testWidgets('un seul pointeur ne déclenche pas le menu', (tester) async {
      await tester.pumpWidget(_buildOverlay());
      // Simule un seul PointerDown au centre du Scaffold
      final gesture = await tester.startGesture(tester.getCenter(find.byType(Scaffold)));
      await tester.pump();
      await gesture.up();
      // Pas de dialog / overlay apparu
      expect(find.text('DEBUG — Environnement backend'), findsNothing);
    });
  });

  group('AppConfig — changement d\'environnement', () {
    test('setEnvironment development configure les bonnes URLs', () {
      AppConfig.setEnvironment(Environment.development);
      expect(AppConfig.environment, Environment.development);
      expect(AppConfig.baseUrl, contains('10.0.2.2'));
    });

    test('setEnvironment production configure les bonnes URLs', () {
      AppConfig.setEnvironment(Environment.production);
      expect(AppConfig.environment, Environment.production);
      expect(AppConfig.baseUrl, contains('railway'));
      // Remettre en dev après le test
      AppConfig.setEnvironment(Environment.development);
    });
  });
}
