use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct WarehouseLocation {
    pub id: Uuid,
    pub warehouse_id: Uuid,
    pub code: String,
    pub zone: String,
    pub temperature_type: String,
    pub is_active: bool,
}

#[derive(Debug, Serialize)]
pub struct ReplenishmentSuggestion {
    pub product_id: Uuid,
    pub sku: String,
    pub product_name: String,
    pub current_stock: BigDecimal,
    pub min_level: BigDecimal,
    pub max_level: BigDecimal,
    pub suggested_order_qty: BigDecimal,
}

#[derive(Debug, sqlx::FromRow)]
struct ReplenishmentRow {
    pub product_id: Uuid,
    pub sku: String,
    pub product_name: String,
    pub current_stock: BigDecimal,
    pub min_level: BigDecimal,
    pub max_level: BigDecimal,
    pub safety_stock: BigDecimal,
}

pub async fn list_bins(
    Path(warehouse_id): Path<Uuid>,
    _auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<WarehouseLocation>>> {
    let bins = sqlx::query_as::<_, WarehouseLocation>(
        r#"
        SELECT id, warehouse_id, code, zone, temperature_type, is_active
        FROM warehouse_locations
        WHERE warehouse_id = $1
        ORDER BY zone, code ASC
        "#,
    )
    .bind(warehouse_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(bins))
}

pub async fn calculate_branch_replenishment(
    Path(branch_id): Path<Uuid>,
    auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<ReplenishmentSuggestion>>> {
    let rows = sqlx::query_as::<_, ReplenishmentRow>(
        r#"
        SELECT
            p.id as product_id,
            p.sku,
            p.name as product_name,
            COALESCE(sb.quantity, 0) as current_stock,
            rr.min_stock_level as min_level,
            rr.max_stock_level as max_level,
            rr.safety_stock
        FROM replenishment_rules rr
        JOIN products p ON p.id = rr.product_id
        LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.branch_id = rr.branch_id
        WHERE rr.branch_id = $1 AND rr.organization_id = $2
        "#,
    )
    .bind(branch_id)
    .bind(auth.organization_id)
    .fetch_all(&state.pool().await)
    .await?;

    let suggestions = rows
        .into_iter()
        .filter_map(|r| {
            let current = r.current_stock;
            let min_lvl = r.min_level;
            let max_lvl = r.max_level;
            let safety = r.safety_stock;

            if current <= min_lvl {
                let suggested = (&max_lvl - &current) + &safety;
                Some(ReplenishmentSuggestion {
                    product_id: r.product_id,
                    sku: r.sku,
                    product_name: r.product_name,
                    current_stock: current,
                    min_level: min_lvl,
                    max_level: max_lvl,
                    suggested_order_qty: suggested,
                })
            } else {
                None
            }
        })
        .collect();

    Ok(Json(suggestions))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/warehouses/:id/bins", get(list_bins))
        .route("/branch/:branch_id/replenishment-suggestions", get(calculate_branch_replenishment))
}
