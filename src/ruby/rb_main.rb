# $DEBUG=true
# $VERBOSE=true


# hack to get standalonify to work
if self.class.const_defined? :COCOA_APP_RESOURCES_DIR
  require 'rbconfig'
  Config::CONFIG['sitelibdir'] = File.join(COCOA_APP_RESOURCES_DIR,"ThirdParty")
  
  bundle_lib_path = File.join(File.dirname(COCOA_APP_RESOURCES_DIR),'Frameworks','RubyCocoa.framework','Resources','ruby')
  $LOAD_PATH << bundle_lib_path
end


begin
require 'rubygems'
rescue LoadError
end
require 'osx/cocoa'
require 'pathname'

def log(*args)
	args.each do |m|
		OSX.NSLog m.inspect
	end
end

def _(key)
	NSLocalizedString(key, '').to_s
end




path = Pathname.new OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Pathname.glob(path + '*.rb') do |file|
	next if file.to_s == __FILE__
	require(file)
end


begin
  OSX::NSApplication.sharedApplication
  OSX::NSApplicationMain(0, nil)
  
rescue Object
  
  log "ruby exception caught: #{$!}"
  $!.backtrace.each do |bt|
    log "  #{bt}"
  end
  
  open("#{ENV['HOME']}/Desktop/Logeye.ruby_crash.log","a") do |f|
    f << "" << $/
    f << "===========================" << $/
    f << "  Logeye Crashed #{Time.now}" << $/
    f << "" << $/
    f << "#{$!.class}: #{$!}" << $/
    $!.backtrace.each {|b| f << "  #{b}" << $/} if $!.respond_to?(:backtrace)
  end
end


