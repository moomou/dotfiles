include_recipe 'docker::default'
include_recipe 'supervisord::default'

bash 'download and install nvidia drivers' do
  cwd '/tmp'
  user 'root'
  code <<-EOH
    # install CUDA
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
    dpkg -i cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
    apt-get update
    apt-get install -y cuda-8-0

    # Create cuda symlink
    ln -s /usr/local/cuda-8.0 /usr/local/cuda

    # Install CUDNN versino v6.0
    CUDNN_TAR_FILE="cudnn-8.0-linux-x64-v6.0.tgz"
    wget http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/${CUDNN_TAR_FILE}
    tar -xzvf ${CUDNN_TAR_FILE}
    (
        cd cuda &&  \
        cp lib64/* /usr/local/cuda/lib64 && \
        cp include/* /usr/local/cuda/include
    )

    # recommended by tensorflow
    apt-get install -y libcupti-dev

    # nccl
    wget https://storage.googleapis.com/mlab9/dep/nccl-repo-ubuntu1604-2.0.5-ga-cuda8.0_2-1_amd64.deb
    dpkg -i nccl-repo-ubuntu1604-2.0.5-ga-cuda8.0_2-1_amd64.deb
    apt update
    apt install -y libnccl2=2.0.5-2+cuda8.0 \
         libnccl-dev=2.0.5-2+cuda8.0

    # TODO: relying these to be in dotfiles repo a good idea?
    # echo export LD_LIBRARY_PATH=/usr/local/cuda/lib64/:$LD_LIBRARY_PATH >> ~/.bash_profile
    EOH
end

# bash 'download and install openmpi' do
# cwd '/tmp'
# user 'root'
# code <<-EOH
# wget https://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-3.0.0.tar.gz
# gunzip -c openmpi-3.0.0.tar.gz | tar xf -
# cd openmpi-3.0.0
# ./configure --prefix=/usr/local --with-cuda
# make all install
# EOH
# end
