use axum::{
    routing::get,
    Json, Router,
};
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

use crate::app::state::AppState;
use crate::modules::{
    branches, compliance, devices, finance, hospitality, hr, inventory, organizations, pos,
    procurement, products, users, warehouse,
};
use crate::sync;

pub fn create_router(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let api_v1 = Router::new()
        .nest("/auth", users::auth_router())
        .nest("/organizations", organizations::router())
        .nest("/branches", branches::router())
        .nest("/devices", devices::router())
        .nest("/products", products::router())
        .nest("/inventory", inventory::router())
        .nest("/procurement", procurement::router())
        .route("/suppliers", get(procurement::list_suppliers).post(procurement::create_supplier))
        .route("/purchase-orders", get(procurement::list_purchase_orders).post(procurement::create_purchase_order))
        .nest("/pos", pos::router())
        .nest("/hospitality", hospitality::router())
        .nest("/warehouse", warehouse::router())
        .nest("/finance", finance::router())
        .nest("/hr", hr::router())
        .nest("/compliance", compliance::router())
        .nest("/sync", sync::router());

    Router::new()
        .route("/health", get(health_check))
        .nest("/api/v1", api_v1)
        .layer(TraceLayer::new_for_http())
        .layer(cors)
        .with_state(state)
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "hirall-backend",
        "version": env!("CARGO_PKG_VERSION"),
        "compliance": {
            "etims": "VSCU/OSCU Ready",
            "mpesa": "Daraja 3.0 Ready"
        }
    }))
}
