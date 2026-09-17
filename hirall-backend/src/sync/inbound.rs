use axum::{extract::State, Json};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::{AuthUser, MaybeAuthUser};
use crate::core::errors::AppResult;
use crate::modules::pos::{create_sale, CreateSaleRequest};

#[derive(Debug, Deserialize)]
pub struct InboundSyncItem {
    pub client_event_id: Uuid,
    pub entity_type: String, // SALE, STOCK_MOVEMENT, CASHIER_SESSION
    pub operation: String,   // INSERT, UPDATE
    pub payload: Value,
    pub client_timestamp: DateTime<Utc>,
    pub branch_id: Uuid,
    pub device_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct PushSyncBatchRequest {
    pub device_uuid: String,
    pub items: Vec<InboundSyncItem>,
}

#[derive(Debug, Serialize)]
pub struct PushSyncBatchResponse {
    pub acknowledged_event_ids: Vec<Uuid>,
    pub failed_event_ids: Vec<Uuid>,
    pub server_time: DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
struct IdRow {
    pub id: Uuid,
}

pub async fn push_sync_batch(
    auth: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<PushSyncBatchRequest>,
) -> AppResult<Json<PushSyncBatchResponse>> {
    let mut acknowledged = Vec::new();
    let mut failed = Vec::new();

    // Verify device exists and belongs to organization
    let device_opt = sqlx::query_as::<_, IdRow>(
        "SELECT id FROM devices WHERE device_uuid = $1 AND organization_id = $2",
    )
    .bind(&payload.device_uuid)
    .bind(auth.organization_id)
    .fetch_optional(&state.pool().await)
    .await?;

    let device_id = device_opt.map(|d| d.id);

    for item in payload.items {
        // 1. Check idempotency: Was this client_event_id already received?
        let existing = sqlx::query_as::<_, IdRow>(
            "SELECT id FROM sync_events WHERE client_event_id = $1 AND organization_id = $2",
        )
        .bind(item.client_event_id)
        .bind(auth.organization_id)
        .fetch_optional(&state.pool().await)
        .await?;

        if existing.is_some() {
            acknowledged.push(item.client_event_id);
            continue;
        }

        // 2. Begin transaction for this event
        let mut tx = state.pool().await.begin().await?;

        let record_result = sqlx::query(
            r#"
            INSERT INTO sync_events (
                organization_id, branch_id, device_id, client_event_id,
                event_type, entity_type, entity_id, payload, client_timestamp,
                processed_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
            "#,
        )
        .bind(auth.organization_id)
        .bind(item.branch_id)
        .bind(device_id.or(item.device_id))
        .bind(item.client_event_id)
        .bind(&item.operation)
        .bind(&item.entity_type)
        .bind(item.client_event_id) // fallback entity_id if not distinct
        .bind(&item.payload)
        .bind(item.client_timestamp)
        .execute(&mut *tx)
        .await;

        match record_result {
            Ok(_) => {
                // If the entity is a SALE, we unpack and process it into the relational sales tables
                if item.entity_type == "SALE" {
                    if let Ok(sale_req) = serde_json::from_value::<CreateSaleRequest>(item.payload.clone()) {
                        let _ = create_sale(
                            MaybeAuthUser(Some(AuthUser {
                                user_id: auth.user_id,
                                organization_id: auth.organization_id,
                                branch_id: Some(item.branch_id),
                                role: auth.role.clone(),
                            })),
                            State(state.clone()),
                            Json(sale_req),
                        )
                        .await;
                    }
                }

                if let Err(e) = tx.commit().await {
                    tracing::error!("Commit error for sync item: {:?}", e);
                    failed.push(item.client_event_id);
                } else {
                    acknowledged.push(item.client_event_id);
                }
            }
            Err(e) => {
                tracing::error!("Failed to record sync item {}: {:?}", item.client_event_id, e);
                let _ = tx.rollback().await;
                failed.push(item.client_event_id);
            }
        }
    }

    Ok(Json(PushSyncBatchResponse {
        acknowledged_event_ids: acknowledged,
        failed_event_ids: failed,
        server_time: Utc::now(),
    }))
}
