version="2.9a"

bash "download and install tmux #{version}" do
  user 'root'
  code <<-EOH
    TMUX_DIR=$(mktemp -d)
    git clone https://github.com/tmux/tmux.git $TMUX_DIR
    pushd $TMUX_DIR
    git checkout #{version}

    apt-get install libevent-dev

    sh autogen.sh
    ./configure && make
    make install
    popd
    EOH
end
