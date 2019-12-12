use std::fs;
use std::io;
use std::path;

pub fn read_file(p: &path::Path) -> io::Result<String> {
    fs::read_to_string(p)
}

pub fn write_file(p: &path::Path, content: &str) -> io::Result<()> {
    fs::write(p, content)
}
