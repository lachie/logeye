class WindowDelegate < OSX::NSObject
  def initForWindow(window)
    if init
      puts "setting delegate for #{window.class} #{window}"
      window.setDelegate self      
      return self
    end
  end
      
  # window delegate
  def windowWillUseStandardFrame_defaultFrame(window,default_frame)
    puts "windowWillUseStandardFrame_defaultFrame... #{window}, #{default_frame}"
    slice = OSX::NSRect.new
    remainder = OSX::NSRect.new

    width = default_frame.size.width * 0.3

    OSX::NSDivideRect(default_frame, slice, remainder, width, OSX::NSMaxXEdge)

    slice
  end

  def windowWillClose(notification)
   puts "closing window, yay"

   # @webview.retain

   # @window.autorelease
   # @window = nil
  end
  
end