username = node['ssh_user']['name']
ssh_filename = node['ssh_user']['ssh_filename']
# TODO: fix the hardcoded path
pub_key = File.read("/home/ubuntu/chef/pubKeys/#{ssh_filename}")

user "#{username}"

directory "/home/#{username}" do
    owner "#{username}"
    group "#{username}"
    action :create
end

directory "/home/#{username}/.ssh" do
    owner "#{username}"
    group "#{username}"
    action :create
    mode '0700'
end

file "/home/#{username}/.ssh/authorized_keys" do
  owner "#{username}"
  group "#{username}"
  content "#{pub_key}"
  action :create_if_missing
  mode '0600'
end
