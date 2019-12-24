use {
    futures::{
        // Extension trait for futures 0.1 futures, adding the `.compat()` method
        // which allows us to use `.await` on 0.1 futures.
        compat::Future01CompatExt,
        // Extension traits providing additional methods on futures.
        // `FutureExt` adds methods that work for all futures, whereas
        // `TryFutureExt` adds methods to futures that return `Result` types.
        future::{FutureExt, TryFutureExt},
    },
    hyper::{
        // A function which runs a future to completion using the Hyper runtime.
        rt::run,
        // This function turns a closure which returns a future into an
        // implementation of the the Hyper `Service` trait, which is an
        // asynchronous function from a generic `Request` to a `Response`.
        service::service_fn,

        // Miscellaneous types from Hyper for working with HTTP.
        Body,
        Client,
        Request,
        Response,
        Server,
        Uri,
    },
};

mod db;

fn main() {
    println!("Hello, world!");
    let addr = std::net::SocketAddr::from(([127, 0, 0, 1], 80));
    // Call our `run_server` function, which returns a future.
    // As with every `async fn`, for `run_server` to do anything,
    // the returned future needs to be run. Additionally,
    // we need to convert the returned future from a futures 0.3 future into a
    // futures 0.1 future.
    let futures_03_future = run_server(addr);
    let futures_01_future = futures_03_future.unit_error().boxed().compat();

    // Finally, we can run the future to completion using the `run` function
    // provided by Hyper.
    run(futures_01_future);
}

async fn serve_req(_req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    let r = Response::builder()
        .status(302)
        .header(
            "Location",
            "https://www.reddit.com/r/rust/comments/8ct275/redirect_301_or_302_in_hyper_server/",
        )
        .body(Body::empty())
        .unwrap();
    Ok(r)
}

async fn run_server(addr: std::net::SocketAddr) {
    println!("Listening on http://{}", addr);

    let serve_future =
        Server::bind(&addr).serve(|| service_fn(|req| serve_req(req).boxed().compat()));

    if let Err(e) = serve_future.compat().await {
        eprintln!("server error: {}", e);
    }
}
