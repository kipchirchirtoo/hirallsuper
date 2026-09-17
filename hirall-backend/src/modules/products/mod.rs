use axum::{
    extract::{Path, Query, State},
    routing::{get, post, put},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::BigDecimal;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::{AuthUser, MaybeAuthUser};
use crate::core::errors::{AppError, AppResult};
use crate::core::storage::PresignedUploadResponse;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Product {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub sku: String,
    pub name: String,
    pub barcode: Option<String>,
    #[sqlx(default)]
    pub barcodes: Option<Vec<String>>,
    pub category_id: Option<Uuid>,
    pub brand_id: Option<Uuid>,
    pub unit_id: Option<Uuid>,
    pub cost_price: BigDecimal,
    pub selling_price: BigDecimal,
    pub tax_rate: BigDecimal,
    pub track_stock: bool,
    pub allow_negative_stock: bool,
    pub status: String,
    #[sqlx(default)]
    pub current_stock: Option<BigDecimal>,  // live from stock_balances
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct ProductQuery {
    pub search: Option<String>,
    pub barcode: Option<String>,
    pub category_id: Option<Uuid>,
    pub organization_id: Option<Uuid>,
    pub branch_id: Option<Uuid>,
    pub all_branches: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct CreateProductRequest {
    pub sku: String,
    pub name: String,
    pub category_id: Option<Uuid>,
    pub brand_id: Option<Uuid>,
    pub unit_id: Option<Uuid>,
    pub cost_price: BigDecimal,
    pub selling_price: BigDecimal,
    pub tax_rate: Option<BigDecimal>,
    pub barcode: Option<String>,
    pub barcodes: Option<Vec<String>>,
    pub track_stock: Option<bool>,
    pub initial_stock: Option<BigDecimal>,
    pub branch_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct AddBarcodeRequest {
    pub barcode: String,
    pub is_primary: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct RequestUploadUrlRequest {
    pub file_extension: String,
    pub mime_type: String,
}

#[derive(Debug, Deserialize)]
pub struct AttachProductImageRequest {
    pub storage_key: String,
    pub url: String,
    pub mime_type: String,
    pub file_size: i64,
    pub is_primary: Option<bool>,
}

#[derive(Debug, sqlx::FromRow)]
struct IdRow {
    pub id: Uuid,
}

pub async fn list_products(
    maybe_auth: MaybeAuthUser,
    Query(params): Query<ProductQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Product>>> {
    let pool = state.pool().await;

    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else if let Some(oid) = params.organization_id {
        let exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM organizations WHERE id = $1)",
        )
        .bind(oid)
        .fetch_one(&pool)
        .await
        .unwrap_or(false);

        if exists {
            oid
        } else {
            sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
            )
            .fetch_optional(&pool)
            .await?
            .unwrap_or(oid)
        }
    } else {
        let default_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?;
        default_org.ok_or_else(|| AppError::NotFound("No active organization found".into()))?
    };

    let branch_id = if let Some(bid) = params.branch_id {
        Some(bid)
    } else if let Some(auth_bid) = maybe_auth.0.as_ref().and_then(|a| a.branch_id) {
        Some(auth_bid)
    } else if params.all_branches == Some(true) {
        None
    } else {
        // Default to organization's primary branch so stock balances remain strictly scoped to a branch
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM branches WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
        )
        .bind(org_id)
        .fetch_optional(&pool)
        .await
        .ok()
        .flatten()
    };

    let search_term = params.search.map(|s| format!("%{}%", s));

    let products = if let Some(barcode) = params.barcode {
        let normalized = barcode.replace('/', "7");
        if let Some(bid) = branch_id {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(sb.quantity, 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                JOIN product_barcodes b ON b.product_id = p.id
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.branch_id = $4
                WHERE (p.organization_id = $1 OR p.organization_id IN (SELECT id FROM organizations WHERE status = 'ACTIVE'))
                  AND (b.barcode = $2 OR b.barcode = $3 OR p.sku = $2 OR p.sku = $3)
                  AND p.status = 'ACTIVE'
                ORDER BY p.name ASC
                "#,
            )
            .bind(org_id)
            .bind(&barcode)
            .bind(&normalized)
            .bind(bid)
            .fetch_all(&pool)
            .await?
        } else {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(SUM(sb.quantity), 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                JOIN product_barcodes b ON b.product_id = p.id
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.organization_id = p.organization_id
                WHERE (p.organization_id = $1 OR p.organization_id IN (SELECT id FROM organizations WHERE status = 'ACTIVE'))
                  AND (b.barcode = $2 OR b.barcode = $3 OR p.sku = $2 OR p.sku = $3)
                  AND p.status = 'ACTIVE'
                GROUP BY p.id, b.barcode
                ORDER BY p.name ASC
                "#,
            )
            .bind(org_id)
            .bind(&barcode)
            .bind(&normalized)
            .fetch_all(&pool)
            .await?
        }
    } else if let Some(term) = search_term {
        if let Some(bid) = branch_id {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(sb.quantity, 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                LEFT JOIN product_barcodes b ON b.product_id = p.id AND b.is_primary = true
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.branch_id = $3
                WHERE p.organization_id = $1 AND p.status = 'ACTIVE' AND (p.name ILIKE $2 OR p.sku ILIKE $2 OR b.barcode ILIKE $2)
                ORDER BY p.name ASC
                LIMIT 200
                "#,
            )
            .bind(org_id)
            .bind(term)
            .bind(bid)
            .fetch_all(&pool)
            .await?
        } else {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(SUM(sb.quantity), 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                LEFT JOIN product_barcodes b ON b.product_id = p.id AND b.is_primary = true
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.organization_id = p.organization_id
                WHERE p.organization_id = $1 AND p.status = 'ACTIVE' AND (p.name ILIKE $2 OR p.sku ILIKE $2 OR b.barcode ILIKE $2)
                GROUP BY p.id, b.barcode
                ORDER BY p.name ASC
                LIMIT 200
                "#,
            )
            .bind(org_id)
            .bind(term)
            .fetch_all(&pool)
            .await?
        }
    } else {
        if let Some(bid) = branch_id {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(sb.quantity, 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                LEFT JOIN product_barcodes b ON b.product_id = p.id AND b.is_primary = true
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.branch_id = $2
                WHERE p.organization_id = $1 AND p.status = 'ACTIVE'
                ORDER BY p.name ASC
                LIMIT 5000
                "#,
            )
            .bind(org_id)
            .bind(bid)
            .fetch_all(&pool)
            .await?
        } else {
            sqlx::query_as::<_, Product>(
                r#"
                SELECT p.id, p.organization_id, p.sku, p.name, b.barcode, p.category_id, p.brand_id, p.unit_id,
                       p.cost_price, p.selling_price, p.tax_rate, p.track_stock, p.allow_negative_stock,
                       p.status, COALESCE(SUM(sb.quantity), 0) AS current_stock, p.created_at, p.updated_at
                FROM products p
                LEFT JOIN product_barcodes b ON b.product_id = p.id AND b.is_primary = true
                LEFT JOIN stock_balances sb ON sb.product_id = p.id AND sb.organization_id = p.organization_id
                WHERE p.organization_id = $1 AND p.status = 'ACTIVE'
                GROUP BY p.id, b.barcode
                ORDER BY p.name ASC
                LIMIT 5000
                "#,
            )
            .bind(org_id)
            .fetch_all(&pool)
            .await?
        }
    };

    Ok(Json(products))
}

pub async fn create_product(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreateProductRequest>,
) -> AppResult<Json<Product>> {
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

    let tax_rate = payload.tax_rate.unwrap_or_else(|| BigDecimal::from(0));
    let track_stock = payload.track_stock.unwrap_or(true);

    let mut product = sqlx::query_as::<_, Product>(
        r#"
        INSERT INTO products (
            organization_id, sku, name, category_id, brand_id, unit_id,
            cost_price, selling_price, tax_rate, track_stock, allow_negative_stock, status
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, false, 'ACTIVE')
        RETURNING id, organization_id, sku, name, NULL as barcode, category_id, brand_id, unit_id,
                  cost_price, selling_price, tax_rate, track_stock, allow_negative_stock,
                  status, created_at, updated_at
        "#,
    )
    .bind(org_id)
    .bind(&payload.sku)
    .bind(&payload.name)
    .bind(payload.category_id)
    .bind(payload.brand_id)
    .bind(payload.unit_id)
    .bind(&payload.cost_price)
    .bind(&payload.selling_price)
    .bind(tax_rate)
    .bind(track_stock)
    .fetch_one(&mut *tx)
    .await?;

    // Collect all barcodes
    let mut all_barcodes: Vec<String> = Vec::new();
    if let Some(b) = payload.barcode {
        let c = b.replace('/', "7").trim().to_string();
        if !c.is_empty() && !all_barcodes.contains(&c) {
            all_barcodes.push(c);
        }
    }
    if let Some(b_list) = payload.barcodes {
        for b in b_list {
            let c = b.replace('/', "7").trim().to_string();
            if !c.is_empty() && !all_barcodes.contains(&c) {
                all_barcodes.push(c);
            }
        }
    }

    for (i, bc) in all_barcodes.iter().enumerate() {
        let is_primary = i == 0;
        sqlx::query(
            r#"
            INSERT INTO product_barcodes (product_id, barcode, barcode_type, is_primary)
            VALUES ($1, $2, 'EAN13', $3)
            ON CONFLICT (product_id, barcode) DO NOTHING
            "#,
        )
        .bind(product.id)
        .bind(bc)
        .bind(is_primary)
        .execute(&mut *tx)
        .await?;
    }
    if !all_barcodes.is_empty() {
        product.barcode = Some(all_barcodes[0].clone());
        product.barcodes = Some(all_barcodes);
    }

    // Handle initial stock balance & movement
    let init_qty = payload.initial_stock.unwrap_or_else(|| BigDecimal::from(0));
    if init_qty > BigDecimal::from(0) {
        let branch_id = if let Some(bid) = payload.branch_id {
            bid
        } else {
            sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM branches WHERE organization_id = $1 ORDER BY created_at ASC LIMIT 1",
            )
            .bind(org_id)
            .fetch_optional(&mut *tx)
            .await?
            .unwrap_or_else(|| Uuid::parse_str("5309fdb8-4344-43eb-9b5b-e9cedd308470").unwrap())
        };

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
        .bind(branch_id)
        .bind(product.id)
        .bind(&init_qty)
        .fetch_one(&mut *tx)
        .await?;

        product.current_stock = Some(new_balance.clone());

        let total_cost = &init_qty * &payload.cost_price;
        sqlx::query(
            r#"
            INSERT INTO stock_movements (
                organization_id, branch_id, product_id, location_area, movement_type,
                quantity, balance_after, unit_cost, total_cost, reference_type, notes
            )
            VALUES ($1, $2, $3, 'SHOP_FLOOR', 'IN', $4, $5, $6, $7, 'INITIAL_STOCK', 'Initial registration stock')
            "#,
        )
        .bind(org_id)
        .bind(branch_id)
        .bind(product.id)
        .bind(&init_qty)
        .bind(&new_balance)
        .bind(&payload.cost_price)
        .bind(&total_cost)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    Ok(Json(product))
}

pub async fn add_barcode(
    Path(product_id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<AddBarcodeRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let clean = payload.barcode.replace('/', "7").trim().to_string();
    if clean.is_empty() {
        return Err(AppError::BadRequest("Barcode cannot be empty".into()));
    }
    let is_primary = payload.is_primary.unwrap_or(false);

    let res = sqlx::query(
        r#"
        INSERT INTO product_barcodes (product_id, barcode, barcode_type, is_primary)
        VALUES ($1, $2, 'EAN13', $3)
        ON CONFLICT (product_id, barcode) DO NOTHING
        "#,
    )
    .bind(product_id)
    .bind(&clean)
    .bind(is_primary)
    .execute(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "success": true,
        "product_id": product_id,
        "barcode": clean,
        "rows_affected": res.rows_affected()
    })))
}

