use thiserror::Error;

/// Main application error type
#[derive(Debug, Error)]
pub enum AppError {
    #[error("Database error: {0}")]
    Database(#[from] DbError),

    #[error("Authentication failed")]
    Unauthorized,

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Invalid input: {0}")]
    InvalidInput(String),

    #[error("Gist backup error: {0}")]
    GistBackup(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("HTTP error: {0}")]
    Http(String),

    #[error("Lock poisoned")]
    LockPoisoned,
}

/// Database-specific errors
#[derive(Debug, Error)]
pub enum DbError {
    #[error("Key not found: {0}")]
    KeyNotFound(String),

    #[error("Lock poisoned")]
    LockPoisoned,

    #[error("Serialization failed: {0}")]
    SerializationFailed(String),

    #[error("Write failed: {0}")]
    WriteFailed(String),
}

/// Result type alias for AppError
pub type Result<T> = std::result::Result<T, AppError>;

/// Result type alias for DbError
pub type DbResult<T> = std::result::Result<T, DbError>;
