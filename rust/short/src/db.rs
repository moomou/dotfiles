use std::collections::HashMap;

use serde::Deserialize;
use serde::Serialize;

pub trait ShortDb {
    fn write(&mut self, k: &str, v: &str) -> Result<(), &str>;
    fn read_latest(&self, k: &str) -> Option<&str>;
    fn read_version(&self, k: &str, version: i32) -> Option<&str>;
    fn ser(&mut self) -> Result<String, serde_json::error::Error>;
}

#[derive(Clone, Serialize, Deserialize, Debug)]
struct MemShortDb {
    // using String to own all the data being referenced
    db: HashMap<String, Vec<String>>,
}

impl ShortDb for MemShortDb {
    fn write(&mut self, k: &str, v: &str) -> Result<(), &str> {
        if !self.db.contains_key(k) {
            self.db.insert(String::from(k), Vec::new());
        }
        self.db.get_mut(k).map(|lnk| lnk.push(String::from(v)));
        Ok(())
    }
    fn read_latest(&self, k: &str) -> Option<&str> {
        if !self.db.contains_key(k) {
            None
        } else {
            self.db[k].last().map(|s| &s[..])
        }
    }
    fn read_version(&self, k: &str, version: i32) -> Option<&str> {
        if !self.db.contains_key(k) {
            return None;
        }

        let idx = (self.db[k].len() - 1) as i32 - version;
        self.db[k].get(idx as usize).map(|s| &s[..])
    }
    fn ser(&mut self) -> Result<String, serde_json::error::Error> {
        serde_json::to_string(&self)
    }
}

pub fn new_from_ser(content: &str) -> impl ShortDb + Clone {
    let db: MemShortDb = serde_json::from_str(content).unwrap();
    return db;
}

pub fn new() -> impl ShortDb + Clone {
    MemShortDb { db: HashMap::new() }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_works() {
        let mut db = MemShortDb { db: HashMap::new() };
        db.write("hi", "goo").unwrap();

        assert_eq!(db.read_latest("hi"), Some("goo"));
        assert_eq!(db.read_latest("nono"), None);

        db.write("hi", "goo2").unwrap();
        assert_eq!(db.read_latest("hi"), Some("goo2"));
        assert_eq!(db.read_version("hi", 0), Some("goo2"));
        assert_eq!(db.read_version("hi", 1), Some("goo"));
        assert_eq!(db.read_version("hi", 2), None);
    }

    #[test]
    fn serde_works() {
        let mut db = MemShortDb { db: HashMap::new() };
        let ser_str = db.ser().unwrap();

        assert_eq!(ser_str, "{\"db\":{}}");
        db.write("hi", "goo2").unwrap();

        assert_eq!(db.ser().unwrap(), "{\"db\":{\"hi\":[\"goo2\"]}}")
    }
}
