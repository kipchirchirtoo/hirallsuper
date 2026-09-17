use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Employee {
    pub id: Uuid,
    pub employee_number: String,
    pub first_name: String,
    pub last_name: String,
    pub national_id: String,
    pub kra_pin: String,
    pub phone: String,
    pub job_title: String,
    pub basic_salary: BigDecimal,
    pub employment_status: String,
}

#[derive(Debug, Deserialize)]
pub struct ClockInRequest {
    pub employee_id: Uuid,
    pub branch_id: Uuid,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
pub struct KenyanPayslipEstimate {
    pub basic_salary: BigDecimal,
    pub gross_pay: BigDecimal,
    pub nssf_deduction: BigDecimal,
    pub shif_deduction: BigDecimal, // 2.75%
    pub housing_levy: BigDecimal,   // 1.5%
    pub paye_tax: BigDecimal,
    pub total_deductions: BigDecimal,
    pub net_pay: BigDecimal,
}

#[derive(Debug, sqlx::FromRow)]
struct IdRow {
    pub id: Uuid,
}

pub async fn list_branch_employees(
    Path(branch_id): Path<Uuid>,
    auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Employee>>> {
    let emps = sqlx::query_as::<_, Employee>(
        r#"
        SELECT id, employee_number, first_name, last_name, national_id, kra_pin,
               phone, job_title, basic_salary, employment_status
        FROM employees
        WHERE organization_id = $1 AND branch_id = $2
        ORDER BY first_name ASC
        "#,
    )
    .bind(auth.organization_id)
    .bind(branch_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(emps))
}

pub async fn clock_in(
    auth: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<ClockInRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let id_row = sqlx::query_as::<_, IdRow>(
        r#"
        INSERT INTO attendance_logs (organization_id, branch_id, employee_id, clock_in, source)
        VALUES ($1, $2, $3, NOW(), 'POS_TERMINAL')
        RETURNING id
        "#,
    )
    .bind(auth.organization_id)
    .bind(payload.branch_id)
    .bind(payload.employee_id)
    .fetch_one(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "status": "clocked_in",
        "attendance_id": id_row.id,
        "timestamp": Utc::now()
    })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/branch/:branch_id/employees", get(list_branch_employees))
        .route("/attendance/clock-in", post(clock_in))
}
