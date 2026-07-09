# UrbanCare-Community-App

## Dockerized Full Stack

This repository can run as a full Docker stack with:

- PostgreSQL database
- FastAPI backend
- Flutter web frontend served by Nginx

### Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)

### 1) Configure environment

Create a root `.env` file from `.env.docker.example` (or export these vars in your shell).

Important:

- `Backend/.env` still contains app-specific secrets (JWT, Supabase keys, etc.).
- `DATABASE_URL` in compose defaults to the local `db` container if not provided.

### 2) Build and start everything

```bash
docker compose up --build -d
```

### 3) Access services

- Frontend: http://localhost:8080
- Backend API: http://localhost:8000
- Backend docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432

### 4) View logs

```bash
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

### 5) Stop stack

```bash
docker compose down
```

To also remove the database volume:

```bash
docker compose down -v
```

## Notes

- Database initialization SQL files are mounted from `Database/` into PostgreSQL's init directory.
- Frontend API URL is injected at build time via `FRONTEND_API_BASE_URL` and passed as Dart define `API_BASE_URL`.

## One-Command Start (Docker + Android Emulator)

Use the helper script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1
```

What it does:

- Starts an Android emulator (first available AVD, or a specific one via `-AvdName`)
- Waits until boot is complete
- Starts Docker stack (`docker compose up -d --build`)

Optional flags:

```powershell
# Choose a specific emulator name
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1 -AvdName "Pixel_8_API_36"

# Also launch flutter run in a new terminal (mobile app)
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1 -RunFlutter

# Skip docker
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1 -NoDocker

# Skip emulator
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1 -NoEmulator

# Start docker without rebuilding images
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1 -NoBuild
```