pub async fn get_upload_url(
    _auth: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<RequestUploadUrlRequest>,
) -> AppResult<Json<PresignedUploadResponse>> {
    let presigned = state
        .storage
        .generate_presigned_upload_url("products", &payload.file_extension, &payload.mime_type)
        .await?;

    Ok(Json(presigned))
}

pub async fn attach_image(
    _auth: AuthUser,
    Path(product_id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<AttachProductImageRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let product_exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM products WHERE id = $1)",
    )
    .bind(product_id)
    .fetch_one(&state.pool().await)
    .await?;

    if !product_exists {
        return Err(AppError::NotFound("Product not found".into()));
    }

    let is_primary = payload.is_primary.unwrap_or(false);

    let img_row = sqlx::query_as::<_, IdRow>(
        r#"
        INSERT INTO product_images (product_id, storage_key, url, mime_type, file_size, is_primary)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id
        "#,
    )
    .bind(product_id)
    .bind(&payload.storage_key)
    .bind(&payload.url)
    .bind(&payload.mime_type)
    .bind(payload.file_size)
    .bind(is_primary)
    .fetch_one(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "id": img_row.id,
        "product_id": product_id,
        "url": payload.url,
        "storage_key": payload.storage_key
    })))
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct UpdateProductRequest {
    pub name: Option<String>,
    pub sku: Option<String>,
    pub category_id: Option<Uuid>,
    pub brand_id: Option<Uuid>,
    pub unit_id: Option<Uuid>,
    pub cost_price: Option<BigDecimal>,
    pub selling_price: Option<BigDecimal>,
    pub tax_rate: Option<BigDecimal>,
    pub track_stock: Option<bool>,
    pub allow_negative_stock: Option<bool>,
    pub status: Option<String>,
}

