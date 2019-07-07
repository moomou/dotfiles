bash 'download dotfiles' do
  user 'moomou'
  code <<-EOH
    mkdir -p ~/dev
    cd ~/dev
    git clone https://github.com/moomou/dotfiles
    cd dotfiles
    sudo ./bootstrap.sh
    sudo ./bootstrap_dot.sh
    EOH
end
