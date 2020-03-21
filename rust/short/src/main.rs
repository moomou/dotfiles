use std::convert::TryInto;
use std::env;
use std::path;
use std::sync::{Arc, RwLock};

use hyper::service::{make_service_fn, service_fn};
use hyper::{Body, Method, Request, Response, Server};
use std::fs::File;
use std::io::Read;

mod db;
mod fs;
mod link;

type GenericError = Box<dyn std::error::Error + Send + Sync>;
type Result<T> = std::result::Result<T, GenericError>;

async fn router(
    req: Request<Body>,
    store: Arc<RwLock<impl db::ShortDb>>,
    secret: Arc<String>,
) -> Result<Response<Body>> {
    let path: Vec<&str> = req
        .uri()
        .path()
        .splitn(3, "/")
        .filter(|s| !s.is_empty())
        .collect();

    if path.len() == 0 {
        return Ok(Response::builder().status(404).body(Body::empty())?);
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
            return Ok(Response::builder().status(404).body(Body::empty())?);
        }
    };

    match req.method() {
        &Method::GET => {
            let authorized = if key.key.starts_with("_") {
                req.headers()
                    .get("authorization")
                    .map(|auth| {
                        let auth = auth.to_str().expect("invalid auth header");
                        // check the password is valid by assuming a constant username
                        auth.ends_with(secret.as_str())
                    })
                    .unwrap_or_default()
            } else {
                true
            };

            match authorized {
                true => Ok(Response::builder()
                    .status(302)
                    .header(
                        "Location",
                        store
                            .read()
                            .unwrap()
                            .read_version(&key.to_string(), key.version)
                            .unwrap_or("http://www.google.com"),
                    )
                    .body(Body::empty())?),
                _ => Ok(Response::builder()
                    .status(401)
                    .header("WWW-Authenticate", "Basic")
                    .body(Body::empty())?),
            }
        }
        &Method::POST => match uri {
            Some(v) => match store.write().unwrap().write(&key.to_string(), v) {
                Ok(_) => Ok(Response::builder().status(200).body(Body::empty())?),
                Err(_) => Ok(Response::builder().status(500).body(Body::empty())?),
            },
            _ => Ok(Response::builder().status(404).body(Body::empty())?),
        },
        _ => Ok(Response::builder().status(404).body(Body::empty())?),
    }
}

async fn shutdown_signal() {
    // Wait for the CTRL+C signal
    tokio::signal::ctrl_c()
        .await
        .expect("failed to install CTRL+C signal handler");
}

fn save_db(p: &path::Path, store: Arc<RwLock<impl db::ShortDb>>) {
    fs::write_file(p, &store.write().unwrap().ser().unwrap()[..]).unwrap();
}

#[tokio::main]
pub async fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        panic!("A path for persistence is required");
    }

    let path = path::Path::new(&args[1]);
    let port = if args.len() == 2 { "9090" } else { &args[2] };
    let addr = ([127, 0, 0, 1], port.parse().unwrap()).into();
    println!("Starting short persisting to {:?}", path);

    // generate random values to use as secret
    let mut f = File::open("/dev/urandom").unwrap();
    let mut secret = [0u8; 8];
    f.read_exact(&mut secret).unwrap();
    let secret = u64::from_be_bytes(secret.try_into().expect("invalid slice"));

    println!("Secret is {:#x}", secret);
    let secret = data_encoding::BASE64.encode(format!("m:{:#x}", secret).as_bytes());

    let arc_secret = Arc::new(secret);
    let store = Arc::new(RwLock::new({
        let s = if path.exists() {
            fs::read_file(path).unwrap()
        } else {
            // TODO: remove hardcoded input
            "{\"db\": {}}".to_string()
        };
        let s = db::new_from_ser(&s[..]);
        s
    }));

    let service = make_service_fn(|_| {
        let store = Arc::clone(&store);
        let secret = Arc::clone(&arc_secret);
        async {
            Ok::<_, GenericError>(service_fn(move |req| {
                // Make the handler own the store ref
                router(req, store.to_owned(), secret.to_owned())
            }))
        }
    });

    let server = Server::bind(&addr).serve(service);
    let graceful = server.with_graceful_shutdown(shutdown_signal());

    println!("Listening on http://{}", addr);
    if let Err(e) = graceful.await {
        eprintln!("server error: {}", e);
    } else {
        save_db(path, Arc::clone(&store));
    }
}
