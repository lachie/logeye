class ConfigSheet < OSX::NSObject
  attr_accessor :sheet
  attr_reader :log

  def self.show(log)
    self.alloc.init.show(log)
  end
  
  def show(log)
    @log = log
    
    puts "sheet, before #{sheet.inspect} "
    
    OSX::NSBundle.loadNibNamed_owner("ConfigSheet", self) unless sheet

    log.willChangeConfig

    OSX::NSApp.runModalForWindow(sheet)
    
    puts "done sheet"
  end
  
  def close(sender)
    # OSX::NSApp.endSheet(sheet)
    OSX::NSApp.stopModal
    sheet.orderOut(self)
    
    @log.didChangeConfig
    @log = nil
  end
end