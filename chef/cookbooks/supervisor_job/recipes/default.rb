configs = node['ssh_tunnel']['configs']

configs.each do |config|
    supervisord_program "#{config['name']}" do
        command "#{config['command']}"
    end
end
