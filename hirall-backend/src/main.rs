use std::net::SocketAddr;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod app;
mod core;
mod modules;
mod sync;

use app::{config::Config, router::create_router, state::AppState};
use core::{database::create_pool, storage::StorageService};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1. Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "hirall_backend=debug,tower_http=debug,axum=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    info!("Starting HIRALL Cloud Platform Backend...");

    // 2. Load configuration
    let config = Config::from_env();
    info!("Configuration loaded for environment: {}", config.environment);

    // 3. Initialize PostgreSQL Database Pool (returns Arc<RwLock<PgPool>> for hot-swap IAM renewal)
    let db_pool = create_pool(&config.database_url, config.database_max_connections).await?;

    // 4. Initialize Object Storage (S3 / Cloudflare R2 / MinIO)
    let storage_service = StorageService::new(&config).await;

    // 5. Construct Application State
    let app_state = AppState::new_with_shared(db_pool, config.clone(), storage_service);

    // 6. Build Axum Router
    let app = create_router(app_state);

    // 7. Bind and start TCP Server
    let addr = SocketAddr::from(([0, 0, 0, 0], config.server_port));
    info!("HIRALL Backend listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
