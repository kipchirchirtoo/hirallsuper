use aws_sdk_s3::presigning::PresigningConfig;
use aws_sdk_s3::Client as S3Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use uuid::Uuid;

use crate::app::config::Config;
use crate::core::errors::{AppError, AppResult};

#[derive(Clone)]
pub struct StorageService {
    s3_client: S3Client,
    bucket: String,
    public_domain: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PresignedUploadResponse {
    pub upload_url: String,
    pub storage_key: String,
    pub file_url: String,
    pub expires_in_seconds: u64,
}

impl StorageService {
    pub async fn new(config: &Config) -> Self {
        let region = aws_sdk_s3::config::Region::new(config.s3_region.clone());
        let credentials = aws_sdk_s3::config::Credentials::new(
            &config.s3_access_key_id,
            &config.s3_secret_access_key,
            None,
            None,
            "custom",
        );

        let s3_config = aws_sdk_s3::Config::builder()
            .region(region)
            .endpoint_url(&config.s3_endpoint)
            .credentials_provider(credentials)
            .force_path_style(true) // Required for MinIO & local dev
            .timeout_config(aws_sdk_s3::config::timeout::TimeoutConfig::disabled())
            .retry_config(aws_sdk_s3::config::retry::RetryConfig::disabled())
            .stalled_stream_protection(aws_sdk_s3::config::StalledStreamProtectionConfig::disabled())
            .identity_cache(aws_sdk_s3::config::IdentityCache::no_cache())
            .build();

        let s3_client = S3Client::from_conf(s3_config);

        Self {
            s3_client,
            bucket: config.s3_bucket.clone(),
            public_domain: config.s3_public_domain.clone(),
        }
    }

    pub async fn generate_presigned_upload_url(
        &self,
        folder: &str,
        file_extension: &str,
        mime_type: &str,
    ) -> AppResult<PresignedUploadResponse> {
        let file_id = Uuid::new_v4();
        let key = format!("{}/{}.{}", folder, file_id, file_extension.trim_start_matches('.'));
        let expires_in = Duration::from_secs(900); // 15 minutes

        let presigning_config = PresigningConfig::expires_in(expires_in)
            .map_err(|e| AppError::Internal(format!("Presigning config error: {}", e)))?;

        let presigned_req = self
            .s3_client
            .put_object()
            .bucket(&self.bucket)
            .key(&key)
            .content_type(mime_type)
            .presigned(presigning_config)
            .await
            .map_err(|e| AppError::Internal(format!("Failed generating presigned URL: {}", e)))?;

        let file_url = format!("{}/{}", self.public_domain.trim_end_matches('/'), key);

        Ok(PresignedUploadResponse {
            upload_url: presigned_req.uri().to_string(),
            storage_key: key,
            file_url,
            expires_in_seconds: 900,
        })
    }
}
