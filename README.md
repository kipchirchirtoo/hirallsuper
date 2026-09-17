# HirallSuper 🛒

Enterprise-grade, distributed Point-of-Sale (POS), Inventory, and Supermarket Management System.

---

## 🏗️ Architecture Overview

The `hirallsuper` monorepo brings together the complete supermarket retail ecosystem:

```
supermarket/
├── hirall-backend/        # High-performance Rust (Axum + SQLx + Tokio) API server
│   ├── Dockerfile         # Multi-stage production container build
│   ├── docker-compose.yml # Local services (PostgreSQL, Redis, MinIO)
│   ├── migrations/        # SQLx database schema migrations
│   └── src/               # Axum endpoints, services, and models
│
└── hirallpos/             # Client applications & Admin
    ├── desktop-app/       # Offline-first Flutter Desktop POS (Windows, Linux, macOS)
    ├── mobile-app/        # Flutter Mobile POS & Stocktaking Assistant (Android)
    └── web-admin/         # Web Back-Office Admin Dashboard (HTML/CSS/JS)
```

---

## 🚀 Components

### 1. High-Performance Backend (`hirall-backend`)
- **Framework**: Rust, Axum, SQLx, Tokio.
- **Database**: PostgreSQL (Aurora/RDS, Neon, or Docker) with Row-Level Security (RLS).
- **Caching & Realtime**: Redis for pub/sub notifications and fast cache.
- **Object Storage**: S3-compatible (MinIO for development, Cloudflare R2 / AWS S3 for production).
- **Auth**: JWT with HMAC-SHA256 and refresh token lifecycle.

#### Quick Start (Backend):
```bash
cd hirall-backend
# Start local DB & Redis (if not using cloud RDS)
docker compose up -d

# Run Rust API
cargo run
```

### 2. Desktop POS Client (`hirallpos/desktop-app`)
- Built with **Flutter Desktop** for cashiers and store checkout lanes.
- Supports ESC/POS thermal receipt printing, barcode scanning, cashier shifts, and offline sync.

### 3. Mobile POS & Stocktaking (`hirallpos/mobile-app`)
- Built with **Flutter Mobile** for floor staff, mobile cashiering, price checkers, and warehouse stock-in.

### 4. Web Admin Dashboard (`hirallpos/web-admin`)
- Web back-office management for inventory, multi-branch control, HR/staff permissions, and reports.

---

## 🔒 Security & Environment Configuration

Configuration is managed via `.env` files. Never commit `.env` containing sensitive credentials to version control. Use `.env.example` templates provided in the subdirectories.

---

## 📦 Deployment

- **Backend**: Containerized via multi-stage `Dockerfile`. Ready for deployment to AWS App Runner, ECS Fargate, Render, Railway, or Linux VPS with Docker Compose.
- **Database**: PostgreSQL 16+ with extensions (`uuid-ossp`, `pgcrypto`).
- **Clients**: Automated compilation via Flutter for target platforms (Windows `.exe`, Android `.apk`).

---

## 📄 License
Proprietary & Confidential - Hirall / Giftmart Supermarket.
