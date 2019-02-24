
bash 'install docker' do
  user 'root'
  code <<-EOH
        DIR=$(mktemp -d)

        pushd $DIR

        # TODO(moomou): make this more dynamic
        FILE=docker-ce_18.06.3~ce~3-0~ubuntu_amd64.deb
        wget https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/$FILE
        dpkg -i $FILE
        docker run hell-world

        popd

        # add default ubuntu user
        sudo usermod -aG docker #{node['server']['username']} || true
    EOH
  not_if '[[ $(docker version --format "{{.Server.Version}}") == "18.06.3-ce" ]]'
end
