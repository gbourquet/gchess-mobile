# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains API specifications for **gChess**, a chess application with a Kotlin backend following Domain-Driven Design (DDD) principles. The repository includes:

- **openapi.json**: REST API specification
- **asyncapi.yaml**: WebSocket API specification

## API Architecture

### REST API (openapi.json)

The REST API provides synchronous endpoints for:

- **Authentication**: User registration (`/api/auth/register`) and login (`/api/auth/login`) with JWT token generation
- **Bot Management**: List all bots (`/api/bots`) and retrieve bot details (`/api/bots/{id}`)

All authenticated endpoints require a JWT token in the `Authorization` header as `Bearer <token>`.

### WebSocket API (asyncapi.yaml)

The WebSocket API provides real-time communication across three channels:

#### 1. Matchmaking Channel (`/ws/matchmaking`)
- **Unified matchmaking** for both human vs human and human vs bot games
- **Human vs Human**: FIFO queue system with position updates
- **Human vs Bot**: Instant matching with optional bot selection and color preference
- **Connection scope**: One connection per UserId
- **Key messages**: `JoinQueue`, `QueuePositionUpdate`, `MatchFound`

#### 2. Game Channel (`/ws/game/{gameId}`)
- Real-time gameplay with move execution and validation
- **Bot integration**: Bots automatically calculate and execute moves after human moves
- **Connection scope**: One connection per PlayerId (game participation)
- **Key messages**: `MoveAttempt`, `MoveExecuted`, `MoveRejected`, `GameStateSync`
- Players can identify bot opponents by username prefix "bot_"

#### 3. Spectate Channel (`/ws/game/{gameId}/spectate`)
- Read-only observation of ongoing games
- **Connection scope**: One connection per UserId (observer)
- Receives all game events but cannot send moves

### Authentication Flow

WebSocket connections require JWT authentication via:
1. Query parameter: `?token=YOUR_JWT_TOKEN`
2. Sec-WebSocket-Protocol header: `Bearer YOUR_JWT_TOKEN`

All connections receive `AuthSuccess` or `AuthFailed` messages upon connection.

### Domain-Driven Design Context

The architecture uses bounded contexts:
- **Matchmaking**: Indexed by UserId (permanent user identity)
- **Gameplay**: Indexed by PlayerId (per-game participation)
- **Spectators**: Indexed by UserId (observers)
- **Shared Kernel**: WebSocketJwtAuth (authentication across all contexts)

### Bot System

Bots are integrated into the unified matchmaking flow:
- Bot games use the same WebSocket endpoints as human games
- Bot moves are triggered automatically via `ExecuteBotMoveUseCase`
- Bots can be selected randomly or by specific botId
- Player color can be specified or randomly assigned

### Identifiers

The system uses ULID format for all identifiers:
- UserId: Permanent user identity
- PlayerId: Per-game participation identity
- GameId: Unique game identifier
- BotId: Bot opponent identifier

## Editing API Specifications

When modifying the API specs:
- **openapi.json**: Use JSON format, ensure all schemas are properly referenced under `#/components/schemas`
- **asyncapi.yaml**: Use AsyncAPI 3.0.0 format, ensure all messages are properly referenced under `#/components/messages`
- Maintain consistency between REST and WebSocket authentication mechanisms
- Ensure bot-related features use the unified matchmaking approach
- Keep ULID format for all identifiers
