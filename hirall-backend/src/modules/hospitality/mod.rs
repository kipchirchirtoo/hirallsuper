use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct RestaurantTable {
    pub id: Uuid,
    pub floor_id: Uuid,
    pub table_number: String,
    pub capacity: i32,
    pub status: String, // AVAILABLE, OCCUPIED, ORDERED, PREPARING, READY, BILL_REQUESTED, PAID
    pub pos_x: i32,
    pub pos_y: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateTableStatusRequest {
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct RecipeItem {
    pub id: Uuid,
    pub menu_product_id: Uuid,
    pub ingredient_product_id: Uuid,
    pub quantity_required: BigDecimal,
    pub unit_of_measure: String,
}

pub async fn list_branch_tables(
    Path(branch_id): Path<Uuid>,
    _auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<RestaurantTable>>> {
    let tables = sqlx::query_as::<_, RestaurantTable>(
        r#"
        SELECT t.id, t.floor_id, t.table_number, t.capacity, t.status, t.pos_x, t.pos_y, t.created_at
        FROM restaurant_tables t
        JOIN restaurant_floors f ON f.id = t.floor_id
        WHERE f.branch_id = $1
        ORDER BY t.table_number ASC
        "#,
    )
    .bind(branch_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(tables))
}

pub async fn update_table_status(
    Path(table_id): Path<Uuid>,
    _auth: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<UpdateTableStatusRequest>,
) -> AppResult<Json<serde_json::Value>> {
    sqlx::query(
        "UPDATE restaurant_tables SET status = $1 WHERE id = $2",
    )
    .bind(&payload.status)
    .bind(table_id)
    .execute(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "status": "ok",
        "table_id": table_id,
        "new_status": payload.status
    })))
}

pub async fn get_recipe(
    Path(menu_product_id): Path<Uuid>,
    _auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<RecipeItem>>> {
    let ingredients = sqlx::query_as::<_, RecipeItem>(
        r#"
        SELECT id, menu_product_id, ingredient_product_id, quantity_required, unit_of_measure
        FROM recipes_bom
        WHERE menu_product_id = $1
        "#,
    )
    .bind(menu_product_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(ingredients))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/branch/:branch_id/tables", get(list_branch_tables))
        .route("/tables/:table_id/status", post(update_table_status))
        .route("/recipes/:menu_product_id", get(get_recipe))
}
