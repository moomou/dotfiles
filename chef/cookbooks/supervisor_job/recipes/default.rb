configs = node['supervisor_job']['configs']

configs.each do |config|
    supervisord_program "#{config['name']}" do
        command "#{config['command']}"
    end
end
