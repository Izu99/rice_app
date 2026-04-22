# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Rice Mill ERP** — a mobile + backend system for managing a Sri Lankan rice mill business. Two codebases in one repo:

- `client/` — Flutter mobile app (Material 3, BLoC/Cubit state management, Clean Architecture)
- `server/` — Node.js/Express REST API with MongoDB via Mongoose

## Commands

### Server (run from `server/`)
```bash
npm run dev    # nodemon hot reload
npm start      # production
```
Requires a `.env` file — copy from `.env.example`. Key vars: `MONGODB_URI`, `JWT_SECRET`, `BACKEND_PORT`.

### Client (run from `client/`)
```bash
flutter run                                      # default device (uses localhost:5000)
flutter run --dart-define=API_URL=http://...     # explicit API URL override
flutter analyze
flutter test
```

## Architecture

### API URL resolution (client)
`client/lib/core/constants/api_endpoints.dart` defines `baseUrl = devBaseUrl`.

- `devBaseUrl` → `http://localhost:5000/api` (local dev)
- Android emulator → use `http://10.0.2.2:5000/api`
- Production VPS → update `baseUrl` to point at the live server

### Client — Clean Architecture layers

```
features/<name>/
  presentation/   — screens + CUBITs
  data/           — datasources, models, repository implementations
  domain/         — entities, repository interfaces, use cases
  *_injection.dart — GetIt registrations for this feature
```

State: `flutter_bloc` CUBITs. DI: `get_it` service locator. Routing: `go_router` with `AuthGuard`.

`client/lib/injection_container.dart` bootstraps all DI in order: external deps → core services → datasources → repositories → use cases → features → router.

Each feature has its own `*_injection.dart` that checks `sl.isRegistered` before registering (safe to call multiple times).

### Client routing (`client/lib/routes/app_router.dart`)

Tabbed shell: Home, Stock, Reports, Expenses, Profile.
Full-screen routes outside shell: Buy, Sell, Customers, Admin, Price Management, Store.

### Server structure

```
src/
  server.js        — startup, DB connect, error handling
  app.js           — Express setup, middleware, route mounting
  controllers/     — business logic
  models/          — Mongoose schemas
  routes/          — thin routers
  middleware/      — auth, roles, validation, rate limiting
  validators/      — express-validator rules
  config/          — DB connection, environment, CORS
```

### Core data models

- **User** — roles: `admin`, `company`, `manager`, `operator`, `viewer`, `customer`; multi-tenant via `companyId`
- **Company** — subscription plans (free/basic/premium/enterprise); per-company settings (milling %, stock threshold, currency)
- **Customer** — type `buyer`/`seller`/`both`; tracks buy/sell balances
- **Transaction** — type `buy`/`sell`; items array; payment history; status `pending|partially_paid|completed|cancelled`; `clientId` + `isSynced` for offline-first
- **StockItem** — type `paddy`/`rice`; tracks weight (kg) and bags; virtual `totalValue` and `isLowStock`
- **MillingRecord** — batch milling: input paddy → output rice with yield %; linked to stock adjustments
- **PaddyRicePrice** — district-wise market prices by quality grade
- **StoreListing** — marketplace buy/sell listings by category

### Offline-first sync

All data models carry `clientId` (UUID generated on device) and `isSynced` flag. Sync endpoints: `POST /api/sync/push`, `GET /api/sync/pull`, `POST /api/sync/resolve`. Server deduplicates by `clientId`.

### Auth / security

JWT bearer token. Two auth middlewares: `auth.js` (older, most routes) and `authMiddleware.js` (newer, exports `authorizeRole()`). Both set `req.user`. Helmet + HPP + mongo-sanitize + rate limiting (100 req/15min general, 10/hr on `/api/auth/login`).

### Multi-tenancy

Every query is scoped by `companyId` from `req.user`. Super-admin (`/api/admin/*`) can access all companies.

## Key gotchas

- `baseUrl` in `api_endpoints.dart` is a compile-time constant — change it there, not at runtime.
- Android emulator cannot reach `localhost` — use `10.0.2.2` for local server.
- `clientId` must be generated on the client (UUID v4) before posting any transaction or stock record — the server uses it for deduplication.
- Shared widgets live in `client/lib/core/shared_widgets/` — reuse before creating new widget classes.
- There are two `api_service.dart` files; always use `client/lib/core/network/api_service.dart`.
