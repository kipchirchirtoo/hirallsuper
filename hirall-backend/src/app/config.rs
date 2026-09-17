use std::env;

#[allow(dead_code)]
#[derive(Clone, Debug)]
pub struct Config {
    pub server_host: String,
    pub server_port: u16,
    pub environment: String,
    pub database_url: String,
    pub database_max_connections: u32,
    pub redis_url: String,
    pub jwt_secret: String,
    pub jwt_refresh_secret: String,
    pub jwt_expiration_hours: i64,
    pub s3_endpoint: String,
    pub s3_region: String,
    pub s3_bucket: String,
    pub s3_access_key_id: String,
    pub s3_secret_access_key: String,
    pub s3_public_domain: String,
}

impl Config {
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();

        Self {
            server_host: env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            server_port: env::var("SERVER_PORT")
                .or_else(|_| env::var("PORT"))
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("SERVER_PORT or PORT must be a valid u16"),
            environment: env::var("ENVIRONMENT").unwrap_or_else(|_| "development".to_string()),
            database_url: env::var("DATABASE_URL").expect("DATABASE_URL must be set"),
            database_max_connections: env::var("DATABASE_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "20".to_string())
                .parse()
                .unwrap_or(20),
            redis_url: env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6379".to_string()),
            jwt_secret: env::var("JWT_SECRET").unwrap_or_else(|_| "default_insecure_secret_key".to_string()),
            jwt_refresh_secret: env::var("JWT_REFRESH_SECRET").unwrap_or_else(|_| "default_insecure_refresh_key".to_string()),
            jwt_expiration_hours: env::var("JWT_EXPIRATION_HOURS")
                .unwrap_or_else(|_| "24".to_string())
                .parse()
                .unwrap_or(24),
            s3_endpoint: env::var("S3_ENDPOINT").unwrap_or_else(|_| "http://localhost:9000".to_string()),
            s3_region: env::var("S3_REGION").unwrap_or_else(|_| "auto".to_string()),
            s3_bucket: env::var("S3_BUCKET").unwrap_or_else(|_| "hirall-media".to_string()),
            s3_access_key_id: env::var("S3_ACCESS_KEY_ID").unwrap_or_default(),
            s3_secret_access_key: env::var("S3_SECRET_ACCESS_KEY").unwrap_or_default(),
            s3_public_domain: env::var("S3_PUBLIC_DOMAIN").unwrap_or_else(|_| "http://localhost:9000/hirall-media".to_string()),
        }
    }
}
