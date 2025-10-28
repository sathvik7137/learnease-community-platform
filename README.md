# learnease

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Postgres-backed storage

This project now uses a Postgres-backed server for all persistent data. A simple Dart `shelf` server is included in the `server/` folder.

Quick steps to run locally:

1. Install Postgres (or use Docker). Example Docker command:

```powershell
docker run --name learnease-postgres -e POSTGRES_USER=learnease -e POSTGRES_PASSWORD=password -e POSTGRES_DB=learnease -p 5432:5432 -d postgres:15
```

2. Apply migrations:

```powershell
# using psql (replace values if not using Docker defaults)
psql "postgres://learnease:password@localhost:5432/learnease" -f server/migrations/create_tables.sql
```

3. Run server:

```powershell
cd server
dart pub get
dart run bin/server.dart
```

4. Run the app and, if you have existing local data, run the migration once from app code by calling `Migrator.migrate()` (a helper exists at `lib/services/migrator.dart`).

Notes:
- The server listens on port 8080 by default. Set `PORT` or `POSTGRES_URL` via environment or `.env` file in `server/` folder.
- The app uses a device-generated id (stored in `SharedPreferences`) as `userId` when calling the server. This keeps behavior compatible without a user auth system.
