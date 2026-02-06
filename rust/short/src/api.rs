use hyper::{body::Bytes, Request, Response};
use http_body_util::Full;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;
use tracing::{debug, info};

use crate::db::ShortDb;
use crate::error::{AppError, Result};

/// Handle all API requests
pub async fn handle_api_request(
    req: Request<hyper::body::Incoming>,
    store: Arc<RwLock<impl ShortDb>>,
    secret: Arc<String>,
) -> Result<Response<Full<Bytes>>> {
    // Check authentication
    let authorized = req
        .headers()
        .get("authorization")
        .and_then(|auth| auth.to_str().ok())
        .map(|auth| auth.ends_with(secret.as_str()))
        .unwrap_or(false);

    if !authorized {
        return Ok(json_response(
            401,
            serde_json::json!({
                "success": false,
                "error": "Authentication required"
            }),
        ));
    }

    // Parse API path: /_api/list
    let path_parts: Vec<&str> = req
        .uri()
        .path()
        .split('/')
        .filter(|s| !s.is_empty())
        .collect();

    if path_parts.len() < 2 || path_parts[1] != "list" {
        return Ok(json_response(
            404,
            serde_json::json!({
                "success": false,
                "error": "Unknown API endpoint"
            }),
        ));
    }

    handle_list_api(req, store).await
}

/// Handle the list API endpoint
async fn handle_list_api(
    req: Request<hyper::body::Incoming>,
    store: Arc<RwLock<impl ShortDb>>,
) -> Result<Response<Full<Bytes>>> {
    let query = req.uri().query().unwrap_or("");
    let params: HashMap<String, String> =
        url::form_urlencoded::parse(query.as_bytes())
            .into_owned()
            .collect();

    let namespace_filter = params.get("namespace").map(|s| s.as_str());
    let prefix_filter = params.get("prefix").map(|s| s.as_str());
    let limit: usize = params
        .get("limit")
        .and_then(|s| s.parse().ok())
        .unwrap_or(100)
        .min(1000);
    let include_versions: bool = params
        .get("versions")
        .and_then(|s| s.parse().ok())
        .unwrap_or(false);

    debug!(
        "List API called: namespace={:?}, prefix={:?}, limit={}, versions={}",
        namespace_filter, prefix_filter, limit, include_versions
    );

    let db = store
        .read()
        .map_err(|_| AppError::LockPoisoned)?;
    let all_links = db.list_latest();

    let total_count = all_links.len();

    let filtered_links: Vec<LinkDetail> = all_links
        .into_iter()
        .filter(|(key, _url)| {
            // Parse "namespace~shortkey"
            let parts: Vec<&str> = key.splitn(2, '~').collect();
            if parts.len() != 2 {
                return false;
            }

            let (ns, short_key) = (parts[0], parts[1]);

            // Filter by namespace
            if let Some(ns_filter) = namespace_filter {
                if ns != ns_filter {
                    return false;
                }
            }

            // Filter by prefix
            if let Some(prefix) = prefix_filter {
                if !short_key.starts_with(prefix) {
                    return false;
                }
            }

            true
        })
        .map(|(key, url)| {
            let parts: Vec<&str> = key.splitn(2, '~').collect();
            LinkDetail {
                key: key.to_string(),
                namespace: parts[0].to_string(),
                short_key: parts[1].to_string(),
                url: url.to_string(),
                version: 0,
                version_count: 1,
                created_at: chrono::Utc::now().to_rfc3339(),
                versions: if include_versions {
                    // For now, just return the current version
                    vec![url.to_string()]
                } else {
                    vec![]
                },
            }
        })
        .take(limit)
        .collect();

    drop(db); // Release the lock

    info!(
        "Returning {} links (filtered from {} total)",
        filtered_links.len(),
        total_count
    );

    Ok(json_response(
        200,
        serde_json::json!({
            "success": true,
            "data": {
                "total_keys": filtered_links.len(),
                "filtered_keys": filtered_links.len(),
                "links": filtered_links
            }
        }),
    ))
}

/// Link detail structure for API responses
#[derive(Serialize)]
struct LinkDetail {
    key: String,
    namespace: String,
    short_key: String,
    url: String,
    version: i32,
    version_count: usize,
    created_at: String,
    versions: Vec<String>,
}

/// Create a JSON response
fn json_response(status: u16, body: serde_json::Value) -> Response<Full<Bytes>> {
    Response::builder()
        .status(status)
        .header("Content-Type", "application/json")
        .body(Full::new(body.to_string().into()))
        .unwrap()
}

use std::sync::RwLock;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_json_response() {
        let body = serde_json::json!({
            "success": true,
            "message": "test"
        });

        let response = json_response(200, body);

        assert_eq!(response.status(), 200);
        assert_eq!(
            response.headers().get("Content-Type").unwrap(),
            "application/json"
        );
    }

    #[test]
    fn test_json_response_error() {
        let body = serde_json::json!({
            "success": false,
            "error": "Authentication required"
        });

        let response = json_response(401, body);

        assert_eq!(response.status(), 401);
    }

    #[test]
    fn test_link_detail_serialization() {
        let link = LinkDetail {
            key: "default~test".to_string(),
            namespace: "default".to_string(),
            short_key: "test".to_string(),
            url: "http://example.com".to_string(),
            version: 0,
            version_count: 1,
            created_at: "2026-01-02T18:30:00Z".to_string(),
            versions: vec!["http://example.com".to_string()],
        };

        let serialized = serde_json::to_string(&link).unwrap();
        assert!(serialized.contains(r#""key":"default~test""#));
        assert!(serialized.contains(r#""namespace":"default""#));
        assert!(serialized.contains(r#""short_key":"test""#));
        assert!(serialized.contains(r#""url":"http://example.com""#));
        assert!(serialized.contains(r#""version":0"#));
        assert!(serialized.contains(r#""version_count":1"#));
    }

    #[test]
    fn test_link_detail_with_versions() {
        let link = LinkDetail {
            key: "default~test".to_string(),
            namespace: "default".to_string(),
            short_key: "test".to_string(),
            url: "http://example.com/v2".to_string(),
            version: 2,
            version_count: 3,
            created_at: "2026-01-02T18:30:00Z".to_string(),
            versions: vec![
                "http://example.com/v1".to_string(),
                "http://example.com/v2".to_string(),
                "http://example.com/v3".to_string(),
            ],
        };

        let serialized = serde_json::to_string(&link).unwrap();
        assert!(serialized.contains(r#""version":2"#));
        assert!(serialized.contains(r#""version_count":3"#));
        assert!(serialized.contains(r#""versions":["http://example.com/v1","http://example.com/v2","http://example.com/v3"]"#));
    }
}
