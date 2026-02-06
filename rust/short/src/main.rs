use std::convert::TryInto;
use std::env;
use std::net::SocketAddr;
use std::path;
use std::sync::Arc;

use hyper::body::Bytes;
use hyper::server::conn::http1;
use hyper::service::service_fn;
use hyper::{Method, Request, Response};
use hyper_util::rt::TokioIo;
use http_body_util::{Full, BodyExt};
use tokio::net::TcpListener;
use tracing::{info, error, debug};
use tracing_subscriber::{EnvFilter, fmt};

use std::fs::File;
use std::io::Read;
use std::sync::RwLock;

mod api;
mod db;
mod error;
mod fs;
mod gist;
mod link;

use crate::db::ShortDb;
use error::{AppError, Result};

type GenericError = Box<dyn std::error::Error + Send + Sync>;
type HttpResult<T> = std::result::Result<T, GenericError>;

async fn router(
    req: Request<hyper::body::Incoming>,
    store: Arc<RwLock<impl db::ShortDb>>,
    secret: Arc<String>,
) -> HttpResult<Response<Full<Bytes>>> {
    // Check for API routes first
    if req.uri().path().starts_with("/_api/") {
        return api::handle_api_request(req, store, secret)
            .await
            .map_err(|e| GenericError::from(e));
    }

    let path: Vec<&str> = req
        .uri()
        .path()
        .splitn(3, "/")
        .filter(|s| !s.is_empty())
        .collect();

    if path.is_empty() {
        return Ok(Response::builder().status(404).body(Full::new(Bytes::new()))?);
    }

    let key;
    let uri;
    match path.len() {
        3 => {
            uri = Some(path[2]);
            key = link::new_with_ns(path[0], path[1]);
        }
        2 => {
            uri = Some(path[1]);
            key = link::new(path[0])
        }
        1 => {
            uri = None;
            key = link::new(path[0]);
        }
        _ => {
            return Ok(Response::builder().status(404).body(Full::new(Bytes::new()))?);
        }
    };

    match req.method() {
        &Method::GET => {
            let authorized = if key.key.starts_with("_") {
                req.headers()
                    .get("authorization")
                    .and_then(|auth| auth.to_str().ok())
                    .map(|auth| {
                        // check the password is valid by assuming a constant username
                        auth.ends_with(secret.as_str())
                    })
                    .unwrap_or_default()
            } else {
                true
            };

            match authorized {
                true => {
                    let db = store.read().map_err(|_| AppError::LockPoisoned)?;
                    let url = db
                        .read_version(&key.to_string(), key.version)
                        .unwrap_or_else(|| "http://www.google.com".to_string());

                    Ok(Response::builder()
                        .status(302)
                        .header("Location", url)
                        .body(Full::new(Bytes::new()))?)
                }
                _ => Ok(Response::builder()
                    .status(401)
                    .header("WWW-Authenticate", "Basic")
                    .body(Full::new(Bytes::new()))?),
            }
        }
        &Method::POST => match uri {
            Some(v) => {
                match store.write().map_err(|_| AppError::LockPoisoned)?.write(&key.to_string(), v) {
                    Ok(_) => Ok(Response::builder().status(200).body(Full::new(Bytes::new()))?),
                    Err(_) => Ok(Response::builder().status(500).body(Full::new(Bytes::new()))?),
                }
            }
            _ => Ok(Response::builder().status(404).body(Full::new(Bytes::new()))?),
        },
        _ => Ok(Response::builder().status(404).body(Full::new(Bytes::new()))?),
    }
}

async fn shutdown_signal(
    path: &path::Path,
    store: Arc<RwLock<impl db::ShortDb>>,
    gist_backup: &Option<Arc<RwLock<gist::GistBackup>>>,
) {
    // Wait for the CTRL+C signal
    tokio::signal::ctrl_c()
        .await
        .expect("failed to install CTRL+C signal handler");

    info!("Shutdown signal received");

    // Save database to file
    if let Err(e) = save_db(path, Arc::clone(&store)) {
        error!("Failed to save database: {}", e);
    }

    // Trigger final gist backup
    if let Some(gist) = gist_backup {
        let db = store.read().unwrap();
        let db_json = db.ser().unwrap();
        drop(db);
        if let Err(e) = gist.write().unwrap().backup(&db_json).await {
            error!("Final gist backup failed: {}", e);
        }
    }
}

fn save_db(p: &path::Path, store: Arc<RwLock<impl db::ShortDb>>) -> Result<()> {
    let db_json = store.write().map_err(|_| AppError::LockPoisoned)?.ser()?;
    fs::write_file(p, &db_json)?;
    Ok(())
}

