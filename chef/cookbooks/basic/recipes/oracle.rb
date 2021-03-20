# stop snapd
bash 'remove junks' do
  user 'root'
  code <<-EOH
    # snapd
    systemctl stop snapd || true
    systemctl disable snapd || true
    apt purge -y snapd || true
    rm -rf ~/snap || true
    rm -rf /snap || true
    rm -rf /var/snap || true
    rm -rf /var/lib/snapd || true

    # oracle junk
    # oracle-update agent
    systemctl stop snap.oracle-cloud-agent.oracle-cloud-agent-updater.service || true
    systemctl disable snap.oracle-cloud-agent.oracle-cloud-agent-updater.service || true
    systemctl stop snap.oracle-cloud-agent.oracle-cloud-agent.service || true
    systemctl disable snap.oracle-cloud-agent.oracle-cloud-agent.service || true


    EOH
end

bash 'oracle firewall rule' do
  user 'root'
  code <<-EOH
    # oracle firewall rules
    apt install -y firewalld

    # default k3s port
    firewall-cmd --zone=public --permanent --add-port=6443/tcp
    # https
    firewall-cmd --zone=public --permanent --add-port=443/tcp
    # http
    firewall-cmd --zone=public --permanent --add-port=80/tcp
    firewall-cmd --reload
  EOH
end
