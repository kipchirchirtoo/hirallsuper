pub mod conflict;
pub mod inbound;
pub mod outbound;

use axum::{
    routing::{get, post},
    Router,
};

use crate::app::state::AppState;
use inbound::push_sync_batch;
use outbound::pull_sync_deltas;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/push", post(push_sync_batch))
        .route("/pull", get(pull_sync_deltas))
}
