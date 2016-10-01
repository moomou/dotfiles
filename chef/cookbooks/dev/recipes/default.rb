user 'moomou'

apt_update 'Update apt cache' do
    # 24 hours
    frequency 86_400
    action :periodic
end

# TODO: Install n for managing node
# TODO: Install golang
# TODO: Install java

package 'software-properties-common'
package 'silversearcher-ag'
package 'git'
package 'nginx'

package ['python-dev', 'python-pip', 'python3-dev', 'python3-pip']

apt_repository 'nvim' do
    uri 'ppa:neovim-ppa/unstable'
end

package 'neovim'
bash 'update pref' do
    code<<-EOH
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
    sudo update-alternatives --config vi
    sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
    sudo update-alternatives --config vim
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    sudo update-alternatives --config editor
    EOH
end

# bare minimum docker installation
docker_installation_package 'default' do
    version '1.12.1'
    action :create
    package_options %q|--force-yes -o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-all'|
end

directory '/home/moomou/dev' do
    owner 'moomou'
    group 'moomou'
    mode '0755'
end

directory '/home/moomou/deploy' do
    owner 'moomou'
    group 'moomou'
    mode '0755'
end

# Setup my dotfiles
