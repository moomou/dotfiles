package 'nginx'
package 'software-properties-common'

directory '/etc/nginx/snippets' do
    action :create
end

cookbook_file '/etc/nginx/sites-available/default' do
    source 'default'
end

template '/etc/nginx/snippets/ssl-params.conf' do
    source 'ssl-params.conf'
end

# install certbot
package 'certbot'
package 'python3-certbot-nginx'

# generate 2048 bit dhparam.pepm
bash 'generate dhparam' do
    user 'root'
    not_if { File.exist?('/etc/ssl/certs/dhparam.pem' )}
    code <<-EOH
        mkdir -p /etc/ssl/certs/
        sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    EOH
end

node['nginx']['domains'].each do |domain|
    root_url = domain['root_url']
    subdomains = domain['subdomains'].map { |sub| "-d #{sub}.#{root_url} " }.join

    if not domain["no_root_cert"]
      subdomains = "-d #{root_url} " + subdomains
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
            :upstreams => domain['upstreams'],
            :servers => domain['servers'],
            :subdomains => domain['subdomains'],
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

    # Reload nginx at the end
    bash 'reload nginx' do
        code <<-EOH
            systemctl reload nginx
        EOH
    end

    bash 'fetch letsencrypt cert' do
        user 'root'
        code <<-EOH
        certbot certonly  \
          --preferred-challenges http \
          --email 'ppymou+letsencrypt@gmail.com' \
          --agree-tos \
          -n \
          --nginx \
          --cert-name #{root_url} \
          #{subdomains}
        EOH
        # TODO: this doesn't respect changed subdomains
        not_if { File.exist?("/etc/letsencrypt/renewal/#{root_url}.conf") }
    end
end

# Reload nginx at the end
bash 'reload nginx' do
    code <<-EOH
        systemctl reload nginx
    EOH
end
