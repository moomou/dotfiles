const DEFAULT_NS: &str = "default";

#[derive(Debug)]
pub struct Link {
    ns: String,
    pub key: String,
    pub version: i32,
}

impl Link {
    pub fn to_string(&self) -> String {
        format!("{}~{}", self.ns, self.key)
    }
    pub fn with_version(self, version: i32) -> Link {
        Link { version, ..self }
    }
}

pub fn new_with_ns(ns: &str, key: &str) -> Link {
    Link {
        ns: String::from(ns),
        key: String::from(key),
        version: 0,
    }
}

pub fn new(key: &str) -> Link {
    new_with_ns(DEFAULT_NS, key)
}

pub fn new_pub(key: &str) -> Link {
    new_with_ns(DEFAULT_NS, key)
}
