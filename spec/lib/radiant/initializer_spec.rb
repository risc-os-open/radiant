require File.dirname(__FILE__) + "/../../spec_helper"

describe Radiant::ApplicationConfiguration do
  before :each do
    @configuration = Radiant::ApplicationConfiguration.new
  end

  it "should be a Rails configuration" do
    @configuration.should be_kind_of(Rails::Configuration)
  end

  it "should have access to the AdminUi" do
    @configuration.admin.should == Radiant::AdminUi.instance
  end
end
