#require 'osx/cocoa' # dummy
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'erb'
require 'pathname'
require 'pp'
require 'rbconfig'



# Application own Settings
APPNAME   = "Logeye"
TARGET    = "build/#{APPNAME}.app"
VERSION   = "rev#{`svn info`[/Revision: (\d+)/, 1]}"

BUILD_DIR = 'build'

RINGBARKER = "#{ENV['HOME']}/CommonDocuments/dev/ruby/ringbarker"

RESOURCES_PATH = "resources"
RESOURCES = ['*.lproj', 'Credits.*', '*.icns','*.html','*.js','*.png']

RESOURCES.collect! {|r| File.join(RESOURCES_PATH,r)}

RESOURCES << "#{RINGBARKER}/lib/*"
json_path = Gem.source_index.search('json').first.full_gem_path
RESOURCES << "#{json_path}/lib/*"

RUBY_SOURCE = 'src/ruby'
OBJC_SOURCE = 'src/objc'

PKGINC    = [TARGET, 'README', 'html', 'client']

LOCALENIB = [] #['Japanese.lproj/Main.nib']
PUBLISH   = 'yourname@yourhost:path'
GEMS      = ['file-tail','json']

VERSION = '0.4.0'
VERSION_INTEGER = 40

RBCOCOA = '/Library/Frameworks/RubyCocoa.framework' #{}"~/tmp/rubycocoa_svn/framework/build/Development/RubyCocoa.framework"
# RBCOCOA = "~/tmp/RubyCocoa-0.12.0/framework/build/Development/RubyCocoa.framework"



STANDALONEIFY = "~/tmp/rubycocoa_svn/framework/tool/standaloneify.rb"

BUNDLEID  = "rubyapp.#{APPNAME}"

CLEAN.include ['**/.*.sw?', '*.dmg', TARGET, 'image', 'a.out']

# Tasks
task :default => [:test]

desc 'Create Application Bundle and Run it.'
task :test => [TARGET] do
	sh %{open '#{TARGET}'}
end



desc 'Make Localized nib from English.lproj and Lang.lproj/nib.strings'
rule(/.nib$/ => [proc {|tn| File.dirname(tn) + '/nib.strings' }]) do |t|
	p t.name
	lproj = File.dirname(t.name)
	target = File.basename(t.name)
	sh %{
	rm -rf #{t.name}
	nibtool -d #{lproj}/nib.strings -w #{t.name} English.lproj/#{target}
	}
end

# File tasks
desc 'Make executable Application Bundle'
file TARGET => [:clean, :prepare, "build/#{APPNAME}", :resources]

desc "prepare the build dir"
task :prepare do
  mkdir_p BUILD_DIR
end  


task :skeleton => :prepare do
  root = "#{BUILD_DIR}/#{APPNAME}.app"
  sh %{
    mkdir -p #{root}
    mkdir -p #{root}/Contents/MacOS
    mkdir -p #{root}/Contents/Frameworks
    mkdir -p #{root}/Contents/Resources
  }
end
  
task :resources => :skeleton do
  contents  = "#{BUILD_DIR}/#{APPNAME}.app/Contents"
  resources = "#{contents}/Resources"
  
	sh %{
	cp -rp #{RBCOCOA} #{contents}/Frameworks
	cp -rp #{RESOURCES.join(' ')} "#{resources}"
	
	cp -rp src/ruby/*.rb "#{resources}"
	
	cp '#{BUILD_DIR}/#{APPNAME}' "#{contents}/MacOS"
	echo -n "APPL????" > "#{contents}/PkgInfo"
	echo -n #{VERSION} > "#{resources}/VERSION"
	}
	
	File.open("#{contents}/Info.plist", "w") do |f|
		f.puts ERB.new(File.read("#{RESOURCES_PATH}/Info.plist.erb")).result
	end
end



COMMON = "-arch i386 -Wall -ggdb -O0 -fno-common -fobjc-exceptions"
CFLAGS = "-I #{Config::CONFIG['topdir']} #{COMMON}"
LDFLAGS = "#{COMMON}  -lobjc -framework Foundation -framework AppKit -framework RubyCocoa"

OBJECTS = []

FileList['src/objc/*.m'].each do |file|
  object = "build/"+File.basename(file).sub(/\.m/,'.o')
  OBJECTS << object
  
  task object => [:prepare] do
    sh %{gcc #{CFLAGS} -c -o #{object} #{file}}
  end
  
  file "build/#{APPNAME}" => object
end


desc "compile and link"
file "build/#{APPNAME}" => [:prepare,'src/objc/main.m'] do
	# Universal Binary: -arch ppc 	
   # src/objc/main.m
	sh %{gcc #{LDFLAGS} #{OBJECTS * ' '} -o 'build/#{APPNAME}'}
end


desc "standaloneify"
task :standalone => TARGET do
  sh %{ruby #{STANDALONEIFY} -d #{BUILD_DIR}/LogeyeStandalone.app -f #{BUILD_DIR}/Logeye.app}
end

desc "package up as the lateset version"
task :dist => :standalone do
  sh %{
    mkdir dist
    mv #{BUILD_DIR}/LogeyeStandalone.app dist/Logeye.app
    rm dist/Logeye-#{VERSION}.zip
    cd dist
    zip -r Logeye-#{VERSION}.zip Logeye.app
    cd ..
  }
end

directory 'pkg'



desc 'Create .dmg file for Publish'
task :package => [:clean, 'pkg', TARGET] do
	name = "#{APPNAME}.#{VERSION}"
	sh %{
	mkdir image
	cp -r #{PKGINC.join(' ')} image
	ln -s html/index.html image/index.html
	}
	puts 'Creating Image...'
	sh %{
	hdiutil create -volname #{name} -srcfolder image #{name}.dmg
	rm -rf image
	mv #{name}.dmg pkg
	}
end

desc 'Publish .dmg file to specific server.'
task :publish => [:package] do
	sh %{
	svn log > CHANGES
	}
	_, host, path = */^([^\s]+):(.+)$/.match(PUBLISH)
	path = Pathname.new path
	puts "Publish: Host: %s, Path: %s" % [host, path]
	sh %{
	scp pkg/IIrcv.#{VERSION}.dmg #{PUBLISH}/pkg
	scp CHANGES #{PUBLISH}/pkg
	scp -r html/* #{PUBLISH}
	}
end