#[tokio::main]
pub async fn main() -> Result<()> {
    // Initialize tracing
    let filter = EnvFilter::from_default_env()
        .add_directive(tracing::Level::INFO.into());

    fmt().with_env_filter(filter).init();

    info!("Starting short URL shortener");

    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        return Err(AppError::InvalidInput("A path for persistence is required".into()));
    }

    let path = path::Path::new(&args[1]);
    let port_str = if args.len() == 2 { "9090" } else { &args[2] };

    let port: u16 = port_str
        .parse()
        .map_err(|e| AppError::InvalidInput(format!("Invalid port: {}", e)))?;

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    info!("Database path: {:?}", path);
    info!("Binding to http://{}", addr);

    // Initialize gist backup if GH_TOKEN provided
    let data_dir = path.parent().unwrap_or(path::Path::new("."));
    let mut gist_backup = if let Ok(token) = std::env::var("GH_TOKEN") {
        let mut gist = gist::GistBackup::new(token, data_dir);
        gist.initialize().await?;

        // Try to restore from gist on startup
        if let Ok(remote_db) = gist.restore().await {
            info!("Restoring database from gist");
            let local_db = if path.exists() {
                fs::read_file(path).unwrap_or_else(|_| "{\"db\": {}}".to_string())
            } else {
                "{\"db\": {}}".to_string()
            };
            let merged = gist.merge_databases(&remote_db, &local_db);
            // Save merged database
            tokio::fs::write(path, &merged).await?;
            info!("Database merged and saved");
        }

        Some(Arc::new(RwLock::new(gist)))
    } else {
        info!("GH_TOKEN not set, gist backup disabled");
        None
    };

    // generate random values to use as secret
    let mut f = File::open("/dev/urandom")?;
    let mut secret_bytes = [0u8; 8];
    f.read_exact(&mut secret_bytes)?;
    let secret_num = u64::from_be_bytes(secret_bytes.try_into().unwrap());

    let secret =
        data_encoding::BASE64_NOPAD.encode(format!("m:{:#x}", secret_num).as_bytes());
    debug!("Secret: {:#x}", secret_num);

    let arc_secret = Arc::new(secret);
    let store = Arc::new(RwLock::new({
        let s = if path.exists() {
            fs::read_file(path)?
        } else {
            info!("Creating new database");
            "{\"db\": {}}".to_string()
        };
        let db = db::new_from_ser(&s[..]);
        info!("Database loaded with {} entries", db.list_latest().len());
        db
    }));

    // Spawn periodic backup task (every 5 minutes)
    if let Some(gist) = gist_backup.clone() {
        let store_clone = Arc::clone(&store);
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(300));
            loop {
                interval.tick().await;
                let db_json = {
                    let db = store_clone.read().unwrap();
                    db.ser().unwrap()
                };

                // Backup without holding the lock
                let gist_arc = gist.clone();
                let backup_result = tokio::task::spawn_blocking(move || {
                    let mut gist_writer = gist_arc.write().unwrap();
                    // Clone the data we need
                    let token = gist_writer.token.clone();
                    let gist_url_file = gist_writer.gist_url_file.clone();
                    let gist_url = gist_writer.gist_url.clone();

                    (token, gist_url_file, gist_url)
                })
                .await;

                match backup_result {
                    Ok((token, gist_url_file, gist_url)) => {
                        let mut temp_gist = gist::GistBackup {
                            client: reqwest::Client::new(),
                            token,
                            gist_url_file,
                            gist_url,
                        };

                        match temp_gist.backup(&db_json).await {
                            Ok(_) => {
                                // Update the gist URL if changed
                                if let Some(new_url) = temp_gist.gist_url {
                                    let mut gist_writer = gist.write().unwrap();
                                    gist_writer.gist_url = Some(new_url);
                                }
                            }
                            Err(e) => error!("Periodic backup failed: {}", e),
                        }
                    }
                    Err(e) => error!("Failed to acquire gist lock: {:?}", e),
                }
            }
        });
    }

    let listener = TcpListener::bind(addr).await?;
    info!("Listening on http://{}", addr);

    // Spawn the server with graceful shutdown
    let store_clone = Arc::clone(&store);
    let gist_clone = gist_backup.clone();
    let server_handle = tokio::spawn(async move {
        loop {
            let (stream, _) = listener.accept().await.unwrap();
            let io = TokioIo::new(stream);

            let store = Arc::clone(&store_clone);
            let secret = Arc::clone(&arc_secret);

            tokio::spawn(async move {
                let service = service_fn(move |req| {
                    let store = Arc::clone(&store);
                    let secret = Arc::clone(&secret);
                    router(req, store, secret)
                });

                if let Err(err) = http1::Builder::new()
                    .serve_connection(io, service)
                    .await
                {
                    error!("Error serving connection: {:?}", err);
                }
            });
        }
    });

    // Wait for shutdown signal
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {
            info!("Shutdown signal received");
        }
        _ = server_handle => {
            info!("Server task completed");
        }
    }

    // Save database and trigger final backup
    if let Err(e) = save_db(path, Arc::clone(&store)) {
        error!("Failed to save database: {}", e);
    }

    if let Some(gist) = &gist_backup {
        let db = store.read().unwrap();
        let db_json = db.ser().unwrap();
        drop(db);
        if let Err(e) = gist.write().unwrap().backup(&db_json).await {
            error!("Final gist backup failed: {}", e);
        }
    }

    info!("Shutdown complete");
    Ok(())
}
