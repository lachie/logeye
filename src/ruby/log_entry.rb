require 'pp'

class LogEntry < OSX::NSObject
  kvc_reader :http_code_series
  
  def self.entryWithRingbarkerEntry(ringbarker_entry)
    alloc.initWithRingbarkerEntry(ringbarker_entry)
  end
  
  def self.image(name)
    #OSX::NSImage.alloc.initWithContentsOfFile(OSX::NSBundle.mainBundle.pathForResource_ofType(name,'png'))
    OSX::NSBundle.mainBundle.pathForResource_ofType(name,'png')
  end
  
  def self.image_for_code(code)
    case code
    when 5 then @@error_image     ||= image('red_spot')
    when 4 then @@not_found_image ||= image('orange_spot')
    when 3 then @@redir_image     ||= image('blue_spot')
    when 2 then @@ok_image        ||= image('green_spot')
    else
      @@no_image ||= image('gray_spot')
    end
  end
  
  def initWithRingbarkerEntry(e)
    if init
      @entry = e
      @index = e.index
      
      @http_code_series = (e.http_code.to_i.div(100) rescue 0)
      @http_code_series = 0 unless (2..5).include? @http_code_series
      
      return self
    end
  end
  
  def rbValueForKey(key)
    return @index if key == 'index'
    
    return self.http_code_series if key == 'http_code_series'
    
    if @entry.fluff? && !key.hasPrefix("requested_at")      
      value = if key == 'controller'
                '[non-request]'
              elsif key == 'icon'
                self.class.image_for_code('000')
              else
                ""
              end

      return value
    end
    
    case key
    when "icon"
      self.class.image_for_code(self.http_code_series)
    when 'requested_at_time'
      @requested_at_time ||= @entry.requested_at.strftime('%H:%M:%S')
    when 'requested_at_date'
      @requested_at_date ||= @entry.requested_at.strftime('%d-%m-%Y')
    else
      @entry.send(key)
    end
  end
  
  def to_json
    @details ||= @entry.lines.collect {|line| parse_detail(line)}.compact
    
    #@details.each {|p| puts p}
    
    hash = @entry.fluff? ? {
      :details => @details
    } : {
      :controller => @entry.controller,
      :action => @entry.action,
      :ip => @entry.ip,
      :verb => @entry.verb,
      :requested_at => @entry.requested_at,
      :http_code => @entry.http_code,
      
      :session_id => @session_id,
      :parameters => @params,
      
      :details => @details 
    }
    
    JSON.generate(hash)
  end
  
  def dump_details
    puts "details"
    @entry.lines.each {|l| puts l}
  end
  
  SESSION_ID_RE = /\s+Session ID: ([a-zA-Z\d]+)/
  PARAMS_RE     = /^\s+Parameters: (.*)$/
  BACKTRACE_RE  = %r{^\s{4}([\w/\.-]+):(\d+)(?:|:in `(.+)')$}
  
  def parse_detail line
    if line.empty? || line.strip.empty?
      return nil
    end
    
    line.gsub!('<','&lt;')
    line.gsub!('>','&gt;')
    
    return parse_sql(line) if line.include? ?\e
    return parse_render(line) if line.starts_with? 'Render'
    
    case line
    when BACKTRACE_RE  then set_backtrace(*$~)
    when SESSION_ID_RE then set_session_id(*$~)
    when PARAMS_RE     then set_params(*$~)
    else
      {:text => line}
    end
  end
  
  # de-ansi !
  CSI = /\e\[([\d;]+)m([^\e]*)/
  SQL_RE = %r{
    (.*?)
    \(([^\(\)]+)\)
    (.*)
  }x
  
  def parse_sql(line)
    # User Load (0.000452)SELECT * FROM users WHERE (users.`remember_token` = '3bc74ce14857e55cdd4522608d30cd1390ce261e'
    
    out = line.gsub(/\e\[[\d;]+m/,'')
    
    if m = out.match(SQL_RE)
      _,name,time,sql = *m
      {:kind => 'sql', :sql => sql,:name => name,:time => time}
    else
      {:text => out}
    end
  end
  
  RENDER_RE = %r{
    Rendered
    \s+
    ([\w\-\./]+)
    \s+
    \(
    ([\d\.]+)
    \)
    }x
  
  RENDERING_WITHIN_RE = %r{
    Rendering
    \s+
    ([\w\-\./]+)
    \s+
    within
    \s+
    ([\w\-\./]+)
  }x
  
  RENDERING_RE = %r{
    Rendering
    \s+
    ([\w\-\./]+)
  }x
  
  def parse_render(line)
    if m = line.match(RENDER_RE)
      _,template,time = *m
      return {:kind => 'render',:template => template, :time => time, :tense => 'Rendered'}
    end
    
    if m = line.match(RENDERING_WITHIN_RE)
      _,template,within = *m
      return {:kind => 'render',:template => template, :within => within, :tense => 'Rendering'}
    end
    
    if m = line.match(RENDERING_RE)
      _,template = *m
      return {:kind => 'render',:template => template, :tense => 'Rendering'}
    end

    
  rescue 
    puts "failed to parse render line: #{line}"
    raise $!
  end
  
  def set_backtrace(_,path,line,method)
    path_kind,short_path = RubyInfo.classify_path(path)
    
    gem = nil
    if path_kind == :gem
      gem        = short_path[0]
      short_path = short_path[1]
    elsif path_kind == :app
      path = File.join('RAILS_ROOT',short_path)
    end
    
    {:kind => 'backtrace', :path => path, :short_path => short_path, :line => line, :method => method, :path_kind => path_kind, :gem => gem}
  end
  
  def set_session_id(_,id)
    @session_id = id
    nil
  end
  
  CONTROLLER_RE = /"controller"=&gt;"([^"]+)"/
  
  def set_params(_,params)
    @params = params.strip
    
    _,@nested_controller = *@params.match(CONTROLLER_RE)

    @nested_controller = nil unless @nested_controller && !@nested_controller.strip.empty?

    nil
  end
  
  def controllerName
    return "#{@nested_controller}_controller" if @nested_controller
    
    if @entry.controller == 'ApplicationController'
      'application'
    else
      "#{@entry.controller[0..-11].downcase}_controller"
    end
  end
  
  def controllerPath
    File.join('app','controllers',controllerName) + '.rb'
  end
end