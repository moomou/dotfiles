package 'nginx'
package 'letsencrypt'

directory '/etc/nginx/snippets' do
    action :create
end

cookbook_file '/etc/nginx/sites-available/default' do
    source 'default'
end

template '/etc/nginx/snippets/ssl-params.conf' do
    source 'ssl-params.conf'
end

bash 'generate dhparam' do
    user 'root'
    not_if { File.exist?('/etc/ssl/certs/dhparam.pem' )}
    code <<-EOH
        mkdir -p /etc/ssl/certs/
        sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    EOH
end

user = node['nginx']['user']
domains = node['nginx']['domains']
domains.each do |domain|
    root_url = domain['root_url']
    subdomains = domain['subdomains'].map { |sub| "-d #{sub}.#{root_url} " }.join
    subdomains = "-d #{root_url} " + subdomains

    # request
    bash 'setup letsencrypt' do
        user 'root'
        code <<-EOH
        letsencrypt certonly -a webroot \
            --webroot-path=/var/www/html \
            --text \
            --agree-tos \
            --renew-by-default \
            --email #{user} \
            #{subdomains}
        EOH
        # not_if { File.exist?("/etc/letsencrypt/renewal/#{root_url}.conf") }
    end

    # add nginx config
    template "/etc/nginx/snippets/ssl-#{root_url}.conf" do
        source 'ssl.conf.erb'
        variables({
            :root_url => "#{root_url}"
        })
    end

    # create template
    template "/etc/nginx/sites-available/#{root_url}.conf" do
        source 'site.conf.erb'
        variables({
            :root_url => root_url,
            :upstreams => domain.upstreams,
            :servers => domain.servers,
            :subodmains => domain['subdomains'],
        })
    end

    # link to enabled
    link "/etc/nginx/sites-enabled/#{root_url}.conf" do
        to "/etc/nginx/sites-available/#{root_url}.conf"
        not_if { domain['disabled'] }
    end

    # create domain dir
    directory "/var/log/nginx/#{root_url}" do
        owner 'www-data'
        action :create
    end

    # create log dir
    domain['subdomains'].each do |subdomain|
        directory "/var/log/nginx/#{root_url}/#{subdomain}" do
            owner 'www-data'
            action :create
        end
    end
end

# Setup renew job
cron 'renew letsencrypt cert and reload nginx' do
    command 'letsencrypt renew >> /var/log/le-renew.log && systemctl reload nginx'
    hour '2'
    day '1'
end

# Reload nginx at the end
bash 'reload nginx' do
    code <<-EOH
        systemctl reload nginx
    EOH
end
