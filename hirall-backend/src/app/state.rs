use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::app::config::Config;
use crate::core::storage::StorageService;

/// Thread-safe, hot-swappable pool handle.
pub type SharedPool = Arc<RwLock<PgPool>>;

#[derive(Clone)]
pub struct AppState {
    pub db: SharedPool,
    pub config: Arc<Config>,
    pub storage: Arc<StorageService>,
}

impl AppState {
    /// Legacy constructor — wraps the pool in a SharedPool internally.
    #[allow(dead_code)]
    pub fn new(db: PgPool, config: Config, storage: StorageService) -> Self {
        Self {
            db: Arc::new(RwLock::new(db)),
            config: Arc::new(config),
            storage: Arc::new(storage),
        }
    }

    /// Constructor when create_pool() already returns a SharedPool.
    pub fn new_with_shared(db: SharedPool, config: Config, storage: StorageService) -> Self {
        Self {
            db,
            config: Arc::new(config),
            storage: Arc::new(storage),
        }
    }

    /// Acquire the current pool (cheap — just clones the Arc inside the RwLock).
    /// Use this in handlers instead of `&state.pool().await`.
    ///
    /// ```rust
    /// let pool = state.pool().await;
    /// sqlx::query(...).fetch_all(&pool).await?;
    /// ```
    pub async fn pool(&self) -> PgPool {
        self.db.read().await.clone()
    }
}
