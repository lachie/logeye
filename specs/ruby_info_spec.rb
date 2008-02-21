require File.dirname(__FILE__)+'/spec_helper.rb'

require 'ruby_info'

describe RubyInfo do
  it "should get info" do
    RubyInfo.should be_ruby
  end
  
  it "should classify site :lib" do
    kind,path = RubyInfo.classify_path('/opt/local/lib/ruby/site_ruby/1.8/something.rb')
    kind.should == :lib
    path.should == 'something.rb'
  end
  
  it "should classify core :lib" do
    kind,path = RubyInfo.classify_path('/opt/local/lib/ruby/1.8/erb.rb')
    kind.should == :lib
    path.should == 'erb.rb'
  end
  
  it "should classify :gem" do
    kind,path = RubyInfo.classify_path('/opt/local/lib/ruby/gems/1.8/gems/activerecord-1.15.3/lib/active_record/base.rb')
    kind.should == :gem
    path.should == ['activerecord-1.15.3','active_record/base.rb']
  end
  
  it "should classify /app as :app" do
    kind,path = RubyInfo.classify_path('/app/controllers/foo_controller.rb')
    kind.should == :app
    path.should == 'app/controllers/foo_controller.rb'
  end
  
  it "should classify /lib as :app" do
    kind,path = RubyInfo.classify_path('/lib/thing.rb')
    kind.should == :app
    path.should == 'lib/thing.rb'
  end
  
  it "should classify /vendor as :app" do
    kind,path = RubyInfo.classify_path('/vendor/rails.rb')
    kind.should == :app
    path.should == 'vendor/rails.rb'
  end
  
  it "should classify /tmp as :unknown" do
    kind,path = RubyInfo.classify_path('/tmp')
    kind.should == :unknown
    path.should == '/tmp'
  end
end