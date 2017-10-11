include_recipe 'docker::default'
include_recipe 'supervisord::default'

# common tool
package 'ffmpeg'
package 'hdf5-tools'
package 'software-properties-common'
package 'silversearcher-ag'
package 'git'
package 'gnupg'
package 'redis-tools'
package 'autossh'
package 'tk-dev'
package 'htop'

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
package 'libopenblas-dev'
package 'liblapack-dev'
package 'libopencv-dev'
# package 'libopenssl-devel'
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

# setup alias and stuff
bash 'install git lfs' do
  user 'root'
  code <<-EOH
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
        apt-get install git-lfs
        git lfs install
    EOH
end

bash 'install gsutil' do
  user 'root'
  code <<-EOH
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo apt-get update && sudo apt-get install google-cloud-sdk
    EOH
end

bash 'install misc' do
  user 'root'
  code <<-EOH
    sudo pip install --upgrade youtube_dl
    EOH
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

  bash 'install pyenv and python3' do
    user username
    code <<-EOH
        export PYENV_ROOT=/home/#{username}/.pyenv

        apt-get update && \
            apt-get install -y git mercurial build-essential libssl-dev libbz2-dev libreadline-dev libsqlite3-dev curl tk-dev && \
            curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

        pyenv install 3.6.3
        env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.3

        pyenv global 3.6.3
      EOH
  end

  bash 'install misc. tools' do
    user username
    code <<-EOH
        echo 'installing n'
        type n >/dev/null 2>&1 || curl -L https://git.io/n-install | bash -s -- -q

        echo 'installing gvm (go version manager)'
        type gvm >/dev/null 2>&1 || (bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer))

        echo setting up .fzf...
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        yes | ~/.fzf/install
   EOH
    only_if { !::File.directory?('~/.fzf') }
  end

  # setup alias and stuff
  bash 'download dotfiles pref' do
    user username
    only_if { username == 'moomou' && !::File.exist?(File.expand_path('~/dev/dotfiles')) }
    code <<-EOH
       git clone https://github.com/moomou/dotfiles.git ~/dev/dotfiles
       cd ~/dev/dotfiles && ./boostrap.sh
      EOH
  end
end
