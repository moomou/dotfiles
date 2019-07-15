# include_recipe 'docker::default'
# include_recipe 'supervisord::default'

# common tool
package 'ncdu'
package 'python3-venv'
package 'ffmpeg'
package 'hdf5-tools'
package 'software-properties-common'
package 'silversearcher-ag'
package 'jq'
package 'git'
package 'gnupg'
package 'redis-tools'
package 'autossh'
package 'tk-dev'
package 'htop'
package 'unzip'
package 'automake'

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
# package 'libopenssl-devel'
package 'binutils'
package 'bison'
package 'build-essential'
package 'bzip2'
package 'gcc'
package 'libbz2-dev'
package 'liblapack-dev'
package 'libncurses5-dev'
package 'libncursesw5-dev'
package 'libopenblas-dev'
package 'libopencv-dev'
package 'libopenmpi-dev'
package 'libreadline-dev'
package 'libreadline6-dev'
package 'libsndfile1'
package 'libsndfile1-dev'
package 'libsqlite3-dev'
package 'libssl-dev'
package 'llvm'
package 'make'
package 'mercurial'
package 'openssl'
package 'tmux'
package 'xz-utils'
package 'zlib1g-dev'
package 'libmicrohttpd-dev'
package 'libssl-dev'
package 'cmake'
package 'libhwloc-dev'

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
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
    EOH
  not_if 'which gsutil'
end

bash 'install misc' do
  user 'root'
  code <<-EOH
    export DEBIAN_FRONTEND=noninteractive
    sudo pip install --upgrade youtube_dl
    (   # install ripgrep
        cd $(mktemp -d) &&
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb &&
        sudo dpkg -i ripgrep_11.0.1_amd64.deb
    )
    (
        # install bat
        cd $(mktemp -d) &&
        curl -LO https://github.com/sharkdp/bat/releases/download/v0.11.0/bat_0.11.0_amd64.deb &&
        sudo dpkg -i bat_0.11.0_amd64.deb
    )
    EOH
  not_if 'which rg'
end

# TODO: uncomment for debugging
# output="#{Chef::JSONCompat.to_json_pretty(node.to_hash)}"
# log output
