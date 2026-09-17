use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::{AppError, AppResult};

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Organization {
    pub id: Uuid,
    pub name: String,
    pub code: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub currency: String,
    pub timezone: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateOrganizationRequest {
    pub name: String,
    pub code: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub currency: Option<String>,
    pub timezone: Option<String>,
}

pub async fn list_organizations(
    _auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Organization>>> {
    let orgs = sqlx::query_as::<_, Organization>(
        r#"
        SELECT id, name, code, email, phone, currency, timezone, status, created_at, updated_at
        FROM organizations
        ORDER BY created_at DESC
        "#,
    )
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(orgs))
}

pub async fn get_organization(
    Path(id): Path<Uuid>,
    _auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Organization>> {
    let org = sqlx::query_as::<_, Organization>(
        r#"
        SELECT id, name, code, email, phone, currency, timezone, status, created_at, updated_at
        FROM organizations
        WHERE id = $1
        "#,
    )
    .bind(id)
    .fetch_optional(&state.pool().await)
    .await?
    .ok_or_else(|| AppError::NotFound("Organization not found".into()))?;

    Ok(Json(org))
}

pub async fn create_organization(
    State(state): State<AppState>,
    Json(payload): Json<CreateOrganizationRequest>,
) -> AppResult<Json<Organization>> {
    let currency = payload.currency.unwrap_or_else(|| "USD".to_string());
    let timezone = payload.timezone.unwrap_or_else(|| "UTC".to_string());

    let org = sqlx::query_as::<_, Organization>(
        r#"
        INSERT INTO organizations (name, code, email, phone, currency, timezone, status)
        VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE')
        RETURNING id, name, code, email, phone, currency, timezone, status, created_at, updated_at
        "#,
    )
    .bind(payload.name)
    .bind(payload.code)
    .bind(payload.email)
    .bind(payload.phone)
    .bind(currency)
    .bind(timezone)
    .fetch_one(&state.pool().await)
    .await?;

    Ok(Json(org))
}

pub async fn get_current_organization(
    State(state): State<AppState>,
) -> AppResult<Json<Organization>> {
    let org = sqlx::query_as::<_, Organization>(
        r#"
        SELECT id, name, code, email, phone, currency, timezone, status, created_at, updated_at
        FROM organizations
        WHERE status = 'ACTIVE'
        ORDER BY created_at ASC
        LIMIT 1
        "#,
    )
    .fetch_optional(&state.pool().await)
    .await?
    .ok_or_else(|| AppError::NotFound("No active organization found".into()))?;

    Ok(Json(org))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(list_organizations).post(create_organization))
        .route("/current", get(get_current_organization))
        .route("/:id", get(get_organization))
}
