class RailsLog < Log
  #kvc_accessor :entries, :environment, :environments, :path
  
  kvc_accessor :environment
  attr_accessor :environments
  attr_accessor :path, :logfile
  attr_reader :entries
  
  def base_name
    @base_name ||= File.basename(path)
  end
  
  def rails_root
    nil
  end
  
  def read_first
  end
  
  def dealloc
    puts "Ruby deallocate #{self.class}"
    @logfile.close if @logfile && !@logfile.closed?
    super_dealloc
  end
  
  def parser
    @parser ||= Ringbarker::Parser.new
  end
  
  def have_environments?
    environments && !environments.empty?
  end
  
  def read
    read_log(@path)
  end

  def read_log(log=@path)
    clear!
    willChangeValueForKey('entries')

    log "reading log #{log}"
    log "entries: #{@entries.count}"
  
    @logfile = File.open(log)
  
    unless @logfile
      raise "failed to open #{log}"
    end
    

    if prescan?
      prescan_log
    else
      seek_end
    end
    
    cleanup_dequeue_log
    setup_timers

    puts "done reading log"
    OSX::NSLog("finished reading log")
    didChangeValueForKey('entries')
  end
  
  def clear!
    willChangeValueForKey('entries')
    log "clearing!"
    @entries ||= OSX::NSMutableArray.array
    @entries.removeAllObjects
    didChangeValueForKey('entries')
  end
  
  def prescan?
    config['prescan'].to_ruby
  end
  
  def didChangeConfig
    super
    read if @old_config['prescan'] != config['prescan']
  end
  
  def setup_timers
    stop_tailing

    @tail_timer    = OSX::NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(1.0,self,'tail:',nil,true)
    @cleanup_timer = OSX::NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(3.0,self,'tailCleanup:',nil,true)
  end
  
  def stop_tailing
    puts "stopping tailing #{self}"
    @tail_timer.invalidate if @tail_timer
    @cleanup_timer.invalidate if @cleanup_timer

    @tail_timer = nil
    @cleanup_timer = nil
  end
  
  def add_entry(e)
    willChangeValueForKey('entries')
    @entries.addObject LogEntry.alloc.initWithRingbarkerEntry(e)
    didChangeValueForKey('entries')
  end
  
  def prescan_log
    OSX::NSLog("prescanning log, eh? #{self.class} #{@logfile}")
    
    @logfile.each do |line|
      parser << line.to_s
      parser.dequeue.each do |r|
        @entries.addObject LogEntry.alloc.initWithRingbarkerEntry(r)
      end
    end
  end
  
  def seek_end
    @logfile.seek(0, IO::SEEK_END)
  end


  def dequeue_log(rearrange=false)
    parser.dequeue.each do |r|
      puts "dq"
      add_entry r
    end
  end

  def cleanup_dequeue_log
    # parser.dump
    
    parser.cleanup.dequeue.each do |r|
      puts "clean dq"
      add_entry r
    end
  end

  def tail(timer)
  
    while line = @logfile.gets
      parser << line.to_s
      dequeue_log
    end
  
  rescue EOFError
    @logfile.seek(0, File::SEEK_CUR)
  rescue Errno::ENOENT, Errno::ESTALE
    # TODO reopen
  end

  def tailCleanup(timer)
    cleanup_dequeue_log
  end
end