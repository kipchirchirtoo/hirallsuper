use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::MaybeAuthUser;
use crate::core::errors::{AppError, AppResult};

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Branch {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub code: String,
    pub address: Option<String>,
    pub phone: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateBranchRequest {
    pub name: String,
    pub code: String,
    pub address: Option<String>,
    pub phone: Option<String>,
}

pub async fn list_branches(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Branch>>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let branches = sqlx::query_as::<_, Branch>(
        r#"
        SELECT id, organization_id, name, code, address, phone, status, created_at, updated_at
        FROM branches
        WHERE organization_id = $1
        ORDER BY name ASC
        "#,
    )
    .bind(org_id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(branches))
}

pub async fn create_branch(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreateBranchRequest>,
) -> AppResult<Json<Branch>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let branch = sqlx::query_as::<_, Branch>(
        r#"
        INSERT INTO branches (organization_id, name, code, address, phone, status)
        VALUES ($1, $2, $3, $4, $5, 'ACTIVE')
        RETURNING id, organization_id, name, code, address, phone, status, created_at, updated_at
        "#,
    )
    .bind(org_id)
    .bind(payload.name)
    .bind(payload.code)
    .bind(payload.address)
    .bind(payload.phone)
    .fetch_one(&pool)
    .await?;

    Ok(Json(branch))
}

pub async fn get_branch(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
) -> AppResult<Json<Branch>> {
    let branch = sqlx::query_as::<_, Branch>(
        r#"
        SELECT id, organization_id, name, code, address, phone, status, created_at, updated_at
        FROM branches
        WHERE id = $1
        "#,
    )
    .bind(id)
    .fetch_optional(&state.pool().await)
    .await?
    .ok_or_else(|| AppError::NotFound("Branch not found".into()))?;

    Ok(Json(branch))
}

pub async fn list_public_branches(
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Branch>>> {
    let branches = sqlx::query_as::<_, Branch>(
        r#"
        SELECT id, organization_id, name, code, address, phone, status, created_at, updated_at
        FROM branches
        WHERE status = 'ACTIVE'
        ORDER BY name ASC
        "#,
    )
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(branches))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct UpdateBranchRequest {
    pub name: Option<String>,
    pub code: Option<String>,
    pub address: Option<String>,
    pub phone: Option<String>,
    pub status: Option<String>,
}

pub async fn update_branch(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<UpdateBranchRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;

    let existing = sqlx::query_as::<_, (String, String, Option<String>, Option<String>, String)>(
        "SELECT name, code, address, phone, status FROM branches WHERE id = $1"
    )
    .bind(id)
    .fetch_optional(&pool)
    .await?;

    let (old_name, old_code, old_address, old_phone, old_status) = match existing {
        Some(b) => b,
        None => return Err(AppError::NotFound("Branch not found".into())),
    };

    let name = payload.name.unwrap_or(old_name);
    let code = payload.code.unwrap_or(old_code);
    let address = payload.address.or(old_address);
    let phone = payload.phone.or(old_phone);
    let status = payload.status.unwrap_or(old_status);

    sqlx::query(
        r#"
        UPDATE branches
        SET name = $1, code = $2, address = $3, phone = $4, status = $5, updated_at = NOW()
        WHERE id = $6
        "#
    )
    .bind(name)
    .bind(code)
    .bind(address)
    .bind(phone)
    .bind(status)
    .bind(id)
    .execute(&pool)
    .await?;

    Ok(Json(serde_json::json!({ "id": id, "success": true })))
}

pub async fn delete_branch(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;
    sqlx::query("UPDATE branches SET status = 'INACTIVE', updated_at = NOW() WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await?;
    Ok(Json(serde_json::json!({ "id": id, "deleted": true })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(list_branches).post(create_branch))
        .route("/public", get(list_public_branches))
        .route("/:id", get(get_branch).put(update_branch).delete(delete_branch))
}
