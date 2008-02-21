class Log < OSX::NSObject
  
  class << self
    def app_support
      unless @app_support
        @app_support = File.expand_path("#{ENV['HOME']}/Library/Application Support/Logeye")
        FileUtils::mkdir_p(@app_support) rescue nil
      end
      @app_support
    end
  
    def logFromPath(path)
      if path[/\.log$/]
        RailsLog.alloc.initWithPath(path)
      else
        RailsApp.alloc.initWithPath(path)
      end
    end
  end
  
  def initWithPath(path)
    OSX::NSLog "initting Log with path [#{self.class}]"
    
    if init
      @path = path
      read_first
      return self
    end
  end

  def config_path
    rp = @path.sub(/^\//,'').gsub('/','_') + '.yaml'
    File.join(Log.app_support,rp)
  end
  
  def config_defaults
    {
      :prescan => false
    }
  end
  
  def first_time?
    !File.exist?( config_path)
  end
  
  def config
    @config ||= (YAML.load_file(config_path) rescue config_defaults).to_ns
  end
  
  def willChangeConfig
    puts "config"
    p config
    @old_config = config.dup
  end
  
  def didChangeConfig
    puts "writing config to #{config_path}"
    open(config_path,'w') do |f|
      f << @config.to_ruby.to_yaml
    end
  end
  
end