pub async fn update_product(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<UpdateProductRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;
    let mut tx = pool.begin().await?;

    let existing = sqlx::query_as::<_, (String, BigDecimal, BigDecimal, BigDecimal, String)>(
        "SELECT name, cost_price, selling_price, tax_rate, status FROM products WHERE id = $1"
    )
    .bind(id)
    .fetch_optional(&mut *tx)
    .await?;

    let (old_name, old_cost, old_price, old_tax, old_status) = match existing {
        Some(row) => row,
        None => return Err(AppError::NotFound("Product not found".into())),
    };

    let name = payload.name.unwrap_or(old_name);
    let cost = payload.cost_price.unwrap_or(old_cost);
    let price = payload.selling_price.unwrap_or(old_price);
    let tax = payload.tax_rate.unwrap_or(old_tax);
    let status = payload.status.unwrap_or(old_status);

    sqlx::query(
        r#"
        UPDATE products
        SET name = $1, cost_price = $2, selling_price = $3, tax_rate = $4, status = $5, updated_at = NOW()
        WHERE id = $6
        "#
    )
    .bind(name)
    .bind(cost)
    .bind(price)
    .bind(tax)
    .bind(status)
    .bind(id)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    Ok(Json(serde_json::json!({ "id": id, "success": true })))
}

pub async fn delete_product(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;
    sqlx::query("UPDATE products SET status = 'INACTIVE', updated_at = NOW() WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await?;
    Ok(Json(serde_json::json!({ "id": id, "deleted": true })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(list_products).post(create_product))
        .route("/:id", put(update_product).delete(delete_product))
        .route("/upload-url", post(get_upload_url))
        .route("/:id/images", post(attach_image))
        .route("/:id/barcodes", post(add_barcode))
}
