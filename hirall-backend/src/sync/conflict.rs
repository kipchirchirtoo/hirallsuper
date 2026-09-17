use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;

use crate::core::errors::AppResult;

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
pub enum ConflictResolutionStrategy {
    LastWriteWins,
    ServerWins,
    ClientWins,
    ManualReview,
}

#[allow(dead_code)]
#[derive(Debug, sqlx::FromRow)]
struct IdRow {
    pub id: Uuid,
}

#[allow(dead_code)]
pub async fn log_conflict(
    pool: &PgPool,
    organization_id: Uuid,
    branch_id: Uuid,
    device_id: Option<Uuid>,
    entity_type: &str,
    entity_id: Uuid,
    conflict_type: &str,
    client_payload: Value,
    server_payload: Value,
    resolution_status: &str,
) -> AppResult<Uuid> {
    let id_row = sqlx::query_as::<_, IdRow>(
        r#"
        INSERT INTO sync_conflicts (
            organization_id, branch_id, device_id, entity_type, entity_id,
            conflict_type, client_payload, server_payload, resolution_status
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
        "#,
    )
    .bind(organization_id)
    .bind(branch_id)
    .bind(device_id)
    .bind(entity_type)
    .bind(entity_id)
    .bind(conflict_type)
    .bind(client_payload)
    .bind(server_payload)
    .bind(resolution_status)
    .fetch_one(pool)
    .await?;

    Ok(id_row.id)
}
