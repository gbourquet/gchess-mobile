# gChess phone

Mobile client of gChess: the same journey as the web client (choose a Time control, wait for an opponent, play, look back at past Games) on a phone. It does not offer spectating yet.

Domain terms (User, Player, Side, Game, Move, Square, Position, Outcome, Draw offer, Time control, Clock, Timeout, Queue, Match…) are defined in [gChess-back/CONTEXT.md](../gChess-back/CONTEXT.md). Client terms (Lobby, Preset, Speed, Custom time control, Check, Premove, Captured pieces, Connection state, History, Result, Game review) are defined in [gChess-front/CONTEXT.md](../gChess-front/CONTEXT.md). Both mean the same thing here.

## Language

**Game record**:
A finished Game as the History keeps it for one User: players, Outcome, Result, Time control, and every Move with the Position after it, ready for Game review.
_Avoid_: Game summary, archive entry
