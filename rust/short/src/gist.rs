use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tokio::fs;
use tracing::{info, warn, error};
use thiserror::Error;

use crate::error::AppError;

/// GitHub Gist backup errors
#[derive(Debug, Error)]
pub enum GistError {
    #[error("GitHub API error: {0}")]
    GitHubApi(String),

    #[error("HTTP request failed: {0}")]
    Request(String),

    #[error("IO error: {0}")]
    Io(String),

    #[error("Gist not found or inaccessible")]
    NotFound,

    #[error("Invalid gist URL format")]
    InvalidUrl,

    #[error("Rate limit exceeded")]
    RateLimited,
}

#[derive(Debug, Serialize, Deserialize)]
struct GistCreateRequest {
    description: String,
    public: bool,
    files: HashMap<String, GistFile>,
}

#[derive(Debug, Serialize, Deserialize)]
struct GistFile {
    content: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct GistResponse {
    id: String,
    #[serde(rename = "html_url")]
    html_url: String,
    files: HashMap<String, GistFileData>,
}

#[derive(Debug, Serialize, Deserialize)]
struct GistFileData {
    #[serde(rename = "raw_url")]
    raw_url: String,
    content: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct GistWrapper {
    version: String,
    timestamp: String,
    database: serde_json::Value,
}

/// GitHub Gist backup manager
pub struct GistBackup {
    pub client: Client,
    pub token: String,
    pub gist_url_file: PathBuf,
    pub gist_url: Option<String>,
}

impl GistBackup {
    /// Create a new GistBackup instance
    pub fn new(token: String, data_dir: &Path) -> Self {
        Self {
            client: Client::new(),
            token,
            gist_url_file: data_dir.join(".short_gist_url"),
            gist_url: None,
        }
    }

    /// Initialize by loading existing gist URL or setting to None
    pub async fn initialize(&mut self) -> Result<(), AppError> {
        if self.gist_url_file.exists() {
            match fs::read_to_string(&self.gist_url_file).await {
                Ok(url) => {
                    let url = url.trim().to_string();
                    if !url.is_empty() {
                        self.gist_url = Some(url);
                        info!("Loaded existing gist URL");
                    }
                }
                Err(e) => {
                    warn!("Failed to read gist URL file: {}", e);
                }
            }
        } else {
            info!("No existing gist found, will create on first backup");
        }
        Ok(())
    }

    /// Backup database to GitHub Gist
    pub async fn backup(&mut self, db_json: &str) -> Result<String, AppError> {
        let file_content = self.wrap_with_metadata(db_json);

        let result = if let Some(url) = &self.gist_url {
            self.update_existing_gist(url, &file_content).await
        } else {
            self.create_new_gist(&file_content).await
        };

        match &result {
            Ok(gist_url) => info!("Backup completed: {}", gist_url),
            Err(e) => error!("Backup failed: {}", e),
        }

        result
    }

    /// Restore database from GitHub Gist
    pub async fn restore(&self) -> Result<String, AppError> {
        let url = self
            .gist_url
            .as_ref()
            .ok_or_else(|| AppError::GistBackup("No gist URL configured".into()))?;

        let response = self
            .client
            .get(url)
            .header("Authorization", format!("Bearer {}", self.token))
            .header("User-Agent", "short-rust-url-shortener")
            .send()
            .await
            .map_err(|e| AppError::GistBackup(format!("Request failed: {}", e)))?;

        if response.status().is_success() {
            let gist: GistResponse = response
                .json()
                .await
                .map_err(|e| AppError::GistBackup(format!("Failed to parse response: {}", e)))?;

            let file = gist
                .files
                .get("short_db_backup.json")
                .ok_or_else(|| AppError::GistBackup("Gist file not found".into()))?;

            let content = file
                .content
                .as_ref()
                .ok_or_else(|| AppError::GistBackup("File content not available".into()))?;

            self.extract_db_from_json(content)
        } else if response.status() == 404 {
            Err(AppError::GistBackup("Gist not found (404)".into()))
        } else if response.status() == 403 {
            Err(AppError::GistBackup("Rate limited (403)".into()))
        } else {
            Err(AppError::GistBackup(format!(
                "GitHub API error: {}",
                response.status()
            )))
        }
    }

