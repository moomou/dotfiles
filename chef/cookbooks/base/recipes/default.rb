## TODO: Install n for managing node
## TODO: Install golang
## TODO: Install java

include_recipe "docker::default"
include_recipe "supervisord::default"

package 'software-properties-common'
package 'silversearcher-ag'
package 'git'
package 'redis-tools'

#package 'libpython2.7-dev'
#package 'libpython-dev'
#package 'python2.7-dev'
#package 'python-pip'
#package 'python3-dev'
#package 'python3-pip'

#apt_repository 'nvim' do
    #uri 'ppa:neovim-ppa/unstable'
#end

#package 'neovim'
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

user 'git'
directory "/home/git" do
    owner 'git'
    action :create
end

# Setup my dotfiles
