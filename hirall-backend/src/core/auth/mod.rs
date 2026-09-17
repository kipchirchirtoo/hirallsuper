use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{header, request::Parts},
};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::core::errors::AppError;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: Uuid,             // User ID
    pub org_id: Uuid,          // Organization ID
    pub branch_id: Option<Uuid>,// Optional active branch ID
    pub role: String,          // Role code / name
    pub exp: i64,              // Expiration timestamp
    pub iat: i64,              // Issued at
}

#[allow(dead_code)]
pub struct AuthUser {
    pub user_id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Option<Uuid>,
    pub role: String,
}

pub fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| AppError::Internal(format!("Hashing error: {}", e)))
}

pub fn verify_password(password: &str, password_hash: &str) -> Result<bool, AppError> {
    let parsed_hash = PasswordHash::new(password_hash)
        .map_err(|e| AppError::Internal(format!("Invalid password hash: {}", e)))?;
    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

pub fn generate_jwt(
    user_id: Uuid,
    org_id: Uuid,
    branch_id: Option<Uuid>,
    role: &str,
    secret: &str,
    hours: i64,
) -> Result<String, AppError> {
    let now = Utc::now();
    let exp = (now + Duration::hours(hours)).timestamp();

    let claims = Claims {
        sub: user_id,
        org_id,
        branch_id,
        role: role.to_string(),
        exp,
        iat: now.timestamp(),
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(format!("Token creation failed: {}", e)))
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get(header::AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .ok_or_else(|| AppError::Authentication("Missing Authorization header".into()))?;

        if !auth_header.starts_with("Bearer ") {
            return Err(AppError::Authentication(
                "Invalid Authorization scheme. Expected 'Bearer <token>'".into(),
            ));
        }

        let token = &auth_header[7..];
        let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "default_insecure_secret_key".into());

        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| AppError::Authentication(format!("Invalid or expired token: {}", e)))?;

        Ok(AuthUser {
            user_id: token_data.claims.sub,
            organization_id: token_data.claims.org_id,
            branch_id: token_data.claims.branch_id,
            role: token_data.claims.role,
        })
    }
}

pub struct MaybeAuthUser(pub Option<AuthUser>);

#[async_trait]
impl<S> FromRequestParts<S> for MaybeAuthUser
where
    S: Send + Sync,
{
    type Rejection = std::convert::Infallible;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        match AuthUser::from_request_parts(parts, state).await {
            Ok(user) => Ok(MaybeAuthUser(Some(user))),
            Err(_) => Ok(MaybeAuthUser(None)),
        }
    }
}

