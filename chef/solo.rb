root = File.absolute_path(File.dirname(__FILE__))

file_cache_path root

cookbook_path [root + '/cookbooks', root + '/vendor']
role_path root + '/roles'
