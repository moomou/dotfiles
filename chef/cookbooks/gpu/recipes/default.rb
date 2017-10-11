include_recipe 'docker::default'
include_recipe 'supervisord::default'

bash 'download and install nvidia drivers' do
  cwd '/tmp'
  user 'root'
  code <<-EOH
    # install CUDA
    wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
    dpkg -i cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
    apt-get update
    apt-get install cuda

    # Install CUDNN versino v5.1
    wget https://storage.googleapis.com/moomou2/dep/cudnn-8.0-linux-x64-v5.1.tgz
    tar -xvf cudnn-8.0-linux-x64-v5.1.tgz
    (
        cd cuda &&  \
        cp lib64/* /usr/local/cuda/lib64 && \
        cp include/* /usr/local/cuda/include
    )

    # recommended by tensorflow
    apt-get install libcupti-dev

    # TODO: relying these to be in dotfiles repo a good idea?
    # echo export LD_LIBRARY_PATH=/usr/local/cuda/lib64/:$LD_LIBRARY_PATH >> ~/.bash_profile
    EOH
end