    /// Merge remote and local databases (local wins on conflicts)
    pub fn merge_databases(&self, remote_json: &str, local_json: &str) -> String {
        let remote_val: serde_json::Value = serde_json::from_str(remote_json)
            .unwrap_or_else(|_| serde_json::json!({ "db": {} }));

        let local_val: serde_json::Value = serde_json::from_str(local_json)
            .unwrap_or_else(|_| serde_json::json!({ "db": {} }));

        let empty_map = serde_json::Map::new();
        let remote_db = remote_val
            .get("db")
            .and_then(|v| v.as_object())
            .unwrap_or(&empty_map);

        let local_db = local_val
            .get("db")
            .and_then(|v| v.as_object())
            .unwrap_or(&empty_map);

        // Merge: start with remote, overwrite with local
        let mut merged_db = remote_db.clone();
        for (key, val) in local_db.iter() {
            merged_db.insert(key.clone(), val.clone());
        }

        let merged = serde_json::json!({
            "db": merged_db
        });

        serde_json::to_string_pretty(&merged).unwrap_or_else(|_| "{\"db\": {}}".to_string())
    }

    /// Wrap database JSON with metadata
    fn wrap_with_metadata(&self, db_json: &str) -> String {
        let db_value: serde_json::Value = serde_json::from_str(db_json)
            .unwrap_or_else(|_| serde_json::json!({ "db": {} }));

        let wrapper = GistWrapper {
            version: "2.0".to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
            database: db_value,
        };

        serde_json::to_string_pretty(&wrapper)
            .unwrap_or_else(|_| db_json.to_string())
    }

    /// Extract database JSON from wrapped format
    fn extract_db_from_json(&self, wrapped: &str) -> Result<String, AppError> {
        let value: serde_json::Value = serde_json::from_str(wrapped)
            .map_err(|e| AppError::GistBackup(format!("Invalid gist format: {}", e)))?;

        let db = value
            .get("database")
            .ok_or_else(|| AppError::GistBackup("Missing 'database' field".into()))?;

        serde_json::to_string_pretty(db)
            .map_err(|e| AppError::GistBackup(format!("Failed to serialize DB: {}", e)))
    }

    /// Create a new gist
    async fn create_new_gist(&mut self, content: &str) -> Result<String, AppError> {
        let mut files = HashMap::new();
        files.insert(
            "short_db_backup.json".to_string(),
            GistFile {
                content: content.to_string(),
            },
        );

        let request = GistCreateRequest {
            description: "URL Shortener Database Backup".to_string(),
            public: false,
            files,
        };

        let response = self
            .client
            .post("https://api.github.com/gists")
            .header("Authorization", format!("Bearer {}", self.token))
            .header("Accept", "application/vnd.github.v3+json")
            .header("User-Agent", "short-rust-url-shortener")
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::GistBackup(format!("Request failed: {}", e)))?;

        if response.status().is_success() {
            let gist: GistResponse = response
                .json()
                .await
                .map_err(|e| AppError::GistBackup(format!("Failed to parse response: {}", e)))?;

            let gist_api_url = format!("https://api.github.com/gists/{}", gist.id);

            // Save gist URL for future use
            if let Err(e) = fs::write(&self.gist_url_file, &gist_api_url).await {
                warn!("Failed to save gist URL: {}", e);
            } else {
                self.gist_url = Some(gist_api_url.clone());
            }

            info!("Created new gist: {}", gist.html_url);
            Ok(gist.html_url)
        } else if response.status() == 403 {
            Err(AppError::GistBackup("Rate limited by GitHub".into()))
        } else {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            Err(AppError::GistBackup(format!(
                "Failed to create gist: {} - {}",
                status,
                error_text
            )))
        }
    }

    /// Update an existing gist
    async fn update_existing_gist(&self, gist_url: &str, content: &str) -> Result<String, AppError> {
        // Extract gist ID from URL
        let gist_id = gist_url
            .rsplit('/')
            .next()
            .ok_or_else(|| AppError::GistBackup("Invalid gist URL".into()))?;

        let mut files = HashMap::new();
        files.insert(
            "short_db_backup.json".to_string(),
            GistFile {
                content: content.to_string(),
            },
        );

        let request = serde_json::json!({
            "files": files
        });

        let response = self
            .client
            .patch(&format!("https://api.github.com/gists/{}", gist_id))
            .header("Authorization", format!("Bearer {}", self.token))
            .header("Accept", "application/vnd.github.v3+json")
            .header("User-Agent", "short-rust-url-shortener")
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::GistBackup(format!("Request failed: {}", e)))?;

