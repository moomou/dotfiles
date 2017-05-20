bash 'install docker' do
    user 'root'
    code <<-EOH
        apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
        echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
		apt-get update
        apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
		apt-get install -y docker-engine=1.11.2-0~xenial

        # add default ubuntu user
        sudo usermod -aG docker #{node['server']['username']}
    EOH
    not_if { ::File.exist?('/usr/bin/docker') }
end
