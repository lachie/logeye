require File.dirname(__FILE__)+'/spec_helper.rb'

require 'rails_log'

describe RailsLog do
  before do
    @log = RailsLog.alloc.init
    @log.path = "/rails_root/default.log"
  end
  
  it "should show correct basename" do
    @log.base_name.should == 'default.log'
  end
  
  it "should have no environments" do
    @log.have_environments?.should_not be_true
  end
  
  it "should have no environments on empty" do
    @log.environments = []
    @log.have_environments?.should_not be_true
  end
  
  it "should have environments" do
    @log.environments = [nil]
    @log.have_environments?.should be_true
  end
  
  it "should not have rails_root" do
    @log.rails_root.should be_nil
  end
  
  it "should read" do
    @log.should_receive(:prescan_log)
    @log.should_receive(:cleanup_dequeue_log)
    @log.should_receive(:setup_timers)
    
    log = File.dirname(__FILE__)+'/fixtures/log.log'
    FileUtils::mkdir_p File.dirname(log)
    FileUtils::touch log
    
    @log.read_log(log)
    
    @log.entries.should_not be_nil
    @log.entries.should be_kind_of(OSX::NSMutableArray)
    @log.logfile.should_not be_nil
  end
end