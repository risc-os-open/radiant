require File.dirname(__FILE__) + "/../../../spec_helper"

describe "Radiant::Configuration::Definition" do
  before :each do
    Radiant::Configuration.initialize_cache
    @basic = Radiant::Configuration::Definition.new({
      :default => 'quite testy'
    })
    @boolean = Radiant::Configuration::Definition.new({
      :type => :boolean,
      :default => true
    })
    @integer = Radiant::Configuration::Definition.new({
      :type => :integer,
      :default => 50
    })
    @validating = Radiant::Configuration::Definition.new({
      :default => "Monkey",
      :validate_with => lambda {|s| s.errors.add(:value, "That's no monkey") unless s.value == "Monkey" }
    })
    @selecting = Radiant::Configuration::Definition.new({
      :default => "Monkey",
      :select_from => [["m", "Monkey"], ["g", "Goat"]]
    })
    @selecting_from_hash = Radiant::Configuration::Definition.new({
      :default => "Non-monkey",
      :allow_blank => true,
      :select_from => {"monkey" => "Definitely a monkey", "goat" => "No fingers", "Bear" => "Angry, huge", "Donkey" => "Non-monkey"}
    })
    @selecting_required = Radiant::Configuration::Definition.new({
      :default => "other",
      :allow_blank => false,
      :select_from => lambda { ['recent', 'other', 'misc'] }
    })
    @enclosed = "something"
    @selecting_at_runtime = Radiant::Configuration::Definition.new({
      :default => "something",
      :select_from => lambda { [@enclosed] }
    })
    @protected = Radiant::Configuration::Definition.new({
      :default => "Monkey",
      :allow_change => false
    })
    @hiding = Radiant::Configuration::Definition.new({
      :default => "Secret Monkey",
      :allow_display => false
    })
    @present = Radiant::Configuration::Definition.new({
      :default => "Hola",
      :allow_blank => false
    })
  end
  after :each do
    Radiant::Cache.clear
    Radiant.configuration.clear_definitions!
  end

  describe "basic definition" do
    before do
      Radiant.configuration.define('test', @basic)
      @setting = Radiant::Configuration.find_by_key('test')
    end

    it "should specify a default" do
      @basic.default.should == "quite testy"
      @setting.value.should == "quite testy"
      Radiant::Configuration['test'].should == 'quite testy'
    end
  end

  describe "validating" do
    before do
      Radiant::Configuration.define('valid', @validating)
      Radiant::Configuration.define('number', @integer)
      Radiant::Configuration.define('selecting', @selecting)
      Radiant::Configuration.define('required', @present)
    end

    it "should validate against the supplied block" do
      setting = Radiant::Configuration.find_by_key('valid')
      lambda{setting.value = "Ape"}.should raise_error
      setting.valid?.should be_false
      setting.errors[:value].should == "That's no monkey"
    end

    it "should allow a valid value to be set" do
      lambda{Radiant::Configuration['valid'] = "Monkey"}.should_not raise_error
      Radiant::Configuration['valid'].should == "Monkey"
      lambda{Radiant::Configuration['selecting'] = "Goat"}.should_not raise_error
      lambda{Radiant::Configuration['selecting'] = ""}.should_not raise_error
      lambda{Radiant::Configuration['integer'] = "27"}.should_not raise_error
      lambda{Radiant::Configuration['integer'] = 27}.should_not raise_error
      lambda{Radiant::Configuration['required'] = "Still here"}.should_not raise_error
    end

    it "should not allow an invalid value to be set" do
      lambda{Radiant::Configuration['valid'] = "Cow"}.should raise_error
      Radiant::Configuration['valid'].should_not == "Cow"
      lambda{Radiant::Configuration['selecting'] = "Pig"}.should raise_error
      lambda{Radiant::Configuration['number'] = "Pig"}.should raise_error
      lambda{Radiant::Configuration['required'] = ""}.should raise_error
    end
  end

  describe "offering selections" do
    before do
      Radiant::Configuration.define('not', @basic)
      Radiant::Configuration.define('now', @selecting)
      Radiant::Configuration.define('hashed', @selecting_from_hash)
      Radiant::Configuration.define('later', @selecting_at_runtime)
      Radiant::Configuration.define('required', @selecting_required)
    end

    it "should identify itself as a selector" do
      Radiant::Configuration.find_by_key('not').selector?.should be_false
      Radiant::Configuration.find_by_key('now').selector?.should be_true
    end

    it "should offer a list of options" do
      Radiant::Configuration.find_by_key('required').selection.should have(3).items
      Radiant::Configuration.find_by_key('now').selection.include?(["", ""]).should be_true
      Radiant::Configuration.find_by_key('now').selection.include?(["m", "Monkey"]).should be_true
      Radiant::Configuration.find_by_key('now').selection.include?(["g", "Goat"]).should be_true
    end

    it "should run a supplied selection block" do
      @enclosed = "testing"
      Radiant::Configuration.find_by_key('later').selection.include?(["testing", "testing"]).should be_true
    end

    it "should normalise the options to a list of pairs" do
      Radiant::Configuration.find_by_key('hashed').selection.is_a?(Hash).should be_false
      Radiant::Configuration.find_by_key('hashed').selection.include?(["monkey", "Definitely a monkey"]).should be_true
    end

    it "should not include a blank option if allow_blank is false" do
      Radiant::Configuration.find_by_key('required').selection.should have(3).items
      Radiant::Configuration.find_by_key('required').selection.include?(["", ""]).should be_false
    end

  end

  describe "protecting" do
    before do
      Radiant::Configuration.define('required', @present)
      Radiant::Configuration.define('fixed', @protected)
    end

    it "should raise a ConfigError when a protected value is set" do
      lambda{ Radiant::Configuration['fixed'] = "different" }.should raise_error(Radiant::Configuration::ConfigError)
    end

    it "should raise a validation error when a required value is made blank" do
      lambda{ Radiant::Configuration['required'] = "" }.should raise_error
    end
  end


end

