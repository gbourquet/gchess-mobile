# Time Control Implementation - Next Steps

## Files Modified/Created

### Domain Layer
- ✅ `lib/features/matchmaking/domain/entities/match_request.dart` - Added time control fields
- ✅ `lib/features/matchmaking/data/models/match_request_model.dart` - Updated JSON serialization
- ✅ `lib/features/game/domain/entities/chess_game.dart` - Added time fields
- ✅ `lib/features/game/data/models/chess_game_model.dart` - Updated JSON parsing
- ✅ `lib/features/game/domain/repositories/game_repository.dart` - Updated MoveExecutedEvent
- ✅ `lib/features/game/data/datasources/game_websocket_data_source.dart` - Updated WebSocket parsing

### Presentation Layer
- ✅ `lib/features/game/presentation/bloc/game_event.dart` - Added UpdateClockTimeEvent
- ✅ `lib/features/game/presentation/bloc/game_state.dart` - Added time fields to GameActive
- ✅ `lib/features/game/presentation/bloc/game_bloc.dart` - Updated to handle time events

### Lobby Feature (New)
- ✅ `lib/features/lobby/presentation/screens/lobby_screen.dart` - Main lobby with presets
- ✅ `lib/features/lobby/presentation/widgets/time_control_preset_button.dart` - Preset button widget
- ✅ `lib/features/lobby/presentation/widgets/custom_game_dialog.dart` - Custom game dialog

### Game Screen Updates
- ✅ `lib/features/game/presentation/widgets/game_clock.dart` - Clock widget with warnings
- ✅ `lib/features/game/presentation/screens/game_screen.dart` - Integrated clocks and timer

### Matchmaking Updates
- ✅ `lib/features/matchmaking/presentation/screens/matchmaking_queue_screen.dart` - Updated to show time control

### Routes
- ✅ `lib/config/routes.dart` - Added lobby route, updated matchmaking route

## Required Actions

### 1. Run Build Runner
You MUST run this to regenerate JSON serialization code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or if you have dart in your path:
```bash
dart run build_runner build --delete-conflicting-outputs
```

This will regenerate:
- `lib/features/matchmaking/data/models/match_request_model.g.dart`

### 2. Verify Backend Compatibility
Ensure your backend (gChess) is running with the updated asyncapi.yaml v2.1.0 that includes:
- `totalTimeMinutes` and `incrementSeconds` in JoinQueue message
- `totalTimeSeconds`, `incrementSeconds`, `whiteTimeRemainingMs`, `blackTimeRemainingMs` in GameStateSync
- `whiteTimeRemainingMs`, `blackTimeRemainingMs` in MoveExecuted message

### 3. Test the Implementation

#### Lobby Screen
1. Navigate to `/lobby` (automatic after login)
2. Test each preset button:
   - Bullet: 1+0, 2+0, 2+1
   - Blitz: 3+0, 3+2, 5+0, 5+3
   - Rapid: 10+0, 10+5, 15+10
   - Classical: 30+0, 30+20
3. Test Custom Game dialog:
   - Try different time values (min 1)
   - Try different increment values (min 0)
   - Verify validation works

#### Matchmaking Queue
1. Join matchmaking with a time control
2. Verify title shows the time control (e.g., "Finding Opponent (5+3)")
3. Wait for a match or cancel

#### Game Screen
1. Join a game with time control
2. Verify both clocks display correctly
3. Verify current player's clock is highlighted
4. Verify time decrements locally every second
5. Verify time syncs after each move (from WebSocket)
6. Test warning colors:
   - Orange when < 60s
   - Red when < 10s
   - Pulse animation when < 5s
7. Test review mode - timer should pause when reviewing history

#### Edge Cases
1. Game ends by timeout - verify TIMEOUT status is handled
2. Resume game - verify clocks display correctly
3. Very short games (1+0) - verify clocks update smoothly

## Features Implemented

### Time Control Presets
- Bullet: 1+0, 2+0, 2+1
- Blitz: 3+0, 3+2, 5+0, 5+3
- Rapid: 10+0, 10+5, 15+10
- Classical: 30+0, 30+20

### Custom Games
- User can specify any time (minutes, min 1)
- User can specify any increment (seconds, min 0)
- Form validation ensures valid inputs

### Clock Display
- Format: `MM:SS` for > 60s, `SS.s` for < 60s
- Warning colors: Orange (< 60s), Red (< 10s)
- Pulse animation when time < 5s
- Highlight current player's clock
- Stop counting when in review mode

### Timer Management
- Local 1Hz decrement for smooth updates
- Synchronization with WebSocket MoveExecuted events
- Timer stops when game ends or reviewing history
- Zero time handling (no negative values)

## Notes

- Timer uses `Timer.periodic` with 1-second intervals
- Clock updates are purely local and synchronized on moves
- Review mode pauses the clock
- No unlimited games (minimum 1 minute required)
- All games are human vs human only

## Troubleshooting

### Build Runner Issues
If `flutter pub run build_runner` fails:
1. Ensure all dependencies are installed: `flutter pub get`
2. Try cleaning: `flutter clean && flutter pub get`
3. Check for conflicts in existing `.g.dart` files

### Clock Not Updating
1. Verify WebSocket receives time fields in MoveExecuted message
2. Check browser console/network tab for WebSocket messages
3. Ensure game has time control (not unlimited)

### Timer Running When Not Turn
This is expected behavior - timer always decrements the current player's clock.
