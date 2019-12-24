use std::collections::{HashMap, LinkedList};

pub trait ShortDb {
    fn write(&mut self, k: &str, v: &str) -> Result<(), &str>;
    fn read_latest(&self, k: &str) -> Option<&str>;
    fn read_version(&self, k: &str, version: i32) -> Option<&str>;
}

struct MemShortDb {
    // using String to own all the data being referenced
    db: HashMap<String, LinkedList<String>>,
}

impl ShortDb for MemShortDb {
    fn write(&mut self, k: &str, v: &str) -> Result<(), &str> {
        if !self.db.contains_key(k) {
            self.db.insert(String::from(k), LinkedList::new());
        }
        self.db
            .get_mut(k)
            .map(|lnk| lnk.push_front(String::from(v)));
        Ok(())
    }
    fn read_latest(&self, k: &str) -> Option<&str> {
        if !self.db.contains_key(k) {
            None
        } else {
            self.db[k].front().map(|s| &s[..])
        }
    }
    fn read_version(&self, k: &str, version: i32) -> Option<&str> {
        if !self.db.contains_key(k) {
            return None;
        }

        let mut count = version;
        for n in self.db[k].iter() {
            if count == 0 {
                return Some(&n);
            }
            count -= 1;
        }
        None
    }
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
        assert_eq!(db.read_version("hi", 1), Some("goo"));
        assert_eq!(db.read_version("hi", 2), None);
    }
}
