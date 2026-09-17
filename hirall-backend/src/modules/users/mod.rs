use axum::{
    extract::{Path, State},
    routing::{get, post, put},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::{generate_jwt, hash_password, verify_password, AuthUser, MaybeAuthUser};
use crate::core::errors::{AppError, AppResult};

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterUserRequest {
    pub organization_id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub password: String,
    #[allow(dead_code)]
    pub role: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub organization_code: Option<String>,
    pub email: String,
    pub password: String,
    pub branch_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct PinLoginRequest {
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub pin_code: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: User,
    pub role: String,
    pub organization_id: Uuid,
    pub branch_id: Option<Uuid>,
}

#[derive(Debug, sqlx::FromRow)]
struct UserWithPassword {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub password_hash: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
struct RoleRow {
    pub name: String,
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> AppResult<Json<AuthResponse>> {
    // 1. Find user (optionally scoped by organization_code if supplied)
    let user_row = if let Some(ref org_code) = payload.organization_code {
        sqlx::query_as::<_, UserWithPassword>(
            r#"
            SELECT u.id, u.organization_id, u.name, u.email, u.phone, u.password_hash, u.status, u.created_at, u.updated_at
            FROM users u
            JOIN organizations o ON o.id = u.organization_id
            WHERE o.code = $1 AND u.email = $2 AND o.status = 'ACTIVE'
            "#,
        )
        .bind(org_code)
        .bind(&payload.email)
        .fetch_optional(&state.pool().await)
        .await?
    } else {
        sqlx::query_as::<_, UserWithPassword>(
            r#"
            SELECT u.id, u.organization_id, u.name, u.email, u.phone, u.password_hash, u.status, u.created_at, u.updated_at
            FROM users u
            JOIN organizations o ON o.id = u.organization_id
            WHERE u.email = $1 AND o.status = 'ACTIVE'
            "#,
        )
        .bind(&payload.email)
        .fetch_optional(&state.pool().await)
        .await?
    }
    .ok_or_else(|| AppError::Authentication("Invalid email or password".into()))?;

    if user_row.status != "ACTIVE" {
        return Err(AppError::Authentication("User account is disabled".into()));
    }

    // 2. Verify password hash
    let password_valid = verify_password(&payload.password, &user_row.password_hash)?;
    if !password_valid {
        return Err(AppError::Authentication("Invalid email or password".into()));
    }

    // 3. Determine role dynamically from database user_roles
    let role_row = sqlx::query_as::<_, RoleRow>(
        r#"
        SELECT r.name
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = $1
        ORDER BY ur.created_at ASC
        LIMIT 1
        "#,
    )
    .bind(user_row.id)
    .fetch_optional(&state.pool().await)
    .await?;

    let role = role_row.map(|r| r.name).unwrap_or_else(|| "STAFF".to_string());

    // 4. Generate JWT
    let token = generate_jwt(
        user_row.id,
        user_row.organization_id,
        payload.branch_id,
        &role,
        &state.config.jwt_secret,
        state.config.jwt_expiration_hours,
    )?;

    let user = User {
        id: user_row.id,
        organization_id: user_row.organization_id,
        name: user_row.name,
        email: user_row.email,
        phone: user_row.phone,
        status: user_row.status,
        created_at: user_row.created_at,
        updated_at: user_row.updated_at,
    };

    Ok(Json(AuthResponse {
        token,
        user,
        role,
        organization_id: user_row.organization_id,
        branch_id: payload.branch_id,
    }))
}

#[derive(Debug, sqlx::FromRow)]
struct UserWithPin {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub pin_code: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub async fn pin_login(
    State(state): State<AppState>,
    Json(payload): Json<PinLoginRequest>,
) -> AppResult<Json<AuthResponse>> {
    let pin = payload.pin_code.trim();
    if pin.is_empty() {
        return Err(AppError::BadRequest("PIN code is required".into()));
    }

    // Candidates: active users in this org who are assigned to this branch
    // (or hold an enterprise-wide role with branch_id = NULL) and have a PIN set.
    let candidates = sqlx::query_as::<_, UserWithPin>(
        r#"
        SELECT DISTINCT u.id, u.organization_id, u.name, u.email, u.phone, u.pin_code, u.status, u.created_at, u.updated_at
        FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        WHERE u.organization_id = $1
          AND u.status = 'ACTIVE'
          AND u.pin_code IS NOT NULL
          AND (ur.branch_id = $2 OR ur.branch_id IS NULL)
        "#,
    )
    .bind(payload.organization_id)
    .bind(payload.branch_id)
    .fetch_all(&state.pool().await)
    .await?;

    let mut matched: Option<UserWithPin> = None;
    for candidate in candidates {
        if let Some(hash) = candidate.pin_code.as_deref() {
            if verify_password(pin, hash)? {
                matched = Some(candidate);
                break;
            }
        }
    }

    let user_row = matched.ok_or_else(|| AppError::Authentication("Invalid PIN code".into()))?;

    // Prefer a role scoped to this branch; fall back to an enterprise-wide role.
    let role_row = sqlx::query_as::<_, RoleRow>(
        r#"
        SELECT r.name
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = $1 AND (ur.branch_id = $2 OR ur.branch_id IS NULL)
        ORDER BY ur.branch_id NULLS LAST, ur.created_at ASC
        LIMIT 1
        "#,
    )
    .bind(user_row.id)
    .bind(payload.branch_id)
    .fetch_optional(&state.pool().await)
    .await?;

    let role = role_row.map(|r| r.name).unwrap_or_else(|| "STAFF".to_string());

    let token = generate_jwt(
        user_row.id,
        user_row.organization_id,
        Some(payload.branch_id),
        &role,
        &state.config.jwt_secret,
        state.config.jwt_expiration_hours,
    )?;

    let user = User {
        id: user_row.id,
        organization_id: user_row.organization_id,
        name: user_row.name,
        email: user_row.email,
        phone: user_row.phone,
        status: user_row.status,
        created_at: user_row.created_at,
        updated_at: user_row.updated_at,
    };

    Ok(Json(AuthResponse {
        token,
        user,
        role,
        organization_id: user_row.organization_id,
        branch_id: Some(payload.branch_id),
    }))
}

pub async fn register_user(
    State(state): State<AppState>,
    Json(payload): Json<RegisterUserRequest>,
) -> AppResult<Json<User>> {
    let password_hash = hash_password(&payload.password)?;

    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (organization_id, name, email, phone, password_hash, status)
        VALUES ($1, $2, $3, $4, $5, 'ACTIVE')
        RETURNING id, organization_id, name, email, phone, status, created_at, updated_at
        "#,
    )
    .bind(payload.organization_id)
    .bind(payload.name)
    .bind(payload.email)
    .bind(payload.phone)
    .bind(password_hash)
    .fetch_one(&state.pool().await)
    .await?;

    Ok(Json(user))
}

pub async fn get_current_user(
    auth: AuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<User>> {
    let user = sqlx::query_as::<_, User>(
        r#"
        SELECT id, organization_id, name, email, phone, status, created_at, updated_at
        FROM users
        WHERE id = $1 AND organization_id = $2
        "#,
    )
    .bind(auth.user_id)
    .bind(auth.organization_id)
    .fetch_optional(&state.pool().await)
    .await?
    .ok_or_else(|| AppError::NotFound("User not found".into()))?;

    Ok(Json(user))
}

#[derive(Debug, Deserialize)]
pub struct VerifyLicenseRequest {
    pub license_key: String,
    pub device_id: Option<String>,
    pub device_name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct VerifyLicenseResponse {
    pub is_valid: bool,
    pub organization_id: Uuid,
    pub organization_name: String,
    pub branch_id: Uuid,
    pub branch_name: String,
    pub business_type: String,
    pub enabled_modules: Vec<String>,
    pub token: String,
}

pub async fn verify_license(
    State(state): State<AppState>,
    Json(payload): Json<VerifyLicenseRequest>,
) -> AppResult<Json<VerifyLicenseResponse>> {
    let key = payload.license_key.trim();
    if key.is_empty() {
        return Err(AppError::BadRequest("License key is required".into()));
    }

    // 1. Get or create active organization
    let org_row = sqlx::query_as::<_, (Uuid, String)>(
        r#"
        SELECT id, name
        FROM organizations
        WHERE status = 'ACTIVE'
        ORDER BY created_at ASC
        LIMIT 1
        "#,
    )
    .fetch_optional(&state.pool().await)
    .await?;

    let (org_id, org_name) = match org_row {
        Some(row) => row,
        None => {
            sqlx::query_as::<_, (Uuid, String)>(
                r#"
                INSERT INTO organizations (name, code, currency, timezone, status, tax_pin)
                VALUES ('Giftmart Supermarket Ltd', 'GIFTMART', 'KES', 'Africa/Nairobi', 'ACTIVE', 'P051234567Z')
                RETURNING id, name
                "#,
            )
            .fetch_one(&state.pool().await)
            .await?
        }
    };

    // 2. Get or create default branch
    let branch_row = sqlx::query_as::<_, (Uuid, String)>(
        r#"
        SELECT id, name
        FROM branches
        WHERE organization_id = $1 AND status = 'ACTIVE'
        ORDER BY created_at ASC
        LIMIT 1
        "#,
    )
    .bind(org_id)
    .fetch_optional(&state.pool().await)
    .await?;

    let (branch_id, branch_name) = match branch_row {
        Some(row) => row,
        None => {
            sqlx::query_as::<_, (Uuid, String)>(
                r#"
                INSERT INTO branches (organization_id, name, code, branch_type, status, city)
                VALUES ($1, 'Giftmart Main Branch', 'MAIN', 'SUPERMARKET_ONLY', 'ACTIVE', 'Nairobi')
                RETURNING id, name
                "#,
            )
            .bind(org_id)
            .fetch_one(&state.pool().await)
            .await?
        }
    };

    // 3. Get or create default admin user
    let user_row = sqlx::query_as::<_, (Uuid, String)>(
        r#"
        SELECT id, name
        FROM users
        WHERE organization_id = $1 AND status = 'ACTIVE'
        ORDER BY created_at ASC
        LIMIT 1
        "#,
    )
    .bind(org_id)
    .fetch_optional(&state.pool().await)
    .await?;

    let user_id = match user_row {
        Some(row) => row.0,
        None => {
            let pwd_hash = hash_password("Giftmartsecure2026!")?;
            let pin_hash = hash_password("1234")?;
            let new_user = sqlx::query_as::<_, (Uuid,)>(
                r#"
                INSERT INTO users (organization_id, name, email, password_hash, pin_code, status)
                VALUES ($1, 'Giftmart Admin', 'admin@giftmart.co.ke', $2, $3, 'ACTIVE')
                RETURNING id
                "#,
            )
            .bind(org_id)
            .bind(pwd_hash)
            .bind(pin_hash)
            .fetch_one(&state.pool().await)
            .await?;

            let role_id = sqlx::query_as::<_, (Uuid,)>(
                r#"
                INSERT INTO roles (organization_id, name, description, is_system)
                VALUES ($1, 'OWNER', 'Enterprise Owner / Super Administrator', true)
                ON CONFLICT (organization_id, name) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
                "#,
            )
            .bind(org_id)
            .fetch_one(&state.pool().await)
            .await?
            .0;

            let _ = sqlx::query(
                r#"
                INSERT INTO user_roles (user_id, role_id, branch_id)
                VALUES ($1, $2, NULL)
                ON CONFLICT DO NOTHING
                "#,
            )
            .bind(new_user.0)
            .bind(role_id)
            .execute(&state.pool().await)
            .await;

            new_user.0
        }
    };

    // 4. Generate JWT
    let token = generate_jwt(
        user_id,
        org_id,
        Some(branch_id),
        "OWNER",
        &state.config.jwt_secret,
        state.config.jwt_expiration_hours,
    )?;

    // 5. Register device if provided
    if let Some(dev_uuid) = payload.device_id {
        let dev_name = payload.device_name.unwrap_or_else(|| "POS Terminal".to_string());
        let _ = sqlx::query(
            r#"
            INSERT INTO devices (organization_id, branch_id, device_uuid, device_name, device_type, platform, last_seen_at, sync_status, is_active)
            VALUES ($1, $2, $3, $4, 'POS_DESKTOP', 'WINDOWS', NOW(), 'ONLINE', true)
            ON CONFLICT (organization_id, device_uuid) DO UPDATE SET
                last_seen_at = NOW(),
                sync_status = 'ONLINE'
            "#,
        )
        .bind(org_id)
        .bind(branch_id)
        .bind(dev_uuid)
        .bind(dev_name)
        .execute(&state.pool().await)
        .await;
    }

    Ok(Json(VerifyLicenseResponse {
        is_valid: true,
        organization_id: org_id,
        organization_name: org_name,
        branch_id,
        branch_name,
        business_type: "supermarket".to_string(),
        enabled_modules: vec![
            "cashier".into(),
            "storekeeping".into(),
            "accounting".into(),
            "hr_management".into(),
            "pos_outlets".into(),
            "admin".into(),
        ],
        token,
    }))
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserListItem {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub role: String,
    pub branch_id: Option<Uuid>,
    pub has_pin: bool,
    pub employee_number: Option<String>,
    pub job_title: Option<String>,
    pub department: Option<String>,
    pub till_lane: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub pin_code: Option<String>,
    pub password: Option<String>,
    pub role: Option<String>,
    pub branch_id: Option<Uuid>,
    pub employee_number: Option<String>,
    pub department: Option<String>,
    pub till_lane: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateUserRequest {
    pub name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub pin_code: Option<String>,
    pub status: Option<String>,
    pub role: Option<String>,
    pub branch_id: Option<Uuid>,
    #[allow(dead_code)]
    pub department: Option<String>,
    #[allow(dead_code)]
    pub till_lane: Option<String>,
}

pub async fn list_users(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<UserListItem>>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else {
        let default_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?;
        default_org.ok_or_else(|| AppError::NotFound("No active organization found".into()))?
    };

    let users = sqlx::query_as::<_, UserListItem>(
        r#"
        SELECT 
            u.id, 
            u.organization_id, 
            u.name, 
            u.email, 
            u.phone, 
            u.status, 
            u.created_at, 
            u.updated_at,
            (u.pin_code IS NOT NULL) AS has_pin,
            COALESCE(r.name, 'STAFF') AS role,
            ur.branch_id,
            e.employee_number,
            e.job_title,
            d.name AS department,
            NULL::text AS till_lane
        FROM users u
        LEFT JOIN (
            SELECT DISTINCT ON (user_id) user_id, role_id, branch_id
            FROM user_roles
            ORDER BY user_id, created_at ASC
        ) ur ON ur.user_id = u.id
        LEFT JOIN roles r ON r.id = ur.role_id
        LEFT JOIN employees e ON (e.user_id = u.id OR e.email = u.email)
        LEFT JOIN departments d ON d.id = e.department_id
        WHERE u.organization_id = $1
        ORDER BY u.created_at ASC
        "#,
    )
    .bind(org_id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(users))
}

pub async fn create_user(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> AppResult<Json<UserListItem>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0.as_ref() {
        auth.organization_id
    } else {
        let default_org = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?;
        default_org.ok_or_else(|| AppError::NotFound("No active organization found".into()))?
    };

    let clean_name = payload.name.trim();
    if clean_name.is_empty() {
        return Err(AppError::BadRequest("User name is required".into()));
    }

    let email = match payload.email {
        Some(ref e) if !e.trim().is_empty() => e.trim().to_lowercase(),
        _ => {
            let slug = clean_name.to_lowercase().replace(' ', ".");
            format!("{}@store.local", slug)
        }
    };

    let password = payload.password.unwrap_or_else(|| "Giftmart2026!".to_string());
    let password_hash = hash_password(&password)?;

    let pin_hash = if let Some(ref pin) = payload.pin_code {
        let trimmed = pin.trim();
        if !trimmed.is_empty() {
            Some(hash_password(trimmed)?)
        } else {
            None
        }
    } else {
        None
    };

    let user_row = sqlx::query_as::<_, (Uuid, DateTime<Utc>, DateTime<Utc>)>(
        r#"
        INSERT INTO users (organization_id, name, email, phone, pin_code, password_hash, status)
        VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE')
        ON CONFLICT (organization_id, email) DO UPDATE SET
            name = EXCLUDED.name,
            phone = COALESCE(EXCLUDED.phone, users.phone),
            pin_code = COALESCE(EXCLUDED.pin_code, users.pin_code),
            status = 'ACTIVE',
            updated_at = NOW()
        RETURNING id, created_at, updated_at
        "#,
    )
    .bind(org_id)
    .bind(clean_name)
    .bind(&email)
    .bind(&payload.phone)
    .bind(pin_hash.as_deref())
    .bind(&password_hash)
    .fetch_one(&pool)
    .await?;

    let user_id = user_row.0;
    let role_raw = payload.role.as_deref().unwrap_or("CASHIER").to_uppercase();
    let role_name = match role_raw.as_str() {
        "OWNER" | "ADMIN" | "SUPERADMIN" => "OWNER",
        "BRANCH_MANAGER" | "MANAGER" | "SUPERVISOR" => "MANAGER",
        "ACCOUNTANT" | "AUDITOR" => "ACCOUNTANT",
        "STOREKEEPER" | "INVENTORY" => "STOREKEEPER",
        "WAITER" | "SERVER" => "WAITER",
        _ => "CASHIER",
    };

    let role_id = sqlx::query_as::<_, (Uuid,)>(
        r#"
        INSERT INTO roles (organization_id, name, description, is_system)
        VALUES ($1, $2, $3, true)
        ON CONFLICT (organization_id, name) DO UPDATE SET name = EXCLUDED.name
        RETURNING id
        "#,
    )
    .bind(org_id)
    .bind(role_name)
    .bind(format!("{} Role", role_name))
    .fetch_one(&pool)
    .await?
    .0;

    let _ = sqlx::query(
        r#"
        INSERT INTO user_roles (user_id, role_id, branch_id)
        VALUES ($1, $2, $3)
        ON CONFLICT DO NOTHING
        "#,
    )
    .bind(user_id)
    .bind(role_id)
    .bind(payload.branch_id)
    .execute(&pool)
    .await;

    Ok(Json(UserListItem {
        id: user_id,
        organization_id: org_id,
        name: clean_name.to_string(),
        email,
        phone: payload.phone,
        status: "ACTIVE".to_string(),
        created_at: user_row.1,
        updated_at: user_row.2,
        role: role_name.to_string(),
        branch_id: payload.branch_id,
        has_pin: pin_hash.is_some(),
        employee_number: payload.employee_number,
        job_title: Some(role_name.to_string()),
        department: payload.department,
        till_lane: payload.till_lane,
    }))
}

pub async fn update_user(
    Path(user_id): Path<Uuid>,
    _maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<UpdateUserRequest>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;

    if let Some(ref name) = payload.name {
        sqlx::query("UPDATE users SET name = $1, updated_at = NOW() WHERE id = $2")
            .bind(name)
            .bind(user_id)
            .execute(&pool)
            .await?;
    }

    if let Some(ref phone) = payload.phone {
        sqlx::query("UPDATE users SET phone = $1, updated_at = NOW() WHERE id = $2")
            .bind(phone)
            .bind(user_id)
            .execute(&pool)
            .await?;
    }

    if let Some(ref email) = payload.email {
        sqlx::query("UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2")
            .bind(email)
            .bind(user_id)
            .execute(&pool)
            .await?;
    }

    if let Some(ref status) = payload.status {
        sqlx::query("UPDATE users SET status = $1, updated_at = NOW() WHERE id = $2")
            .bind(status)
            .bind(user_id)
            .execute(&pool)
            .await?;
    }

    if let Some(ref pin) = payload.pin_code {
        let trimmed = pin.trim();
        if !trimmed.is_empty() {
            let hash = hash_password(trimmed)?;
            sqlx::query("UPDATE users SET pin_code = $1, updated_at = NOW() WHERE id = $2")
                .bind(hash)
                .bind(user_id)
                .execute(&pool)
                .await?;
        }
    }

    if let Some(ref role_raw) = payload.role {
        let role_name = match role_raw.to_uppercase().as_str() {
            "OWNER" | "ADMIN" | "SUPERADMIN" => "OWNER",
            "BRANCH_MANAGER" | "MANAGER" | "SUPERVISOR" => "MANAGER",
            "ACCOUNTANT" | "AUDITOR" => "ACCOUNTANT",
            "STOREKEEPER" | "INVENTORY" => "STOREKEEPER",
            "WAITER" | "SERVER" => "WAITER",
            _ => "CASHIER",
        };

        if let Some(org_id) = sqlx::query_scalar::<_, Uuid>("SELECT organization_id FROM users WHERE id = $1")
            .bind(user_id)
            .fetch_optional(&pool)
            .await?
        {
            let role_id = sqlx::query_as::<_, (Uuid,)>(
                r#"
                INSERT INTO roles (organization_id, name, description, is_system)
                VALUES ($1, $2, $3, true)
                ON CONFLICT (organization_id, name) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
                "#,
            )
            .bind(org_id)
            .bind(role_name)
            .bind(format!("{} Role", role_name))
            .fetch_one(&pool)
            .await?
            .0;

            let _ = sqlx::query(
                r#"
                INSERT INTO user_roles (user_id, role_id, branch_id)
                VALUES ($1, $2, $3)
                ON CONFLICT (user_id, role_id, branch_id) DO UPDATE SET role_id = EXCLUDED.role_id
                "#,
            )
            .bind(user_id)
            .bind(role_id)
            .bind(payload.branch_id)
            .execute(&pool)
            .await;
        }
    }

    Ok(Json(serde_json::json!({
        "success": true,
        "id": user_id
    })))
}

pub async fn delete_user(
    Path(user_id): Path<Uuid>,
    _maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    let pool = state.pool().await;

    let res = sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(&pool)
        .await;

    match res {
        Ok(_) => Ok(Json(serde_json::json!({ "deleted": true, "id": user_id }))),
        Err(_) => {
            sqlx::query("UPDATE users SET status = 'DISABLED', updated_at = NOW() WHERE id = $1")
                .bind(user_id)
                .execute(&pool)
                .await?;
            Ok(Json(serde_json::json!({ "disabled": true, "id": user_id })))
        }
    }
}

pub fn auth_router() -> Router<AppState> {
    Router::new()
        .route("/login", post(login))
        .route("/pin-login", post(pin_login))
        .route("/register", post(register_user))
        .route("/verify-license", post(verify_license))
        .route("/me", get(get_current_user))
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", put(update_user).delete(delete_user))
}
