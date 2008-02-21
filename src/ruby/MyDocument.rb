require 'thread'
require 'ringbarker'# unless const_defined? Ringbarker::Parser
require 'json'
require 'yaml'
require 'fileutils'

OSX.require_framework 'WebKit'

class MyDocument < OSX::NSDocument
  %W{2 3 4 5 x}.each do |n|
    kvc_accessor "icon#{n}x".to_sym, "icon#{n}x_on".to_sym, "filter#{n}x".to_sym
  end
  
  kvc_accessor :log, :log_sorters, :log_selection
  kvc_accessor :filterPredicate

  kvc_depends_on [:filter2x, :filter3x, :filter4x, :filter5x, :filterxx], :filterPredicate
  
  FILTER_MAP = {
    :filter2x => 2,
    :filter3x => 3,
    :filter4x => 4,
    :filter5x => 5,
    :filterxx => 0
  }
  
  ib_outlet :entries_controller, :webview, :table
  
  def windowNibName
    return "MyDocument"
  end
  
  
  def windowControllerDidLoadNib(window_controller)
    super_windowControllerDidLoadNib(window_controller)
    
    window = window_controller.window
    window.setReleasedWhenClosed false
    
    window.setFrameAutosaveName(@read_path)
    
    WindowDelegate.alloc.initForWindow(window_controller.window)
    
    window_controller.setShouldCloseDocument true
  end
  

  def dealloc
    OSX::NSLog "Ruby deallocating MyDocument"
    self.log = nil
    
    # GC.start
    super_dealloc
  end
  
  def observeValueForKeyPath_ofObject_change_context(keyPath, object, change, context)
    if self.log == object
      puts "hey you changed the log, hmmm #{change.to_ruby.inspect}"
      @entries_controller.rearrangeObjects
    else
      super
    end
  end

  def awakeFromNib
    @webview.setResourceLoadDelegate(self)
    @webview.setPolicyDelegate(self)
    @webview.setFrameLoadDelegate(self)
    @webview.setUIDelegate(self)

    base = OSX::NSURL.fileURLWithPath(File.dirname(__FILE__)+"/shell.html")
    html = File.read(File.dirname(__FILE__)+'/shell.html')
    
    @webview.mainFrame.loadHTMLString_baseURL(html,base)
    
    self.log_sorters = [OSX::NSSortDescriptor.alloc.initWithKey_ascending("index",false)]

    %w{2 3 4 5 x}.each do |n|
      self.send("icon#{n}x="    , self.class.icon_for_series(n, false))
      self.send("icon#{n}x_on=" , self.class.icon_for_series(n, true))
    end

  end
  
  
  # NSDocument hook for loading the path
  # note that the actual reading of the resource is defered until after the webview's
  # shell html is loaded, detected in webView_didFinishLoadForFrame
  # Actual loading is triggered by source_path=
  def readFromURL_ofType_error(url, type, error)
    @read_path = url.path.to_s
    error = nil
    
    return root_valid?(@read_path)
  end

    
  # KVC accessors
  
  def filterPredicate
    https = []
    
    https = [:filter2x, :filter3x, :filter4x, :filter5x, :filterxx].collect do |filter|
      send(filter) == 1 ? FILTER_MAP[filter] : nil
    end.compact

    https.empty? ? nil : OSX::NSPredicate.predicateWithFormat("http_code_series IN %@", https)
  end
  
  def source_path=(path)
    OSX::NSLog("setting source path to #{path}")
    @source_path = path
    
    unless @previous_path == path
      @previous_path = path
      
      load_log
    end
  end
  
  def load_log
    self.log = Log.logFromPath(@source_path)
    
    # showConfig if self.log.first_time?
    
    self.log.read
  end
  
  
  def log=(log)
    @log.stop_tailing if @log    
    @log = log
  end
  
  def root_valid?(root)
    if File.directory?(root)
      File.directory?(File.join(root,'log'))
    else
      File.exist?(root)
    end
  end

  
  def log_selection=(sel)
    @log_selection = sel
    
    return unless @entries_controller.arrangedObjects.count > 0 and @entries_controller.selectedObjects.count > 0
    
    @selected_index = sel.firstIndex
    self.selected_entry = @entries_controller.selectedObjects.lastObject
  end
    
  def selected_entry=(entry)
    #entry.dump_details
    
    @selected_entry = entry
    
    wso = @webview.windowScriptObject
    wso.evaluateWebScript("Page.setEntry(#{entry.to_json})")
  end
  
  
  # workspace utils
  
  def editEntryFile(entries)
    return if entries.count < 1
    editRailsFile(entries.objectAtIndex(0).controllerPath)
  end
  
  def editRailsFile(*path)
    return unless @log.rails_root
    editFile File.join(@log.rails_root,*path)
  end

  def editFile(file,line=0)
    file.sub!('RAILS_ROOT',@log.rails_root) if @log.rails_root
    
    OSX::NSLog "editing file... #{file}"
    
    editor = OSX::NSUserDefaultsController.sharedUserDefaultsController.values.valueForKey('editor').to_s
    
    if editor && !editor.strip.empty?
      OSX::NSWorkspace.sharedWorkspace.openFile_withApplication(file,editor)
      return
    end
    
    editor = OSX::NSUserDefaultsController.sharedUserDefaultsController.values.valueForKey('editorViaCommandline').to_s
    
    if editor && !editor.strip.empty?
      editor = File.expand_path(editor)
      editor.sub!('$line',line.to_s)
      editor.sub!('$file',file.to_s)
  
      system(editor)
    end
  end
  
  
  # actions
  def revealRailsRoot(sender)
    return unless @log and @log.path # and @log.rails_root
    OSX::NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(@log.path,ENV['HOME'])
  end
  
  def clearLog(sender)
    return unless @log
    @log.clear!
    @entries_controller.rearrangeObjects
  end

  def showConfig(sender=nil)
    ConfigSheet.alloc.init.show(self.log)
  end
 

  # web view delegation
  
  def webView_resource_didFinishLoadingFromDataSource(wv,resource,ds)
    puts "web resource finished loading"
    p resource
  end
  
  def webView_resource_didFailLoadingWithError_fromDataSource(wv,id,error,ds)
    puts "resource failed"
    p error
    p error.domain
    p error.code
    p error.userInfo
  end
  
  def webView_decidePolicyForMIMEType_request_frame_decisionListener(wv,mimetype,req,frame,dlis)
    puts "webView_decidePolicyForMIMEType_request_frame_decisionListener"
    puts "type: #{mimetype}"
    puts "abs url #{req.URL.absoluteString}"
  end
  
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(wv,action,request,frame,listener)    
    if request.URL.scheme == 'logeye'
      listener.ignore
      _,url = request.URL.absoluteString.split(':',2)
      handle_logeye_url(url)
    else
      listener.use
    end
  end
  
  
  def webView_didFinishLoadForFrame(wv,frame)
    return if frame.parentFrame
    @ready = true
    self.source_path = @read_path
    #self.log_selection = OSX::NSIndexSet.indexSetWithIndex(0)
  end
  
  def webView_runJavaScriptAlertPanelWithMessage(ev,message)
    puts "alert: #{message}"
  end
  
    
  # handle clicks on the html
  def handle_logeye_url(url)    
    puts "handling logeye url: #{url}"
    command,args = url.split('/',2)
    
    case(command)
    when 'editcontroller'
      controller = @selected_entry.controllerPath
      puts "controller: #{controller}"
      editRailsFile(controller)
    when 'editbacktrace'
      file,line = nil,nil
      
      args.split('&').each do |segment|
        key,value = segment.split('=')
        file = value if key == 'path'
        line = value if key == 'line'
      end
      
      editFile(file,line)
    else
      raise "unknown logeye command #{command}"
    end
  end
  
  
  # icon asset loading... refactor this, biatch
  def self.icon(name)
    OSX::NSImage.alloc.initWithContentsOfFile(OSX::NSBundle.mainBundle.pathForResource_ofType(name,'png'))
  end
  
  def self.icon_for_series(series,on=false)
    series = (series.to_i rescue 0)
    
    unless on
      case series
        when 2 then @green_spot  ||= icon('green_spot')
        when 3 then @blue_spot   ||= icon('blue_spot')
        when 4 then @orange_spot ||= icon('orange_spot')
        when 5 then @red_spot    ||= icon('red_spot')
      else
        @gray_spot ||= icon('gray_spot') 
      end
    else
      case series
        when 2 then @green_spot_on  ||= icon('green_spot_on')
        when 3 then @blue_spot_on   ||= icon('blue_spot_on')
        when 4 then @orange_spot_on ||= icon('orange_spot_on')
        when 5 then @red_spot_on    ||= icon('red_spot_on')
      else
        @gray_spot_on ||= icon('gray_spot_on') 
      end
    end
  end

end