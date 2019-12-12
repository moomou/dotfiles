use std::env;
use std::path;
use std::sync::{Arc, RwLock};

use hyper::service::{make_service_fn, service_fn};
use hyper::{Body, Method, Request, Response, Server};

mod db;
mod fs;
mod link;

type GenericError = Box<dyn std::error::Error + Send + Sync>;
type Result<T> = std::result::Result<T, GenericError>;

async fn router(
    req: Request<Body>,
    store: Arc<RwLock<impl db::ShortDb>>,
) -> Result<Response<Body>> {
    let path: Vec<&str> = req
        .uri()
        .path()
        .splitn(3, "/")
        .filter(|s| !s.is_empty())
        .collect();

    match req.method() {
        &Method::GET => {
            let l = if path.len() == 1 {
                link::new(path[0])
            } else if path.len() == 2 {
                match path[1].parse::<i32>() {
                    Ok(v) => link::new(path[0]).with_version(v),
                    Err(_) => link::new_with_ns(path[0], path[1]),
                }
            } else {
                link::new_with_ns(path[0], path[1]).with_version(path[2].parse()?)
            };

            Ok(Response::builder()
                .status(302)
                .header(
                    "Location",
                    store
                        .read()
                        .unwrap()
                        .read_version(&l.to_string(), l.version)
                        .unwrap_or("http://www.google.com"),
                )
                .body(Body::empty())?)
        }
        &Method::POST => {
            let uri;
            let l = if path.len() == 3 {
                uri = path[2];
                link::new_with_ns(path[0], path[1])
            } else {
                uri = path[1];
                link::new(path[0])
            };

            match store.write().unwrap().write(&l.to_string(), uri) {
                Ok(_) => Ok(Response::builder().status(200).body(Body::empty())?),
                Err(_) => Ok(Response::builder().status(500).body(Body::empty())?),
            }
        }
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

    let db_inst = {
        let s;
        if path.exists() {
            s = fs::read_file(path).unwrap();
        } else {
            // TODO: remove hardcoded input
            s = "{\"db\": {}}".to_string();
        }
        db::new_from_ser(&s[..])
    };
    let store = Arc::new(RwLock::new(db_inst));

    let service = make_service_fn(|_| {
        let store = Arc::clone(&store);
        async {
            Ok::<_, GenericError>(service_fn(move |req| {
                // Clone again to ensure that store outlives this closure.
                router(req, store.to_owned())
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
