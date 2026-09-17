use axum::{
    extract::{Path, Query, State},
    routing::get,
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::{AuthUser, MaybeAuthUser};
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct StockBalance {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub product_id: Uuid,
    pub quantity: BigDecimal,
    pub reserved_quantity: BigDecimal,
    pub min_stock_level: Option<BigDecimal>,
    pub max_stock_level: Option<BigDecimal>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct StockMovement {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub product_id: Uuid,
    pub movement_type: String,
    pub quantity: BigDecimal,
    pub unit_cost: BigDecimal,
    pub reference_type: Option<String>,
    pub reference_id: Option<Uuid>,
    pub device_id: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RecordStockMovementRequest {
    pub branch_id: Uuid,
    pub product_id: Uuid,
    pub movement_type: String, // PURCHASE, ADJUSTMENT, BREAKAGE, etc.
    pub quantity: BigDecimal,   // positive for addition, negative for reduction
    pub unit_cost: BigDecimal,
    pub reference_type: Option<String>,
    pub reference_id: Option<Uuid>,
    pub device_id: Option<Uuid>,
    pub notes: Option<String>,
}

pub async fn get_branch_stock(
    Path(branch_id): Path<Uuid>,
    auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<StockBalance>>> {
    let balances = sqlx::query_as::<_, StockBalance>(
        r#"
        SELECT id, organization_id, branch_id, product_id, quantity, reserved_quantity,
               min_stock_level, max_stock_level, updated_at
        FROM stock_balances
        WHERE organization_id = $1 AND branch_id = $2
        "#,
    )
    .bind(auth.organization_id)
    .bind(branch_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(balances))
}

pub async fn record_stock_movement(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<RecordStockMovementRequest>,
) -> AppResult<Json<StockMovement>> {
    let mut tx = state.pool().await.begin().await?;

    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        let default_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&mut *tx)
        .await?;
        default_org.unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    // 1. Atomically update the branch stock balance and get new balance
    let new_balance = sqlx::query_scalar::<_, BigDecimal>(
        r#"
        INSERT INTO stock_balances (organization_id, branch_id, product_id, location_area, quantity, reserved_quantity, updated_at)
        VALUES ($1, $2, $3, 'SHOP_FLOOR', $4, 0, NOW())
        ON CONFLICT (branch_id, product_id, location_area)
        DO UPDATE SET
            quantity = stock_balances.quantity + EXCLUDED.quantity,
            updated_at = NOW()
        RETURNING quantity
        "#,
    )
    .bind(org_id)
    .bind(payload.branch_id)
    .bind(payload.product_id)
    .bind(&payload.quantity)
    .fetch_one(&mut *tx)
    .await?;

    // 2. Insert immutable movement audit row
    let movement = sqlx::query_as::<_, StockMovement>(
        r#"
        INSERT INTO stock_movements (
            organization_id, branch_id, product_id, location_area, movement_type, quantity,
            balance_after, unit_cost, reference_type, reference_id, device_id, notes
        )
        VALUES ($1, $2, $3, 'SHOP_FLOOR', $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING id, organization_id, branch_id, product_id, movement_type, quantity,
                  unit_cost, reference_type, reference_id, device_id, notes, created_at
        "#,
    )
    .bind(org_id)
    .bind(payload.branch_id)
    .bind(payload.product_id)
    .bind(payload.movement_type)
    .bind(payload.quantity)
    .bind(new_balance)
    .bind(payload.unit_cost)
    .bind(payload.reference_type)
    .bind(payload.reference_id)
    .bind(payload.device_id)
    .bind(payload.notes)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;

    Ok(Json(movement))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct StockMovementQuery {
    pub branch_id: Option<Uuid>,
    pub product_id: Option<Uuid>,
    pub movement_type: Option<String>,
    pub limit: Option<i64>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct StockMovementDetail {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub product_id: Uuid,
    pub product_name: Option<String>,
    pub sku: Option<String>,
    pub barcode: Option<String>,
    pub location_area: String,
    pub movement_type: String,
    pub quantity: BigDecimal,
    pub balance_after: BigDecimal,
    pub unit_cost: BigDecimal,
    pub reference_type: Option<String>,
    pub reference_id: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub async fn list_stock_movements(
    Query(params): Query<StockMovementQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<StockMovementDetail>>> {
    let pool = state.pool().await;
    let limit = params.limit.unwrap_or(200).min(1000);

    let movements = if let Some(bid) = params.branch_id {
        sqlx::query_as::<_, StockMovementDetail>(
            r#"
            SELECT 
                sm.id, sm.organization_id, sm.branch_id, sm.product_id,
                p.name AS product_name,
                p.sku AS sku,
                p.barcode AS barcode,
                sm.location_area, sm.movement_type, sm.quantity, sm.balance_after,
                sm.unit_cost, sm.reference_type, sm.reference_id, sm.notes, sm.created_at
            FROM stock_movements sm
            LEFT JOIN products p ON sm.product_id = p.id
            WHERE sm.branch_id = $1
            ORDER BY sm.created_at DESC
            LIMIT $2
            "#
        )
        .bind(bid)
        .bind(limit)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, StockMovementDetail>(
            r#"
            SELECT 
                sm.id, sm.organization_id, sm.branch_id, sm.product_id,
                p.name AS product_name,
                p.sku AS sku,
                p.barcode AS barcode,
                sm.location_area, sm.movement_type, sm.quantity, sm.balance_after,
                sm.unit_cost, sm.reference_type, sm.reference_id, sm.notes, sm.created_at
            FROM stock_movements sm
            LEFT JOIN products p ON sm.product_id = p.id
            ORDER BY sm.created_at DESC
            LIMIT $1
            "#
        )
        .bind(limit)
        .fetch_all(&pool)
        .await?
    };

    Ok(Json(movements))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/movements", get(list_stock_movements).post(record_stock_movement))
        .route("/branch/:branch_id", get(get_branch_stock))
}
