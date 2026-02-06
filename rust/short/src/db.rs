use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use crate::error::{DbError, DbResult};

pub trait ShortDb {
    // create new mapping
    fn write(&mut self, k: &str, v: &str) -> DbResult<()>;
    // delete a key
    fn delete(&mut self, k: &str) -> DbResult<()>;
    // get latest
    fn read_latest(&self, k: &str) -> Option<String>;
    // read a particular version
    fn read_version(&self, k: &str, version: i32) -> Option<String>;
    // list all urls stored
    fn list_latest(&self) -> Vec<(String, String)>;

    fn ser(&self) -> DbResult<String>;
}

#[derive(Clone, Serialize, Deserialize, Debug)]
struct MemShortDb {
    // using String to own all the data being referenced
    db: HashMap<String, Vec<String>>,
}

impl ShortDb for MemShortDb {
    fn list_latest(&self) -> Vec<(String, String)> {
        let mut mapping = Vec::new();
        for (k, vals) in self.db.iter() {
            if let Some(val) = vals.last() {
                mapping.push((k.clone(), val.clone()));
            }
        }

        mapping.sort();
        mapping
    }

    fn delete(&mut self, key: &str) -> DbResult<()> {
        if self.db.contains_key(key) {
            self.db.remove(key);
        }
        Ok(())
    }

    fn write(&mut self, k: &str, v: &str) -> DbResult<()> {
        if !self.db.contains_key(k) {
            self.db.insert(String::from(k), Vec::new());
        }
        if let Some(lnk) = self.db.get_mut(k) {
            lnk.push(String::from(v));
        }
        Ok(())
    }

    fn read_latest(&self, k: &str) -> Option<String> {
        self.db.get(k)?.last().cloned()
    }

    fn read_version(&self, k: &str, version: i32) -> Option<String> {
        let vals = self.db.get(k)?;
        let idx = (vals.len() - 1) as i32 - version;
        if idx < 0 || idx >= vals.len() as i32 {
            None
        } else {
            vals.get(idx as usize).cloned()
        }
    }

    fn ser(&self) -> DbResult<String> {
        serde_json::to_string(&self)
            .map_err(|e| DbError::SerializationFailed(e.to_string()))
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
        let mut db = new();
        db.write("hi", "goo").unwrap();

        assert_eq!(db.read_latest("hi"), Some("goo".to_string()));
        assert_eq!(db.read_latest("nono"), None);

        db.write("hi", "goo2").unwrap();
        assert_eq!(db.read_latest("hi"), Some("goo2".to_string()));
        assert_eq!(db.read_version("hi", 0), Some("goo2".to_string()));
        assert_eq!(db.read_version("hi", 1), Some("goo".to_string()));
        assert_eq!(db.read_version("hi", 2), None);

        assert_eq!(db.list_latest(), vec!(("hi".to_string(), "goo2".to_string())));
    }

    #[test]
    fn serde_works() {
        let mut db = new();
        let ser_str = db.ser().unwrap();

        assert_eq!(ser_str, "{\"db\":{}}");
        db.write("hi", "goo2").unwrap();

        assert_eq!(db.ser().unwrap(), "{\"db\":{\"hi\":[\"goo2\"]}}")
    }
}
