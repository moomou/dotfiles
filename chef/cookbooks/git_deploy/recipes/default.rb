directory "/home/git/prod" do
    owner 'git'
    action :create
end

bash 'setup home/git/prod' do
    user 'git'
    code <<-EOH
        cd /home/git/prod
        git init --bare
    EOH
end

template '/home/git/prod/hooks/post-receive' do
    source 'post-receive.erb'
    owner 'git'
    group 'git'
    mode '0755'
    variables({
        'app': node[:git_deploy][:app]
    })
end
