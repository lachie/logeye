require 'rails_log'

class RailsApp < RailsLog
  
  def base_name
    @base_name ||= File.basename(path)
  end
  
  def read_first
    self.environments = Dir[File.join(path,"log",'*.log')].collect do |file|
      File.basename(file).sub(/\.log$/,'')
    end
  end

  def read
    log "reading rails app"
    log config
    self.environment = config['default_environment']
  end
  
  def config_defaults
    def_env = self.environments.include?('development') ? 'development' : self.environments.first
    
    super.update( :default_environment => def_env )
  end
  
  
  def environment=(env)
    puts "setting environment, kay? #{env}"
    @environment = env

    log = "#{path}/log/#{@environment}.log"
    
    @parser = nil
    
    read_log(log)
  end
  
  def rails_root
    path
  end
end