git "/etc/repos/ops" do
  repository "ext::ssh -i //home/ubuntu/.ssh/ops_deploy_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no git@github.com %S /moomou/ops.git"
  checkout_branch "master"
  action :sync
end
