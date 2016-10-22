root = File.absolute_path(File.dirname(__FILE__))

file_cache_path root

cookbook_path [root + '/vendor', root + '/cookbooks']
role_path root + '/roles'
