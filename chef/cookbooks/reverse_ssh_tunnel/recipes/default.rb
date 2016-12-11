# make sure we have /root/.ssh
directory "/root/.ssh"
directory "/root/.ssh/keys"

# create /root/.ssh/config
cookbook_file "/root/.ssh/config" do
    source "config"
    action :create_if_missing
    mode '0644'
end

# drop in reverse ssh proxy supervisord via droplet
cookbook_file "/etc/supervisor/conf.d/do-tunnel.conf" do
	source "do-tunnel.conf"
	mode '0644'
	notifies :reload, "service[supervisor]"
end

log 'You must drop droplet.rsa in /root/.ssh/key manually' do
  level :warn
end
