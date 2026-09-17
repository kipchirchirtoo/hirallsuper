pub mod etims;
pub mod mpesa;

use axum::Router;
use crate::app::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .nest("/etims", etims::router())
        .nest("/mpesa", mpesa::router())
}
