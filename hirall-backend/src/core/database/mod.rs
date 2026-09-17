use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use tracing::info;
use crate::app::state::SharedPool;
use crate::core::errors::AppResult;

// ── In-process RDS IAM token via SigV4 presigning ───────────────────────────
// The RDS auth token is a SigV4 presigned URL (without "https://").
// Uses permanent AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY — no CLI, no browser.

fn hmac_sha256(key: &[u8], data: &[u8]) -> Vec<u8> {
    use hmac::{Hmac, Mac};
    use sha2::Sha256;
    let mut mac = Hmac::<Sha256>::new_from_slice(key).expect("HMAC accepts any key length");
    mac.update(data);
    mac.finalize().into_bytes().to_vec()
}

fn sha256_hex(data: &[u8]) -> String {
    use sha2::{Sha256, Digest};
    let mut h = Sha256::new();
    h.update(data);
    format!("{:x}", h.finalize())
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

/// Generate an RDS IAM auth token (valid 15 min) using SigV4 presigning.
fn generate_rds_iam_token(host: &str, port: u16, user: &str, region: &str) -> Option<String> {
    let access_key = std::env::var("AWS_ACCESS_KEY_ID").ok()?;
    let secret_key = std::env::var("AWS_SECRET_ACCESS_KEY").ok()?;
    if access_key.is_empty() || secret_key.is_empty() {
        tracing::error!("AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY not set in .env");
        return None;
    }

    let now = chrono::Utc::now();
    let date_str  = now.format("%Y%m%d").to_string();       // e.g. 20260906
    let datetime  = now.format("%Y%m%dT%H%M%SZ").to_string(); // e.g. 20260906T054000Z
    let service   = "rds-db";
    let algorithm = "AWS4-HMAC-SHA256";
    let scope     = format!("{}/{}/{}/aws4_request", date_str, region, service);
    let credential= format!("{}/{}", access_key, scope);

    // The "host" header value
    let host_header = format!("{}:{}", host, port);

    // Canonical query string (params sorted alphabetically)
    let query = format!(
        "Action=connect&DBUser={}&X-Amz-Algorithm={}&X-Amz-Credential={}&X-Amz-Date={}&X-Amz-Expires=900&X-Amz-SignedHeaders=host",
        user,
        algorithm,
        urlencoding::encode(&credential),
        datetime
    );

    // Canonical request
    let canonical_headers = format!("host:{}\n", host_header);
    let signed_headers = "host";
    let payload_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"; // SHA256("")

    let canonical_request = format!(
        "GET\n/\n{}\n{}\n{}\n{}",
        query,
        canonical_headers,
        signed_headers,
        payload_hash
    );

    // String to sign
    let canonical_request_hash = sha256_hex(canonical_request.as_bytes());
    let string_to_sign = format!(
        "{}\n{}\n{}\n{}",
        algorithm,
        datetime,
        scope,
        canonical_request_hash
    );

    // Signing key
    let k_secret  = format!("AWS4{}", secret_key);
    let k_date    = hmac_sha256(k_secret.as_bytes(), date_str.as_bytes());
    let k_region  = hmac_sha256(&k_date,   region.as_bytes());
    let k_service = hmac_sha256(&k_region, service.as_bytes());
    let k_signing = hmac_sha256(&k_service, b"aws4_request");

    let signature = hex(&hmac_sha256(&k_signing, string_to_sign.as_bytes()));

    // Final token (SigV4 presigned URL without scheme)
    let token = format!(
        "{}:{}/?{}&X-Amz-Signature={}",
        host, port, query, signature
    );

    Some(token)
}

// ── Pool builder ─────────────────────────────────────────────────────────────

async fn build_iam_pool(host: &str, port: u16, user: &str, dbname: &str, region: &str, max_connections: u32)
    -> Result<PgPool, String>
{
    let token = generate_rds_iam_token(host, port, user, region)
        .ok_or_else(|| "Failed to generate RDS IAM token".to_string())?;

    let url = format!(
        "postgres://{}:{}@{}:{}/{}?sslmode=require",
        user,
        urlencoding::encode(&token),
        host, port, dbname
    );

    PgPoolOptions::new()
        .max_connections(max_connections)
        .min_connections(1)
        .acquire_timeout(Duration::from_secs(30))
        .idle_timeout(Duration::from_secs(540))     // 9 min — under 15-min token expiry
        .max_lifetime(Duration::from_secs(700))     // 11.5 min — reconnect before token expires
        .connect(&url)
        .await
        .map_err(|e| format!("DB connect failed: {e}"))
}

// ── Public entry point ───────────────────────────────────────────────────────

pub async fn create_pool(_database_url: &str, max_connections: u32) -> AppResult<SharedPool> {
    let host   = std::env::var("DB_HOST").unwrap_or_else(|_| "localhost".into());
    let user   = std::env::var("DB_USER").unwrap_or_else(|_| "postgres".into());
    let dbname = std::env::var("DB_NAME").unwrap_or_else(|_| "giftmart".into());
    let region = std::env::var("AWS_REGION").unwrap_or_else(|_| "eu-west-1".into());
    let port: u16 = 5432;

    info!("Initializing PostgreSQL connection pool...");
    info!("Generating RDS IAM token for {}@{}:{}/{} in {}...", user, host, port, dbname, region);

    let pool = build_iam_pool(&host, port, &user, &dbname, &region, max_connections)
        .await
        .map_err(|e| {
            tracing::error!("IAM pool startup failed: {}", e);
            sqlx::Error::Configuration(e.into())
        })?;

    info!("Connected to PostgreSQL (IAM) successfully.");

    let shared: SharedPool = std::sync::Arc::new(tokio::sync::RwLock::new(pool));

    // ── Token refresh every 12 minutes (tokens expire in 15 min) ─────────────
    let shared_clone = shared.clone();
    let host_s   = host.clone();
    let user_s   = user.clone();
    let dbname_s = dbname.clone();
    let region_s = region.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(12 * 60));
        interval.tick().await; // skip first immediate tick
        loop {
            interval.tick().await;
            info!("Refreshing RDS IAM token (12-min cycle)...");
            match build_iam_pool(&host_s, port, &user_s, &dbname_s, &region_s, max_connections).await {
                Ok(new_pool) => {
                    let old = {
                        let mut guard = shared_clone.write().await;
                        std::mem::replace(&mut *guard, new_pool)
                    };
                    old.close().await;
                    info!("IAM pool hot-swapped successfully.");
                }
                Err(e) => {
                    tracing::error!("IAM token refresh failed — keeping existing pool. Error: {}", e);
                }
            }
        }
    });

    // ── Keepalive ping every 60 s ────────────────────────────────────────────
    let ping_ref = shared.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(60));
        loop {
            interval.tick().await;
            let pool = ping_ref.read().await;
            if let Err(e) = sqlx::query("SELECT 1").execute(&*pool).await {
                tracing::warn!("DB keepalive ping error: {}", e);
            }
        }
    });

    Ok(shared)
}

#[allow(dead_code)]
pub async fn run_migrations(pool: &PgPool) -> AppResult<()> {
    info!("Checking and applying pending database migrations...");
    sqlx::migrate!("./migrations").run(pool).await?;
    info!("Database migrations applied successfully.");
    Ok(())
}
