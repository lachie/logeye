class MyDocController < OSX::NSDocumentController
  def runModalOpenPanel_forTypes(panel,types)
    panel.setCanChooseDirectories(true)
    panel.setCanChooseFiles(true)
    
    super_runModalOpenPanel_forTypes(panel,types)
  end
end

class MyController < OSX::NSWindowController
  
  def self.initialize
    puts "setting initial values"
    OSX::NSUserDefaultsController.sharedUserDefaultsController.setInitialValues('windowAlpha' => 100.0, 'floatWindows' => false, 'editor' => 'TextMate')
  end
  
  ib_outlet :prefsWindow
  
  
  # OSX::NSUserDefaultsController.sharedUserDefaultsController.removeObserver_forKeyPath(self, 'values.windowAlpha')
  # OSX::NSUserDefaultsController.sharedUserDefaultsController.removeObserver_forKeyPath(self, 'values.floatWindows')  
  
  def applicationShouldOpenUntitledFile(app)
    false
  end
  
  def applicationWillTerminate(app)
    documents = OSX::NSDocumentController.sharedDocumentController.documents    
    documents.collect! {|document| document.fileURL.absoluteString}
    
    std_defaults = OSX::NSUserDefaults.standardUserDefaults
    std_defaults.setObject_forKey(OSX::NSArray.arrayWithArray(documents),"documentsToReopen")
    std_defaults.synchronize
  end

  
  def applicationWillFinishLaunching(app)
    dc = MyDocController.alloc.init
    
    std_defaults = OSX::NSUserDefaults.standardUserDefaults
    if documents = std_defaults.objectForKey("documentsToReopen")
      documents.each do |url_string|
        dc.openDocumentWithContentsOfURL_display_error(OSX::NSURL.URLWithString(url_string),true,nil)
      end
    end
  end
end