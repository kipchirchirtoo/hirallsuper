# Giftmart Supermarket POS Platform

An enterprise-grade, high-performance retail Point of Sale and management platform tailored specifically for **Giftmart Supermarket Ltd**. Powered by a native **Rust (Axum + SQLx)** cloud backend engine, an offline-first Flutter desktop POS client, and a web admin console.

---

## Architecture Overview

```
                         ┌─────────────────────────────┐
                         │    hirall-backend           │
                         │    (Rust + Axum + Tokio)    │
                         │    - Port: 8080             │
                         │    - High-Throughput POS    │
                         │    - Kenyan KRA eTIMS VSCU  │
                         │    - M-Pesa Daraja 3.0      │
                         │    - Native Push/Pull Sync  │
                         └──────────────┬──────────────┘
                                        │
                                        ▼
                         ┌─────────────────────────────┐
                         │   PostgreSQL ("giftmart")   │  ← Single source of truth
                         │   - Org: Giftmart Supermarket│
                         │   - Branches: Main, Express,│
                         │     Central Warehouse Hub   │
                         └──────────────┬──────────────┘
                                        │ Native Delta Push/Pull
                                        │ (/api/v1/sync/push & /pull)
                                        ▼
               ┌────────────────────────┼────────────────────────┐
               ▼                        ▼                        ▼
    ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
    │ Flutter Desktop │      │ Flutter Desktop │      │ Web Admin       │
    │ Main Store POS  │      │ Express Outlet  │      │ Management      │
    │ Local Drift DB  │      │ Local Drift DB  │      │ Console (:8080) │
    └─────────────────┘      └─────────────────┘      └─────────────────┘
```

- **Frontend Client (Flutter Desktop):** High-speed barcode scanning, itemized cart, thermal 80mm receipt generation, cash & M-Pesa tender, and local SQLite/Drift database.
- **Central Database (PostgreSQL - `giftmart`):** Single-organization master database for Giftmart Supermarket Ltd with multi-branch partitioning.
- **Backend API (`hirall-backend`):** High-performance Rust Axum service with Tokio runtime, SQLx connection pool, Redis cache, Kenyan fiscal compliance (eTIMS), and native synchronization.
- **Offline Sync:** Zero-dependency native sync engine (`/api/v1/sync/push` & `/api/v1/sync/pull`) with monotonic watermark cursors and branch-scoped event replay.
- **Clean Codebase:** Legacy FastAPI backend, legacy database scripts, and PowerSync configuration have been moved to `C:\Users\user\OneDrive\Desktop\ARCHIVE`.

---

## Directory Structure

```
supermarket/
├── hirall-backend/            # Ultimate Backend: Rust (Axum + SQLx + Redis)
│   ├── src/
│   │   ├── app/               # Config, router, state
│   │   ├── core/              # Auth (JWT/Argon2), database pool, storage
│   │   ├── modules/           # Branches, devices, pos, products, inventory, hr, finance, compliance
│   │   └── sync/              # Native push/pull sync engine (replaces PowerSync)
│   ├── migrations/            # 13 ordered PostgreSQL enterprise migrations
│   ├── setup_giftmart_db.sql  # Consolidated Giftmart database schema & seed
│   ├── setup_giftmart_db.ps1  # Automated DB initialization runner
│   └── Cargo.toml
│
└── hirallpos/                 # Client Applications
    ├── desktop-app/           # Flutter Desktop POS Application
    │   ├── lib/
    │   │   ├── core/          # Drift DB, Native SyncService, API client, theme
    │   │   ├── features/      # Cashier, storekeeping, outlets, accounting, waiter, HR
    │   │   └── main.dart      # GiftmartPosApp entrypoint
    │   └── pubspec.yaml
    ├── web-admin/             # Web Management Dashboard (HTML5 / JS / CSS)
    ├── mobile-app/            # Staff Mobile Companion (LAN Wireless Bridge)
    ├── docker-compose.yml     # Unified Dev Stack (PostgreSQL + Redis + Rust Backend)
    ├── run_backend.bat        # Launch backend on Windows
    ├── run_backend.sh         # Launch backend on Linux
    └── README.md
```

---

## Getting Started

### 1. Database Setup (`giftmart`)
Generate and apply all 13 enterprise migrations and the Giftmart Supermarket seed data:
```powershell
# From hirall-backend:
powershell -ExecutionPolicy Bypass -File setup_giftmart_db.ps1
```
Or execute `hirall-backend/setup_giftmart_db.sql` directly in PostgreSQL.

### 2. Launch Backend
Run via script:
```powershell
# Windows:
.\run_backend.bat

# Linux:
./run_backend.sh
```
Or directly with Cargo:
```bash
cd ../hirall-backend
cargo run --bin hirall-backend
```
Backend API will be live at: `http://localhost:8080/api/v1`
Health check: `http://localhost:8080/health`

### 3. Launch Web Admin
Open `web-admin/index.html` in any browser or serve with a static server:
```bash
cd web-admin
npx serve .
```

### 4. Launch Flutter Desktop Client
```bash
cd desktop-app
flutter pub get
flutter run -d windows # or -d linux / -d macos
```

---

## Default Administrative Credentials

| Account | Email | Password | PIN | Role |
|---|---|---|---|---|
| **Super-Admin** | `admin@giftmart.co.ke` | `Admin@12345` | `1234` | Enterprise Super-Admin |
| **Store Manager** | `manager.kericho@giftmart.co.ke` | `Admin@12345` | `2026` | Kericho Main Branch Manager |
| **Cashier 1** | `cashier1@giftmart.co.ke` | `Admin@12345` | `1111` | Till Operator Lane 1 |
