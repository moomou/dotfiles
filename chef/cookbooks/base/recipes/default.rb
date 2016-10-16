## TODO: Install n for managing node
## TODO: Install golang
## TODO: Install java

include_recipe "docker::default"

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
    user 'root'
    code <<-EOH
        update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
        update-alternatives --config vi
        update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
        update-alternatives --config vim
        update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
        update-alternatives --config editor
    EOH
end

# Setup my dotfiles
