# increase GC freq to reduce mem usage
file '/etc/systemd/system/k3s.service.env' do
  content 'GOGC=20'
  owner 'root'
  group 'root'
end

raise "Missing required env `GH_CR_RO_TOKEN`:: #{ENV.keys}" if not ENV["GH_CR_RO_TOKEN"]

directory "/etc/rancher/k3s" do
  action :create
end

template '/etc/rancher/k3s/registries.yaml' do
  source 'registries.yaml.erb'
  owner 'root'
  group 'root'
  mode '600'
end

bash 'restart k3s if present' do
  user 'root'
  code <<-EOH
    systemctl restart k3s.service || true
    systemctl restart k3s-agent.service || true
  EOH
end

