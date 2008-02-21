class RubyInfo
  class << self
    @@ruby = nil
    @@rubylibdir = nil
    @@gemsdir = nil
    
    def ruby(rb,*libs)
      l = libs.collect {|lib| "-r#{lib}"} * ' '
      `ruby #{l} -e "print #{rb}"`
    end
    
    def ruby?
      if @@ruby.nil?
        system("ruby -e'true'")        
        @@ruby = !!$?.success?
      end

      @@ruby
    end
    
    def gather_info
      unless @@rubylibdir
        @@rubylibdir = ruby("Config::CONFIG['rubylibdir']", 'rbconfig')
        @@sitelibdir = ruby("Config::CONFIG['sitelibdir']", 'rbconfig')
        @@gemsdir    = ruby("Gem.dir",'rubygems')+'/gems'
      end
    end
    
    def subpath(root,full_path)
      full_path[root.length+1..-1] || ''
    end
    
    def classify_path(path)
      return unless ruby?
      gather_info
      
      clean_path = path.sub(/^[\.\/]+/,'')
      
      if path.starts_with?(@@gemsdir)
        gem = subpath(@@gemsdir,path)
        m = gem.split('/lib/',2)
        [:gem,m]
        
      elsif path.starts_with?(@@rubylibdir)
        [:lib, subpath(@@rubylibdir,path)]
        
      elsif path.starts_with?(@@sitelibdir)
        [:lib, subpath(@@sitelibdir,path)]
        
      elsif clean_path.starts_with?('app/') || clean_path.starts_with?('lib/') || clean_path.starts_with?('vendor')
        [:app,clean_path]
        
      else
        [:unknown,path]
        
      end
    end
  end
end