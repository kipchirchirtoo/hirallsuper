use axum::{
    extract::{Query, State},
    routing::get,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::{AuthUser, MaybeAuthUser};
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Account {
    pub id: Uuid,
    pub account_code: String,
    pub account_name: String,
    pub account_type: String, // ASSET, LIABILITY, EQUITY, REVENUE, COGS, EXPENSE
    pub is_active: bool,
}

#[derive(Debug, Deserialize)]
pub struct RecordBranchExpenseRequest {
    pub branch_id: Option<Uuid>,
    pub expense_category: String,
    pub amount: BigDecimal,
    pub payee: String,
    pub receipt_attachment_url: Option<String>,
}

#[derive(Debug, sqlx::FromRow)]
struct IdRow {
    pub id: Uuid,
}

pub async fn list_chart_of_accounts(
    auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Account>>> {
    let accounts = sqlx::query_as::<_, Account>(
        r#"
        SELECT id, account_code, account_name, account_type, is_active
        FROM chart_of_accounts
        WHERE organization_id = $1
        ORDER BY account_code ASC
        "#,
    )
    .bind(auth.organization_id)
    .fetch_all(&state.pool().await)
    .await?;

    Ok(Json(accounts))
}

pub async fn record_branch_expense(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<RecordBranchExpenseRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;

    let (org_id, user_id, branch_id) = if let Some(auth) = maybe_auth.0 {
        (auth.organization_id, Some(auth.user_id), payload.branch_id.unwrap_or(auth.organization_id))
    } else {
        let def_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap());

        let bid = if let Some(b) = payload.branch_id {
            b
        } else {
            sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM branches WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
            )
            .bind(def_org)
            .fetch_optional(&pool)
            .await?
            .unwrap_or_else(|| Uuid::parse_str("331b6fe8-1430-4bd4-be23-d4d62a67eab7").unwrap())
        };

        let uid = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM users WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
        )
        .bind(def_org)
        .fetch_optional(&pool)
        .await?;

        (def_org, uid, bid)
    };

    let expense_row = sqlx::query_as::<_, IdRow>(
        r#"
        INSERT INTO branch_expenses (
            organization_id, branch_id, expense_category, amount, payee,
            receipt_attachment_url, paid_by, status
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'APPROVED')
        RETURNING id
        "#,
    )
    .bind(org_id)
    .bind(branch_id)
    .bind(&payload.expense_category)
    .bind(&payload.amount)
    .bind(&payload.payee)
    .bind(payload.receipt_attachment_url)
    .bind(user_id)
    .fetch_one(&pool)
    .await?;

    Ok(Json(serde_json::json!({
        "status": "recorded",
        "expense_id": expense_row.id,
        "amount": payload.amount,
        "payee": payload.payee
    })))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct ExpenseQuery {
    pub branch_id: Option<Uuid>,
    pub limit: Option<i64>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct ExpenseDetail {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub expense_category: String,
    pub amount: BigDecimal,
    pub payee: String,
    pub status: String,
    pub receipt_attachment_url: Option<String>,
    pub paid_by_name: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

pub async fn list_branch_expenses(
    Query(params): Query<ExpenseQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<ExpenseDetail>>> {
    let pool = state.pool().await;
    let limit = params.limit.unwrap_or(100).min(500);

    let expenses = if let Some(bid) = params.branch_id {
        sqlx::query_as::<_, ExpenseDetail>(
            r#"
            SELECT 
                e.id, e.organization_id, e.branch_id, e.expense_category, e.amount,
                e.payee, e.status, e.receipt_attachment_url,
                u.name AS paid_by_name,
                e.created_at
            FROM branch_expenses e
            LEFT JOIN users u ON e.paid_by = u.id
            WHERE e.branch_id = $1
            ORDER BY e.created_at DESC
            LIMIT $2
            "#
        )
        .bind(bid)
        .bind(limit)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, ExpenseDetail>(
            r#"
            SELECT 
                e.id, e.organization_id, e.branch_id, e.expense_category, e.amount,
                e.payee, e.status, e.receipt_attachment_url,
                u.name AS paid_by_name,
                e.created_at
            FROM branch_expenses e
            LEFT JOIN users u ON e.paid_by = u.id
            ORDER BY e.created_at DESC
            LIMIT $1
            "#
        )
        .bind(limit)
        .fetch_all(&pool)
        .await?
    };

    Ok(Json(expenses))
}

pub async fn get_financial_summary(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    #[derive(sqlx::FromRow)]
    struct SalesSummary {
        gross_sales: Option<BigDecimal>,
        tax_collected: Option<BigDecimal>,
        transaction_count: Option<i64>,
    }

    #[derive(sqlx::FromRow)]
    struct ExpenseSummary {
        total_expenses: Option<BigDecimal>,
    }

    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        let default_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&state.pool().await)
        .await?;
        default_org.unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let sales = sqlx::query_as::<_, SalesSummary>(
        r#"
        SELECT
            COALESCE(SUM(grand_total), 0)  AS gross_sales,
            COALESCE(SUM(tax_total), 0)    AS tax_collected,
            COUNT(*)                        AS transaction_count
        FROM sales
        WHERE organization_id = $1
          AND payment_status = 'PAID'
          AND (created_at::date = CURRENT_DATE OR created_at >= (NOW() - INTERVAL '24 hours'))
        "#,
    )
    .bind(org_id)
    .fetch_one(&state.pool().await)
    .await?;

    let expenses = sqlx::query_as::<_, ExpenseSummary>(
        r#"
        SELECT COALESCE(SUM(amount), 0) AS total_expenses
        FROM branch_expenses
        WHERE organization_id = $1
          AND (created_at::date = CURRENT_DATE OR created_at >= (NOW() - INTERVAL '24 hours'))
        "#,
    )
    .bind(org_id)
    .fetch_one(&state.pool().await)
    .await?;

    let gross  = sales.gross_sales.unwrap_or_default();
    let vat    = sales.tax_collected.unwrap_or_default();
    let exp    = expenses.total_expenses.unwrap_or_default();
    let net    = gross.clone() - vat.clone() - exp.clone();
    let count  = sales.transaction_count.unwrap_or(0);

    Ok(Json(serde_json::json!({
        "period": "today",
        "gross_sales":        gross.to_string(),
        "vat_collected":      vat.to_string(),
        "total_expenses":     exp.to_string(),
        "net_profit":         net.to_string(),
        "transaction_count":  count,
    })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/accounts", get(list_chart_of_accounts))
        .route("/expenses", get(list_branch_expenses).post(record_branch_expense))
        .route("/summary", get(get_financial_summary))
}
