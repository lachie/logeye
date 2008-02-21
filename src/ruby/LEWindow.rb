class LEWindow < OSX::NSWindow
  def awakeFromNib
    OSX::NSUserDefaultsController.sharedUserDefaultsController.objc_send :addObserver, self,
              :forKeyPath, 'values.windowAlpha',
              :options, OSX::NSKeyValueObservingOptionNew,
              :context, nil

    OSX::NSUserDefaultsController.sharedUserDefaultsController.objc_send :addObserver, self,
              :forKeyPath, 'values.floatWindows',
              :options, OSX::NSKeyValueObservingOptionNew,
              :context, nil
              
    setup_from_defaults
  end
  
  def observeValueForKeyPath_ofObject_change_context(keyPath, object, change, context)
    if OSX::NSUserDefaultsController.sharedUserDefaultsController == object
      setup_from_defaults
    end
  end
  
  def setup_from_defaults
    values = OSX::NSUserDefaultsController.sharedUserDefaultsController.values
    
    if values.valueForKey('floatWindows').to_ruby
      puts "floaty"
      self.setLevel(OSX::NSFloatingWindowLevel)
    else
      puts "no floaty"
      self.setLevel(OSX::NSNormalWindowLevel)
    end

    self.setAlphaValue values.valueForKey('windowAlpha').to_i / 100.0
  end
  
end