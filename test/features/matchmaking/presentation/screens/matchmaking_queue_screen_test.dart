import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/screens/matchmaking_queue_screen.dart';

// Provider override qui fixe l'état sans déclencher la vraie logique
ProviderScope _buildScreen(
  MatchmakingState state, {
  MatchRequest request = const MatchRequest(
    totalTimeMinutes: 10,
    incrementSeconds: 5,
  ),
}) {
  return ProviderScope(
    overrides: [
      matchmakingNotifierProvider.overrideWith(() => _FakeMatchmakingNotifier(state)),
    ],
    child: MaterialApp(
      home: MatchmakingQueueScreen(request: request),
    ),
  );
}

class _FakeMatchmakingNotifier extends MatchmakingNotifier {
  final MatchmakingState _initial;

  _FakeMatchmakingNotifier(this._initial);

  @override
  MatchmakingState build() => _initial;

  @override
  Future<void> connect() async {}

  @override
  Future<void> joinQueue(MatchRequest request) async {}
}

void main() {
  group('MatchmakingQueueScreen', () {
    testWidgets('affiche le titre avec le contrôle de temps', (tester) async {
      await tester.pumpWidget(_buildScreen(const MatchmakingConnecting()));
      await tester.pump();

      expect(find.text('Recherche 10+5'), findsOneWidget);
    });

    testWidgets('affiche "Illimité" quand totalTimeMinutes est null', (tester) async {
      await tester.pumpWidget(_buildScreen(
        const MatchmakingConnecting(),
        request: const MatchRequest(),
      ));
      await tester.pump();

      expect(find.text('Recherche Illimité'), findsOneWidget);
    });

    testWidgets('affiche "Illimité" quand totalTimeMinutes est 0', (tester) async {
      await tester.pumpWidget(_buildScreen(
        const MatchmakingConnecting(),
        request: const MatchRequest(totalTimeMinutes: 0),
      ));
      await tester.pump();

      expect(find.text('Recherche Illimité'), findsOneWidget);
    });

    testWidgets('affiche le spinner de connexion dans l\'état Connecting',
        (tester) async {
      await tester.pumpWidget(_buildScreen(const MatchmakingConnecting()));
      await tester.pump();

      expect(find.text('Connexion au matchmaking...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('affiche le spinner de connexion dans l\'état initial (MatchmakingIdle)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(const MatchmakingIdle()));
      await tester.pump();

      // état Idle avant joinQueue → vue de connexion par défaut
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('affiche la position en file dans l\'état InQueue',
        (tester) async {
      await tester.pumpWidget(_buildScreen(const InQueue(position: 3)));
      await tester.pump();

      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('affiche le texte "Vous êtes le prochain" quand position == 1',
        (tester) async {
      await tester.pumpWidget(_buildScreen(const InQueue(position: 1)));
      await tester.pump();

      expect(
        find.textContaining('Vous êtes le prochain'),
        findsOneWidget,
      );
    });

    testWidgets('affiche un texte générique quand position > 1',
        (tester) async {
      await tester.pumpWidget(_buildScreen(const InQueue(position: 4)));
      await tester.pump();

      expect(
        find.textContaining('prochain joueur disponible'),
        findsOneWidget,
      );
    });

    testWidgets('affiche la vue erreur dans l\'état MatchmakingError',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(const MatchmakingError('Connexion refusée')),
      );
      await tester.pump();

      expect(find.text('Erreur de connexion'), findsOneWidget);
      expect(find.text('Connexion refusée'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('le bouton Annuler est toujours affiché', (tester) async {
      await tester.pumpWidget(_buildScreen(const MatchmakingConnecting()));
      await tester.pump();

      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('le bouton retour (arrow_back) est affiché', (tester) async {
      await tester.pumpWidget(_buildScreen(const MatchmakingConnecting()));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });
}
