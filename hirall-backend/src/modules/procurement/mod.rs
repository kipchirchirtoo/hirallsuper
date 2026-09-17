use axum::{
    extract::{Path, Query, State},
    routing::{get, put},
    Json, Router,
};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use std::str::FromStr;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::MaybeAuthUser;
use crate::core::errors::{AppError, AppResult};

// ============================================================================
// 1. SUPPLIERS MODELS & HANDLERS
// ============================================================================

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Supplier {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub code: String,
    pub name: String,
    pub tax_pin: Option<String>,
    pub contact_person: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub address: Option<String>,
    pub payment_terms: String,
    pub credit_limit: Option<BigDecimal>,
    pub lead_time_days: i32,
    pub delivery_accuracy_score: Option<BigDecimal>,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct SupplierQuery {
    pub organization_id: Option<Uuid>,
    pub search: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateSupplierRequest {
    pub code: Option<String>,
    pub name: String,
    pub tax_pin: Option<String>,
    pub contact_person: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub address: Option<String>,
    pub payment_terms: Option<String>,
    pub lead_time_days: Option<i32>,
}

pub async fn list_suppliers(
    maybe_auth: MaybeAuthUser,
    Query(params): Query<SupplierQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Supplier>>> {
    let pool = state.pool().await;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else if let Some(oid) = params.organization_id {
        oid
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let suppliers = if let Some(ref q) = params.search {
        let pattern = format!("%{}%", q.to_lowercase());
        sqlx::query_as::<_, Supplier>(
            r#"
            SELECT id, organization_id, code, name, tax_pin, contact_person, phone, email,
                   address, payment_terms, credit_limit, lead_time_days, delivery_accuracy_score,
                   status, created_at
            FROM suppliers
            WHERE organization_id = $1 
              AND (LOWER(name) LIKE $2 OR LOWER(code) LIKE $2 OR (tax_pin IS NOT NULL AND LOWER(tax_pin) LIKE $2))
            ORDER BY created_at DESC
            "#,
        )
        .bind(org_id)
        .bind(pattern)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, Supplier>(
            r#"
            SELECT id, organization_id, code, name, tax_pin, contact_person, phone, email,
                   address, payment_terms, credit_limit, lead_time_days, delivery_accuracy_score,
                   status, created_at
            FROM suppliers
            WHERE organization_id = $1
            ORDER BY created_at DESC
            "#,
        )
        .bind(org_id)
        .fetch_all(&pool)
        .await?
    };

    Ok(Json(suppliers))
}

pub async fn create_supplier(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreateSupplierRequest>,
) -> AppResult<Json<Supplier>> {
    let pool = state.pool().await;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let count = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM suppliers WHERE organization_id = $1",
    )
    .bind(org_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    let code = payload.code.unwrap_or_else(|| format!("SUP-{:04}", count + 1));
    let payment_terms = payload.payment_terms.unwrap_or_else(|| "NET_30".into());
    let lead_time_days = payload.lead_time_days.unwrap_or(3);

    let supplier = sqlx::query_as::<_, Supplier>(
        r#"
        INSERT INTO suppliers (
            organization_id, code, name, tax_pin, contact_person, phone, email,
            address, payment_terms, credit_limit, lead_time_days, status
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0.0, $10, 'ACTIVE')
        ON CONFLICT (organization_id, code) 
        DO UPDATE SET
            name = EXCLUDED.name,
            tax_pin = EXCLUDED.tax_pin,
            contact_person = EXCLUDED.contact_person,
            phone = EXCLUDED.phone,
            email = EXCLUDED.email,
            address = EXCLUDED.address,
            payment_terms = EXCLUDED.payment_terms,
            lead_time_days = EXCLUDED.lead_time_days
        RETURNING id, organization_id, code, name, tax_pin, contact_person, phone, email,
                  address, payment_terms, credit_limit, lead_time_days, delivery_accuracy_score,
                  status, created_at
        "#,
    )
    .bind(org_id)
    .bind(code)
    .bind(payload.name.trim())
    .bind(payload.tax_pin.map(|s| s.trim().to_uppercase()))
    .bind(payload.contact_person.map(|s| s.trim().to_string()))
    .bind(payload.phone.map(|s| s.trim().to_string()))
    .bind(payload.email.map(|s| s.trim().to_string()))
    .bind(payload.address.map(|s| s.trim().to_string()))
    .bind(payment_terms)
    .bind(lead_time_days)
    .fetch_one(&pool)
    .await?;

    Ok(Json(supplier))
}

// ============================================================================
// 2. PURCHASE ORDERS MODELS & HANDLERS
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct PurchaseOrderResponse {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub supplier_id: Uuid,
    pub supplier_name: String,
    pub po_number: String,
    pub status: String,
    pub order_date: String,
    pub expected_delivery_date: Option<String>,
    pub subtotal: BigDecimal,
    pub tax_total: BigDecimal,
    pub grand_total: BigDecimal,
    pub notes: Option<String>,
    pub items: Vec<PurchaseOrderItemResponse>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PurchaseOrderItemResponse {
    pub id: Uuid,
    pub product_id: Uuid,
    pub product_name: String,
    pub sku: String,
    pub quantity_ordered: BigDecimal,
    pub quantity_received: BigDecimal,
    pub unit_cost: BigDecimal,
    pub tax_rate: BigDecimal,
    pub total_cost: BigDecimal,
}

#[derive(Debug, Deserialize)]
pub struct PurchaseOrderQuery {
    pub organization_id: Option<Uuid>,
    pub branch_id: Option<Uuid>,
    #[allow(dead_code)]
    pub status: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreatePurchaseOrderRequest {
    pub branch_id: Option<Uuid>,
    pub supplier_id: Option<Uuid>,
    pub supplier_name: Option<String>,
    pub po_number: Option<String>,
    pub expected_delivery_date: Option<String>,
    pub notes: Option<String>,
    pub items: Vec<CreatePoItemRequest>,
}

#[derive(Debug, Deserialize)]
pub struct CreatePoItemRequest {
    pub product_id: Option<Uuid>,
    pub sku: Option<String>,
    pub name: Option<String>,
    pub quantity: BigDecimal,
    pub unit_cost: BigDecimal,
    pub tax_rate: Option<BigDecimal>,
}

pub async fn list_purchase_orders(
    maybe_auth: MaybeAuthUser,
    Query(params): Query<PurchaseOrderQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<PurchaseOrderResponse>>> {
    let pool = state.pool().await;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else if let Some(oid) = params.organization_id {
        oid
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    #[derive(sqlx::FromRow)]
    struct PoRow {
        id: Uuid,
        organization_id: Uuid,
        branch_id: Uuid,
        supplier_id: Uuid,
        supplier_name: String,
        po_number: String,
        status: String,
        order_date: NaiveDate,
        expected_delivery_date: Option<NaiveDate>,
        subtotal: BigDecimal,
        tax_total: BigDecimal,
        grand_total: BigDecimal,
        notes: Option<String>,
        created_at: DateTime<Utc>,
    }

    let po_rows = if let Some(bid) = params.branch_id {
        sqlx::query_as::<_, PoRow>(
            r#"
            SELECT po.id, po.organization_id, po.branch_id, po.supplier_id,
                   s.name AS supplier_name, po.po_number, po.status, po.order_date,
                   po.expected_delivery_date, po.subtotal, po.tax_total, po.grand_total,
                   po.notes, po.created_at
            FROM purchase_orders po
            JOIN suppliers s ON s.id = po.supplier_id
            WHERE po.organization_id = $1 AND po.branch_id = $2
            ORDER BY po.created_at DESC
            "#,
        )
        .bind(org_id)
        .bind(bid)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, PoRow>(
            r#"
            SELECT po.id, po.organization_id, po.branch_id, po.supplier_id,
                   s.name AS supplier_name, po.po_number, po.status, po.order_date,
                   po.expected_delivery_date, po.subtotal, po.tax_total, po.grand_total,
                   po.notes, po.created_at
            FROM purchase_orders po
            JOIN suppliers s ON s.id = po.supplier_id
            WHERE po.organization_id = $1
            ORDER BY po.created_at DESC
            "#,
        )
        .bind(org_id)
        .fetch_all(&pool)
        .await?
    };

    #[derive(sqlx::FromRow)]
    struct ItemRow {
        #[allow(dead_code)]
        id: Uuid,
        #[allow(dead_code)]
        po_id: Uuid,
        product_id: Uuid,
        product_name: String,
        sku: String,
        quantity_ordered: BigDecimal,
        quantity_received: BigDecimal,
        unit_cost: BigDecimal,
        tax_rate: BigDecimal,
        total_cost: BigDecimal,
    }

    let mut result = Vec::new();

    for row in po_rows {
        let items = sqlx::query_as::<_, ItemRow>(
            r#"
            SELECT poi.id, poi.po_id, poi.product_id, p.name AS product_name, p.sku,
                   poi.quantity_ordered, poi.quantity_received, poi.unit_cost,
                   poi.tax_rate, poi.total_cost
            FROM purchase_order_items poi
            JOIN products p ON p.id = poi.product_id
            WHERE poi.po_id = $1
            "#,
        )
        .bind(row.id)
        .fetch_all(&pool)
        .await?;

        result.push(PurchaseOrderResponse {
            id: row.id,
            organization_id: row.organization_id,
            branch_id: row.branch_id,
            supplier_id: row.supplier_id,
            supplier_name: row.supplier_name,
            po_number: row.po_number,
            status: row.status,
            order_date: row.order_date.format("%d %b %Y").to_string(),
            expected_delivery_date: row.expected_delivery_date.map(|d| d.format("%d %b %Y").to_string()),
            subtotal: row.subtotal,
            tax_total: row.tax_total,
            grand_total: row.grand_total,
            notes: row.notes,
            items: items
                .into_iter()
                .map(|i| PurchaseOrderItemResponse {
                    id: i.id,
                    product_id: i.product_id,
                    product_name: i.product_name,
                    sku: i.sku,
                    quantity_ordered: i.quantity_ordered,
                    quantity_received: i.quantity_received,
                    unit_cost: i.unit_cost,
                    tax_rate: i.tax_rate,
                    total_cost: i.total_cost,
                })
                .collect(),
            created_at: row.created_at,
        });
    }

    Ok(Json(result))
}

pub async fn create_purchase_order(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreatePurchaseOrderRequest>,
) -> AppResult<Json<PurchaseOrderResponse>> {
    let pool = state.pool().await;
    let mut tx = pool.begin().await?;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&mut *tx)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let branch_id = if let Some(bid) = payload.branch_id {
        bid
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM branches WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
        )
        .bind(org_id)
        .fetch_optional(&mut *tx)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("331b6fe8-1430-4bd4-be23-d4d62a67eab7").unwrap())
    };

    // Find or create supplier
    let (supplier_id, supplier_name) = if let Some(sid) = payload.supplier_id {
        let name = sqlx::query_scalar::<_, String>("SELECT name FROM suppliers WHERE id = $1")
            .bind(sid)
            .fetch_optional(&mut *tx)
            .await?
            .unwrap_or_else(|| "Local Vendor".into());
        (sid, name)
    } else if let Some(ref name) = payload.supplier_name {
        let existing = sqlx::query_as::<_, (Uuid, String)>(
            "SELECT id, name FROM suppliers WHERE organization_id = $1 AND LOWER(name) = LOWER($2) LIMIT 1",
        )
        .bind(org_id)
        .bind(name.trim())
        .fetch_optional(&mut *tx)
        .await?;

        if let Some(s) = existing {
            s
        } else {
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM suppliers WHERE organization_id = $1",
            )
            .bind(org_id)
            .fetch_one(&mut *tx)
            .await
            .unwrap_or(0);

            let code = format!("SUP-{:04}", count + 1);
            let new_sup = sqlx::query_as::<_, (Uuid, String)>(
                r#"
                INSERT INTO suppliers (organization_id, code, name, payment_terms, lead_time_days, status)
                VALUES ($1, $2, $3, 'NET_30', 3, 'ACTIVE')
                RETURNING id, name
                "#,
            )
            .bind(org_id)
            .bind(code)
            .bind(name.trim())
            .fetch_one(&mut *tx)
            .await?;
            new_sup
        }
    } else {
        return Err(AppError::BadRequest("Supplier is required".into()));
    };

    let po_number = payload.po_number.unwrap_or_else(|| {
        let now = Utc::now();
        format!("PO-{}-{:04}", now.format("%Y%m%d"), (now.timestamp_subsec_millis() % 9000) + 1000)
    });

    let expected_date = payload
        .expected_delivery_date
        .as_deref()
        .and_then(|d| NaiveDate::parse_from_str(d, "%Y-%m-%d").ok());

    let mut subtotal = BigDecimal::from(0);
    let mut tax_total = BigDecimal::from(0);
    let mut resolved_items: Vec<(Uuid, String, String, BigDecimal, BigDecimal, BigDecimal, BigDecimal)> = Vec::new();

    for item in payload.items {
        let (prod_id, prod_name, prod_sku) = if let Some(pid) = item.product_id {
            let p = sqlx::query_as::<_, (Uuid, String, String)>(
                "SELECT id, name, sku FROM products WHERE id = $1",
            )
            .bind(pid)
            .fetch_optional(&mut *tx)
            .await?;
            if let Some(res) = p {
                res
            } else {
                continue;
            }
        } else {
            let p_by_sku = if let Some(ref sku) = item.sku {
                sqlx::query_as::<_, (Uuid, String, String)>(
                    "SELECT id, name, sku FROM products WHERE organization_id = $1 AND UPPER(sku) = UPPER($2) LIMIT 1",
                )
                .bind(org_id)
                .bind(sku.trim())
                .fetch_optional(&mut *tx)
                .await?
            } else {
                None
            };

            if let Some(res) = p_by_sku {
                res
            } else if let Some(ref name) = item.name {
                let p_by_name = sqlx::query_as::<_, (Uuid, String, String)>(
                    "SELECT id, name, sku FROM products WHERE organization_id = $1 AND (LOWER(name) = LOWER($2) OR LOWER(name) LIKE LOWER($3)) LIMIT 1",
                )
                .bind(org_id)
                .bind(name.trim())
                .bind(format!("%{}%", name.trim()))
                .fetch_optional(&mut *tx)
                .await?;

                if let Some(res) = p_by_name {
                    res
                } else {
                    let sku = item.sku.clone().unwrap_or_else(|| format!("SKU-{:04}", (Utc::now().timestamp_subsec_millis() % 9000) + 1000));
                    let new_p = sqlx::query_as::<_, (Uuid, String, String)>(
                        r#"
                        INSERT INTO products (organization_id, sku, name, selling_price, cost_price, tax_rate, status)
                        VALUES ($1, $2, $3, $4 * 1.25, $4, 0.1600, 'ACTIVE')
                        RETURNING id, name, sku
                        "#,
                    )
                    .bind(org_id)
                    .bind(sku)
                    .bind(name.trim())
                    .bind(&item.unit_cost)
                    .fetch_one(&mut *tx)
                    .await?;
                    new_p
                }
            } else {
                continue;
            }
        };

        let tax_rate = item.tax_rate.unwrap_or_else(|| BigDecimal::from_str("0.1600").unwrap());
        let line_cost = &item.quantity * &item.unit_cost;
        let line_tax = &line_cost * &tax_rate;

        subtotal += &line_cost;
        tax_total += &line_tax;

        resolved_items.push((
            prod_id,
            prod_name,
            prod_sku,
            item.quantity,
            item.unit_cost,
            tax_rate,
            line_cost,
        ));
    }

    let grand_total = &subtotal + &tax_total;

    #[derive(sqlx::FromRow)]
    struct CreatedPo {
        id: Uuid,
        organization_id: Uuid,
        branch_id: Uuid,
        supplier_id: Uuid,
        po_number: String,
        status: String,
        order_date: NaiveDate,
        expected_delivery_date: Option<NaiveDate>,
        subtotal: BigDecimal,
        tax_total: BigDecimal,
        grand_total: BigDecimal,
        notes: Option<String>,
        created_at: DateTime<Utc>,
    }

    let created_po = sqlx::query_as::<_, CreatedPo>(
        r#"
        INSERT INTO purchase_orders (
            organization_id, branch_id, supplier_id, po_number, status, order_date,
            expected_delivery_date, subtotal, tax_total, grand_total, notes
        )
        VALUES ($1, $2, $3, $4, 'SUBMITTED', CURRENT_DATE, $5, $6, $7, $8, $9)
        RETURNING id, organization_id, branch_id, supplier_id, po_number, status,
                  order_date, expected_delivery_date, subtotal, tax_total, grand_total,
                  notes, created_at
        "#,
    )
    .bind(org_id)
    .bind(branch_id)
    .bind(supplier_id)
    .bind(po_number)
    .bind(expected_date)
    .bind(&subtotal)
    .bind(&tax_total)
    .bind(&grand_total)
    .bind(payload.notes)
    .fetch_one(&mut *tx)
    .await?;

    let mut output_items = Vec::new();

    for (p_id, p_name, p_sku, qty, u_cost, t_rate, l_cost) in resolved_items {
        let item_id = sqlx::query_scalar::<_, Uuid>(
            r#"
            INSERT INTO purchase_order_items (
                po_id, product_id, quantity_ordered, quantity_received,
                unit_cost, tax_rate, total_cost
            )
            VALUES ($1, $2, $3, 0, $4, $5, $6)
            RETURNING id
            "#,
        )
        .bind(created_po.id)
        .bind(p_id)
        .bind(&qty)
        .bind(&u_cost)
        .bind(&t_rate)
        .bind(&l_cost)
        .fetch_one(&mut *tx)
        .await?;

        output_items.push(PurchaseOrderItemResponse {
            id: item_id,
            product_id: p_id,
            product_name: p_name,
            sku: p_sku,
            quantity_ordered: qty,
            quantity_received: BigDecimal::from(0),
            unit_cost: u_cost,
            tax_rate: t_rate,
            total_cost: l_cost,
        });
    }

    tx.commit().await?;

    Ok(Json(PurchaseOrderResponse {
        id: created_po.id,
        organization_id: created_po.organization_id,
        branch_id: created_po.branch_id,
        supplier_id: created_po.supplier_id,
        supplier_name,
        po_number: created_po.po_number,
        status: created_po.status,
        order_date: created_po.order_date.format("%d %b %Y").to_string(),
        expected_delivery_date: created_po.expected_delivery_date.map(|d| d.format("%d %b %Y").to_string()),
        subtotal: created_po.subtotal,
        tax_total: created_po.tax_total,
        grand_total: created_po.grand_total,
        notes: created_po.notes,
        items: output_items,
        created_at: created_po.created_at,
    }))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct UpdateSupplierRequest {
    pub name: Option<String>,
    pub contact_person: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub address: Option<String>,
    pub tax_pin: Option<String>,
    pub payment_terms: Option<String>,
    pub lead_time_days: Option<i32>,
    pub status: Option<String>,
}

pub async fn update_supplier(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<UpdateSupplierRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;

    let existing = sqlx::query_as::<_, (String, Option<String>, Option<String>, Option<String>, Option<String>, Option<String>, String, i32, String)>(
        "SELECT name, contact_person, phone, email, address, tax_pin, payment_terms, lead_time_days, status FROM suppliers WHERE id = $1"
    )
    .bind(id)
    .fetch_optional(&pool)
    .await?;

    let (old_name, old_contact, old_phone, old_email, old_address, old_tax, old_terms, old_lead, old_status) = match existing {
        Some(s) => s,
        None => return Err(AppError::NotFound("Supplier not found".into())),
    };

    let name = payload.name.unwrap_or(old_name);
    let contact = payload.contact_person.or(old_contact);
    let phone = payload.phone.or(old_phone);
    let email = payload.email.or(old_email);
    let address = payload.address.or(old_address);
    let tax = payload.tax_pin.or(old_tax);
    let terms = payload.payment_terms.unwrap_or(old_terms);
    let lead = payload.lead_time_days.unwrap_or(old_lead);
    let status = payload.status.unwrap_or(old_status);

    sqlx::query(
        r#"
        UPDATE suppliers
        SET name = $1, contact_person = $2, phone = $3, email = $4, address = $5,
            tax_pin = $6, payment_terms = $7, lead_time_days = $8, status = $9
        WHERE id = $10
        "#
    )
    .bind(name)
    .bind(contact)
    .bind(phone)
    .bind(email)
    .bind(address)
    .bind(tax)
    .bind(terms)
    .bind(lead)
    .bind(status)
    .bind(id)
    .execute(&pool)
    .await?;

    Ok(Json(serde_json::json!({ "id": id, "success": true })))
}

pub async fn delete_supplier(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;
    sqlx::query("UPDATE suppliers SET status = 'INACTIVE' WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await?;
    Ok(Json(serde_json::json!({ "id": id, "deleted": true })))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct GrnQuery {
    pub branch_id: Option<Uuid>,
    pub limit: Option<i64>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct GrnSummaryRow {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub supplier_id: Uuid,
    pub supplier_name: Option<String>,
    pub grn_number: String,
    pub supplier_delivery_note: Option<String>,
    pub supplier_invoice_number: Option<String>,
    pub status: String,
    pub total_items_received: i32,
    pub total_cost_received: BigDecimal,
    pub remarks: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub async fn list_grns(
    Query(params): Query<GrnQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<GrnSummaryRow>>> {
    let pool = state.pool().await;
    let limit = params.limit.unwrap_or(100).min(500);

    let grns = if let Some(bid) = params.branch_id {
        sqlx::query_as::<_, GrnSummaryRow>(
            r#"
            SELECT 
                g.id, g.organization_id, g.branch_id, g.supplier_id,
                s.name AS supplier_name,
                g.grn_number, g.supplier_delivery_note, g.supplier_invoice_number,
                g.status, g.total_items_received, g.total_cost_received, g.remarks,
                g.created_at
            FROM goods_received_notes g
            LEFT JOIN suppliers s ON g.supplier_id = s.id
            WHERE g.branch_id = $1
            ORDER BY g.created_at DESC
            LIMIT $2
            "#
        )
        .bind(bid)
        .bind(limit)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, GrnSummaryRow>(
            r#"
            SELECT 
                g.id, g.organization_id, g.branch_id, g.supplier_id,
                s.name AS supplier_name,
                g.grn_number, g.supplier_delivery_note, g.supplier_invoice_number,
                g.status, g.total_items_received, g.total_cost_received, g.remarks,
                g.created_at
            FROM goods_received_notes g
            LEFT JOIN suppliers s ON g.supplier_id = s.id
            ORDER BY g.created_at DESC
            LIMIT $1
            "#
        )
        .bind(limit)
        .fetch_all(&pool)
        .await?
    };

    Ok(Json(grns))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct CreateGrnItemRequest {
    pub product_id: Option<Uuid>,
    pub sku: Option<String>,
    pub name: Option<String>,
    pub quantity: BigDecimal,
    pub unit_cost: BigDecimal,
    pub batch_number: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateGrnRequest {
    pub branch_id: Option<Uuid>,
    pub supplier_id: Option<Uuid>,
    pub supplier_name: Option<String>,
    pub grn_number: Option<String>,
    pub supplier_delivery_note: Option<String>,
    pub supplier_invoice_number: Option<String>,
    pub remarks: Option<String>,
    pub items: Vec<CreateGrnItemRequest>,
}

pub async fn create_grn(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreateGrnRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let mut tx = state.pool().await.begin().await?;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&mut *tx)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let branch_id = if let Some(bid) = payload.branch_id {
        bid
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM branches WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
        )
        .bind(org_id)
        .fetch_optional(&mut *tx)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("331b6fe8-1430-4bd4-be23-d4d62a67eab7").unwrap())
    };

    let user_id = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM users WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
    )
    .bind(org_id)
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or_else(Uuid::new_v4);

    let supplier_id = if let Some(sid) = payload.supplier_id {
        sid
    } else if let Some(ref sname) = payload.supplier_name {
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM suppliers WHERE organization_id = $1 AND LOWER(name) = LOWER($2) LIMIT 1"
        )
        .bind(org_id)
        .bind(sname)
        .fetch_optional(&mut *tx)
        .await?;

        if let Some(sid) = existing {
            sid
        } else {
            let code = format!("SUP-{:03}", (Utc::now().timestamp_subsec_millis() % 900) + 100);
            sqlx::query_scalar::<_, Uuid>(
                "INSERT INTO suppliers (organization_id, code, name, status) VALUES ($1, $2, $3, 'ACTIVE') RETURNING id"
            )
            .bind(org_id)
            .bind(code)
            .bind(sname)
            .fetch_one(&mut *tx)
            .await?
        }
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM suppliers WHERE organization_id = $1 LIMIT 1"
        )
        .bind(org_id)
        .fetch_optional(&mut *tx)
        .await?
        .unwrap_or_else(Uuid::new_v4)
    };

    let grn_number = payload.grn_number.unwrap_or_else(|| {
        format!("GRN-{}-{}", Utc::now().format("%Y%m%d"), (Utc::now().timestamp_subsec_millis() % 9000) + 1000)
    });

    let mut total_cost = BigDecimal::from(0);
    let total_items = payload.items.len() as i32;

    for item in &payload.items {
        let line_total = &item.quantity * &item.unit_cost;
        total_cost += line_total;
    }

    let grn_id = sqlx::query_scalar::<_, Uuid>(
        r#"
        INSERT INTO goods_received_notes (
            organization_id, branch_id, supplier_id, grn_number,
            supplier_delivery_note, supplier_invoice_number, received_by,
            status, total_items_received, total_cost_received, remarks
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'COMPLETED', $8, $9, $10)
        RETURNING id
        "#
    )
    .bind(org_id)
    .bind(branch_id)
    .bind(supplier_id)
    .bind(&grn_number)
    .bind(payload.supplier_delivery_note)
    .bind(payload.supplier_invoice_number)
    .bind(user_id)
    .bind(total_items)
    .bind(&total_cost)
    .bind(payload.remarks)
    .fetch_one(&mut *tx)
    .await?;

    for item in payload.items {
        let prod_id = if let Some(pid) = item.product_id {
            pid
        } else if let Some(ref sku) = item.sku {
            let pid = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM products WHERE organization_id = $1 AND sku = $2 LIMIT 1"
            )
            .bind(org_id)
            .bind(sku)
            .fetch_optional(&mut *tx)
            .await?;
            pid.unwrap_or_else(Uuid::new_v4)
        } else {
            continue;
        };

        let line_total = &item.quantity * &item.unit_cost;

        sqlx::query(
            r#"
            INSERT INTO grn_items (
                grn_id, product_id, quantity_received, unit_cost, total_cost, batch_number
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            "#
        )
        .bind(grn_id)
        .bind(prod_id)
        .bind(&item.quantity)
        .bind(&item.unit_cost)
        .bind(&line_total)
        .bind(item.batch_number)
        .execute(&mut *tx)
        .await?;

        // Update branch stock balances atomically
        let new_balance = sqlx::query_scalar::<_, BigDecimal>(
            r#"
            INSERT INTO stock_balances (organization_id, branch_id, product_id, location_area, quantity, reserved_quantity, updated_at)
            VALUES ($1, $2, $3, 'SHOP_FLOOR', $4, 0, NOW())
            ON CONFLICT (branch_id, product_id, location_area)
            DO UPDATE SET
                quantity = stock_balances.quantity + EXCLUDED.quantity,
                updated_at = NOW()
            RETURNING quantity
            "#
        )
        .bind(org_id)
        .bind(branch_id)
        .bind(prod_id)
        .bind(&item.quantity)
        .fetch_one(&mut *tx)
        .await?;

        // Write stock movement
        sqlx::query(
            r#"
            INSERT INTO stock_movements (
                organization_id, branch_id, product_id, location_area, movement_type, quantity,
                balance_after, unit_cost, reference_type, reference_id, notes
            )
            VALUES ($1, $2, $3, 'SHOP_FLOOR', 'PURCHASE', $4, $5, $6, 'GRN', $7, 'Received via GRN')
            "#
        )
        .bind(org_id)
        .bind(branch_id)
        .bind(prod_id)
        .bind(&item.quantity)
        .bind(new_balance)
        .bind(&item.unit_cost)
        .bind(grn_id)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    Ok(Json(serde_json::json!({
        "id": grn_id,
        "grn_number": grn_number,
        "total_cost": total_cost,
        "status": "COMPLETED"
    })))
}

// Router builder for procurement
pub fn router() -> Router<AppState> {
    Router::new()
        .route("/suppliers", get(list_suppliers).post(create_supplier))
        .route("/suppliers/:id", put(update_supplier).delete(delete_supplier))
        .route("/purchase-orders", get(list_purchase_orders).post(create_purchase_order))
        .route("/grn", get(list_grns).post(create_grn))
}
