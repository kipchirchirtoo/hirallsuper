use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::{AppError, AppResult};

#[derive(Debug, Deserialize)]
pub struct StkPushRequest {
    pub branch_id: Uuid,
    pub sale_id: Option<Uuid>,
    pub phone_number: String, // 2547XXXXXXXX
    pub amount: BigDecimal,
}

#[derive(Debug, Serialize)]
pub struct StkPushResponse {
    pub merchant_request_id: String,
    pub checkout_request_id: String,
    pub response_code: String,
    pub customer_message: String,
}

#[derive(Debug, Deserialize)]
pub struct DarajaCallbackPayload {
    #[serde(rename = "Body")]
    pub body: DarajaBody,
}

#[allow(non_snake_case)]
#[derive(Debug, Serialize, Deserialize)]
pub struct DarajaBody {
    pub stkCallback: StkCallbackData,
}

#[allow(non_snake_case)]
#[derive(Debug, Serialize, Deserialize)]
pub struct StkCallbackData {
    pub MerchantRequestID: String,
    pub CheckoutRequestID: String,
    pub ResultCode: i32,
    pub ResultDesc: String,
    pub CallbackMetadata: Option<Value>,
}

#[derive(Debug, sqlx::FromRow)]
struct MpesaTxStatusRow {
    pub status: String,
    pub result_code: Option<i32>,
    pub result_desc: Option<String>,
    pub mpesa_receipt_number: Option<String>,
    pub amount: BigDecimal,
    pub phone_number: String,
}

pub async fn initiate_stk_push(
    auth: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<StkPushRequest>,
) -> AppResult<Json<StkPushResponse>> {
    let merchant_request_id = format!("MR-{}", Uuid::new_v4().to_string().replace("-", "")[..12].to_uppercase());
    let checkout_request_id = format!("ws_CO_{}_{}", Utc::now().timestamp_millis(), &payload.phone_number[payload.phone_number.len()-4..]);

    // 1. Record pending transaction in mpesa_transactions
    sqlx::query(
        r#"
        INSERT INTO mpesa_transactions (
            organization_id, branch_id, sale_id, transaction_type,
            merchant_request_id, checkout_request_id, phone_number, amount, status
        )
        VALUES ($1, $2, $3, 'STK_PUSH', $4, $5, $6, $7, 'PENDING')
        "#,
    )
    .bind(auth.organization_id)
    .bind(payload.branch_id)
    .bind(payload.sale_id)
    .bind(&merchant_request_id)
    .bind(&checkout_request_id)
    .bind(&payload.phone_number)
    .bind(payload.amount)
    .execute(&state.pool().await)
    .await?;

    // In production, this issues an HTTPS POST to https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest
    Ok(Json(StkPushResponse {
        merchant_request_id,
        checkout_request_id,
        response_code: "0".to_string(),
        customer_message: "Success. Request accepted for processing on customer handset.".to_string(),
    }))
}

pub async fn handle_daraja_callback(
    State(state): State<AppState>,
    Json(payload): Json<DarajaCallbackPayload>,
) -> AppResult<Json<serde_json::Value>> {
    let cb = payload.body.stkCallback;
    let status = if cb.ResultCode == 0 { "COMPLETED" } else { "FAILED" };

    // Extract M-Pesa receipt number from CallbackMetadata if present
    let mut receipt_num = None;
    if let Some(meta) = &cb.CallbackMetadata {
        if let Some(items) = meta.get("Item").and_then(|i| i.as_array()) {
            for itm in items {
                if itm.get("Name").and_then(|n| n.as_str()) == Some("MpesaReceiptNumber") {
                    receipt_num = itm.get("Value").and_then(|v| v.as_str()).map(|s| s.to_string());
                }
            }
        }
    }

    let raw_json = serde_json::to_value(&cb).unwrap_or_default();

    sqlx::query(
        r#"
        UPDATE mpesa_transactions
        SET status = $1,
            result_code = $2,
            result_desc = $3,
            mpesa_receipt_number = $4,
            raw_callback_payload = $5,
            transaction_date = NOW(),
            updated_at = NOW()
        WHERE checkout_request_id = $6
        "#,
    )
    .bind(status)
    .bind(cb.ResultCode)
    .bind(&cb.ResultDesc)
    .bind(receipt_num)
    .bind(raw_json)
    .bind(&cb.CheckoutRequestID)
    .execute(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "ResultCode": 0,
        "ResultDesc": "Callback accepted successfully"
    })))
}

pub async fn check_stk_status(
    Path(checkout_request_id): Path<String>,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    let tx = sqlx::query_as::<_, MpesaTxStatusRow>(
        r#"
        SELECT status, result_code, result_desc, mpesa_receipt_number, amount, phone_number
        FROM mpesa_transactions
        WHERE checkout_request_id = $1
        "#,
    )
    .bind(&checkout_request_id)
    .fetch_optional(&state.pool().await)
    .await?
    .ok_or_else(|| AppError::NotFound("Transaction not found".into()))?;

    Ok(Json(serde_json::json!({
        "checkout_request_id": checkout_request_id,
        "status": tx.status,
        "result_code": tx.result_code,
        "result_desc": tx.result_desc,
        "mpesa_receipt_number": tx.mpesa_receipt_number,
        "amount": tx.amount,
        "phone_number": tx.phone_number
    })))
}

#[derive(Debug, Deserialize)]
pub struct SimulateMpesaRequest {
    pub checkout_request_id: String,
    pub result_code: Option<i32>,
}

pub async fn simulate_stk_completion(
    State(state): State<AppState>,
    Json(payload): Json<SimulateMpesaRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let receipt = format!("QHX{}A0K", Utc::now().timestamp_millis().to_string().chars().rev().take(5).collect::<String>());
    let result_code = payload.result_code.unwrap_or(0);
    let status = if result_code == 0 { "COMPLETED" } else { "FAILED" };

    sqlx::query(
        r#"
        UPDATE mpesa_transactions
        SET status = $1,
            result_code = $2,
            result_desc = 'The service request is processed successfully.',
            mpesa_receipt_number = $3,
            updated_at = NOW()
        WHERE checkout_request_id = $4
        "#,
    )
    .bind(status)
    .bind(result_code)
    .bind(&receipt)
    .bind(&payload.checkout_request_id)
    .execute(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "status": status,
        "mpesa_receipt_number": receipt,
        "checkout_request_id": payload.checkout_request_id
    })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/stkpush", post(initiate_stk_push))
        .route("/callback", post(handle_daraja_callback))
        .route("/status/:checkout_id", get(check_stk_status))
        .route("/simulate", post(simulate_stk_completion))
}
