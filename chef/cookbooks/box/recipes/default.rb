## TODO: Install n for managing node
## TODO: Install golang
## TODO: Install java
include_recipe "docker::default"
include_recipe "supervisord::default"

# common tool
package 'software-properties-common'
package 'silversearcher-ag'
package 'git'
package 'gnupg'
package 'redis-tools'
package 'autossh'

# py header
package 'libpython2.7-dev'
package 'libpython-dev'
package 'python2.7-dev'
package 'python-pip'
package 'python3-dev'
package 'python3-pip'

# some general dep
package 'mercurial'
package 'make'
package 'binutils'
package 'bison'
package 'gcc'
package 'build-essential'
package 'tmux'

username=node['box']["username"]

# debugging
# output="#{Chef::JSONCompat.to_json_pretty(node.to_hash)}"
# log output

apt_repository 'nvim' do
    uri 'ppa:neovim-ppa/unstable'
end
apt_repository 'git' do
    uri 'ppa:git-core/ppa'
end

package 'git' do
    action :upgrade
end
package 'neovim' do
    action :upgrade
end

bash 'install tools via curl' do
    user "#{username}"
    code <<-EOH
        echo 'installing n'
        curl -L https://git.io/n-install | bash -s -- -q

        echo 'installing pyenv'
        curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

        echo 'installing gvm (go version manager)'
        (bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)) || true
    EOH
    not_if 'which gvm', :user => "#{username}"
end

#bash 'update pref' do
    #user 'root'
    #code <<-EOH
        #update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
        #update-alternatives --config vi
        #update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
        #update-alternatives --config vim
        #update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
        #update-alternatives --config editor
    #EOH
#end

# create git user
user 'git'
directory "/home/git" do
    owner 'git'
    action :create
end

# creates me and home dir
user "#{username}"
directory "/home/#{username}" do
    # owner "#{username}"
    # group "#{username}"
    action :create
end

# ensure dev exists
directory "/home/#{username}/dev" do
    mode '0755'
    not_if { username == "root" }
    # owner "#{username}"
    # group "#{username}"
    action :create
end

# setup alias and stuff
bash 'download dotfiles pref' do
    user "#{username}"
    not_if { ::File.exist?(File.expand_path('~/dev')) }
    code <<-EOH
        git clone https://github.com/moomou/dotfiles.git ~/dev/
        cd ~/dev/dotfiles && ./boostrap.sh
    EOH
end
