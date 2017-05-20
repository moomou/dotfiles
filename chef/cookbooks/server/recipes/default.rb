## TODO: Install n for managing node
## TODO: Install java
include_recipe 'docker::default'
include_recipe 'supervisord::default'

# common tool
package 'software-properties-common'
package 'silversearcher-ag'
package 'git'
package 'gnupg'
package 'redis-tools'
package 'autossh'

# py header
package 'libpython-dev'
package 'libpython2.7-dev'
package 'python-all-dev'
package 'python-pip'
package 'python2.7-dev'
package 'python3-all-dev'
package 'python3-dev'
package 'python3-pip'

# some general dep
package 'binutils'
package 'bison'
package 'build-essential'
package 'bzip2'
package 'gcc'
package 'libbz2-dev'
package 'libncurses5-dev'
package 'libncursesw5-dev'
#package 'libopenssl-devel'
package 'libreadline-dev'
package 'libreadline6'
package 'libreadline6-dev'
package 'libsqlite3-dev'
package 'libssl-dev'
package 'llvm'
package 'make'
package 'mercurial'
package 'openssl'
package 'tmux'
package 'xz-utils'
package 'zlib1g-dev'

# default user - usually `root`
username = node['server']['username']

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


node['server']['users'].each do |user_info|
    username = user_info['username']

    # creat user
    user username
    directory "/home/#{username}" do
        owner username
        group username
        action :create
    end

    # ensure dev exists
    directory "/home/#{username}/dev" do
        mode '0755'
        only_if { username == 'moomou' }
        owner username
        group username
        action :create
    end

    # setup alias and stuff
    bash 'download dotfiles pref' do
        user username
        only_if { username == 'moomou' && !::File.exist?(File.expand_path('~/dev')) }
        code <<-EOH
            git clone https://github.com/moomou/dotfiles.git ~/dev/dotfiles
            cd ~/dev/dotfiles && ./boostrap.sh
        EOH
    end

    bash 'install tools via curl' do
        user username
        code <<-EOH
            echo 'installing n'
            curl -L https://git.io/n-install | bash -s -- -q

            echo 'installing pyenv'
            curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

            echo 'installing gvm (go version manager)'
            (bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)) || true

            echo setting up .fzf...
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install
        EOH
        only_if { username == 'moomou' && !::File.directory?('~/.fzf') }
    end
end