        if response.status().is_success() {
            let gist: GistResponse = response
                .json()
                .await
                .map_err(|e| AppError::GistBackup(format!("Failed to parse response: {}", e)))?;

            info!("Updated gist: {}", gist.html_url);
            Ok(gist.html_url)
        } else if response.status() == 404 {
            // Gist was deleted, will create new one next time
            warn!("Existing gist not found (404), will create new gist on next backup");
            Err(AppError::GistBackup("Gist not found".into()))
        } else if response.status() == 403 {
            Err(AppError::GistBackup("Rate limited by GitHub".into()))
        } else {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            Err(AppError::GistBackup(format!(
                "Failed to update gist: {} - {}",
                status,
                error_text
            )))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wrap_metadata() {
        let temp_gist = GistBackup::new("test_token".to_string(), Path::new("/tmp"));
        let db_json = r#"{"db":{"test":["http://example.com"]}}"#;
        let wrapped = temp_gist.wrap_with_metadata(db_json);

        // Check that key components are present (formatting may differ)
        assert!(wrapped.contains("version"));
        assert!(wrapped.contains("database"));
        assert!(wrapped.contains("test"));
        assert!(wrapped.contains("timestamp"));
    }

    #[test]
    fn test_extract_db_from_json() {
        let temp_gist = GistBackup::new("test_token".to_string(), Path::new("/tmp"));
        let wrapped = r#"{
            "version": "2.0",
            "timestamp": "2026-01-02T18:30:00Z",
            "database": {
                "db": {
                    "test": ["http://example.com"]
                }
            }
        }"#;

        let result = temp_gist.extract_db_from_json(wrapped);
        assert!(result.is_ok());

        let extracted = result.unwrap();
        assert!(extracted.contains("test"));
        assert!(extracted.contains("http://example.com"));
    }

    #[test]
    fn test_merge_databases() {
        let temp_gist = GistBackup::new("test_token".to_string(), Path::new("/tmp"));
        let remote = r#"{"db":{"key1":["url1"],"key2":["url2"]}}"#;
        let local = r#"{"db":{"key2":["url2_local"],"key3":["url3"]}}"#;

        let merged = temp_gist.merge_databases(remote, local);
        let merged_val: serde_json::Value = serde_json::from_str(&merged).unwrap();
        let merged_db = merged_val.get("db").unwrap().as_object().unwrap();

        // Local should win for key2
        assert_eq!(
            merged_db.get("key2").unwrap(),
            &serde_json::json!(["url2_local"])
        );
        // Remote key1 should be preserved
        assert_eq!(merged_db.get("key1").unwrap(), &serde_json::json!(["url1"]));
        // Local key3 should be added
        assert_eq!(merged_db.get("key3").unwrap(), &serde_json::json!(["url3"]));
    }

    #[test]
    fn test_merge_empty_local() {
        let temp_gist = GistBackup::new("test_token".to_string(), Path::new("/tmp"));
        let remote = r#"{"db":{"key1":["url1"]}}"#;
        let local = r#"{"db":{}}"#;

        let merged = temp_gist.merge_databases(remote, local);
        let merged_val: serde_json::Value = serde_json::from_str(&merged).unwrap();
        let merged_db = merged_val.get("db").unwrap().as_object().unwrap();

        // Remote should be preserved when local is empty
        assert_eq!(merged_db.get("key1").unwrap(), &serde_json::json!(["url1"]));
    }

    #[test]
    fn test_merge_empty_remote() {
        let temp_gist = GistBackup::new("test_token".to_string(), Path::new("/tmp"));
        let remote = r#"{"db":{}}"#;
        let local = r#"{"db":{"key1":["url1"]}}"#;

        let merged = temp_gist.merge_databases(remote, local);
        let merged_val: serde_json::Value = serde_json::from_str(&merged).unwrap();
        let merged_db = merged_val.get("db").unwrap().as_object().unwrap();

        // Local should be preserved when remote is empty
        assert_eq!(merged_db.get("key1").unwrap(), &serde_json::json!(["url1"]));
    }
}
