# Short

A short link server with basic auth for protecting sensitive links, GitHub Gist backup, and a private LIST API - written in Rust.

**A Rust learning project.**

## Features

### 🔐 Password Protected Links
Links starting with `_` are protected by a server-generated password using HTTP Basic Auth.

### 📂 Namespaced Links
Organize links under different namespaces to avoid conflicts:

```bash
# Create a link in the 'work' namespace
curl -XPOST http://go/work/jenkins/https://jenkins.example.com

# Create a link in the default namespace
curl -XPOST http://go/mylink/https://example.com
```

### 🔄 String Expansion
Save URLs with `<s>` placeholder for dynamic string expansion:

```bash
# Save with <s> placeholder
curl -XPOST http://go/g/http://google.com/?q=<s>

# Access with expansion
curl -L http://go/g/hello  # Redirects to http://google.com/?q=hello
curl -L http://go/g         # Redirects to http://google.com/?q=
```

### 💾 GitHub Gist Backup (NEW)
Automatically backup your database to a private GitHub Gist:

```bash
# Set GitHub token with gist scope
export GH_TOKEN=ghp_your_github_token_here

# Start the server - backups happen every 5 minutes + on shutdown
./short /path/to/data.json 9090
```

**Features:**
- **Automatic backups**: Every 5 minutes in the background
- **Shutdown backups**: Final backup when server stops (CTRL+C)
- **Startup restoration**: Automatically restores and merges databases on startup
- **Merge strategy**: Local database wins on conflicts
- **Private gists**: Only accessible to you
- **No configuration needed**: Just set `GH_TOKEN` environment variable

### 📋 Private LIST API (NEW)
List all links via a private JSON API endpoint:

```bash
# Get the secret from server startup logs
SECRET=<your_secret_here>

# List all links
curl -H "Authorization: Basic m:$SECRET" http://localhost:9090/_api/list

# Filter by namespace
curl -H "Authorization: Basic m:$SECRET" \
  "http://localhost:9090/_api/list?namespace=work"

# Filter by key prefix
curl -H "Authorization: Basic m:$SECRET" \
  "http://localhost:9090/_api/list?prefix=git"

# Include version history
curl -H "Authorization: Basic m:$SECRET" \
  "http://localhost:9090/_api/list?versions=true&limit=50"
```

**Query Parameters:**
- `namespace` - Filter by namespace
- `prefix` - Filter keys by prefix
- `limit` - Max results (default: 100, max: 1000)
- `versions` - Include version history (default: false)

**Response Format:**
```json
{
  "success": true,
  "data": {
    "total_keys": 2,
    "filtered_keys": 2,
    "links": [
      {
        "key": "default~git",
        "namespace": "default",
        "short_key": "git",
        "url": "https://github.com/user/repo",
        "version": 0,
        "version_count": 1,
        "created_at": "2026-01-02T18:30:00Z",
        "versions": ["https://github.com/user/repo"]
      }
    ]
  }
}
```

## Usage

### Starting the Server

```bash
# Basic usage
./short /path/to/data.json 9090

# With GitHub Gist backup
export GH_TOKEN=ghp_your_github_token
./short /var/lib/short/db.json 9090
```

The server will:
1. Display a generated secret for protected links (in hex format)
2. Load existing database or create new one
3. Restore from GitHub Gist if `GH_TOKEN` is set and gist exists
4. Start listening on the specified port
5. Begin periodic backups every 5 minutes (if `GH_TOKEN` set)

### Creating Links

```bash
# Public link
curl -XPOST http://localhost:9090/mylink/https://example.com

# Protected link (requires authentication)
curl -XPOST http://localhost:9090/_private/https://internal.company.com

# Namespaced link
curl -XPOST http://localhost:9090/docs/readme/https://github.com/user/repo
```

### Accessing Links

```bash
# Public link
curl -L http://localhost:9090/mylink

# Protected link (requires auth with secret from startup logs)
SECRET=<secret_from_logs>
curl -L -H "Authorization: Basic m:$SECRET" http://localhost:9090/_private

# String expansion
curl -L http://localhost:9090/g/search-term
```

### Environment Variables

- `GH_TOKEN` - (Optional) GitHub personal access token with `gist` scope for automated backups

### Logging

The server uses structured logging with `tracing`. Logs include:
- INFO: Normal operations (startup, requests, backups)
- DEBUG: Detailed diagnostics
- WARN: Recoverable issues
- ERROR: Critical failures

## Technical Details

- **Language**: Rust
- **Runtime**: Tokio 1.x (async)
- **HTTP Server**: Hyper 1.6
- **Storage**: In-memory HashMap with JSON persistence
- **Backup**: GitHub Gist API via reqwest
- **Logging**: tracing and tracing-subscriber

## Project Structure

```
src/
├── main.rs      # HTTP server, routing
├── db.rs        # Database trait and implementation
├── link.rs      # Link key parsing
├── fs.rs        # File I/O
├── gist.rs      # GitHub Gist backup/restore (NEW)
├── api.rs       # LIST API handlers (NEW)
└── error.rs     # Error types (NEW)
```

## Development

```bash
# Build
cargo build --release

# Run tests
cargo test

# Check
cargo check
```


