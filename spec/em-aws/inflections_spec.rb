require_relative '../spec_helper'

describe EventMachine::AWS::Inflections do
  include EventMachine::AWS::Inflections
  
  describe "#snakecase" do
    it "makes everything lowercase" do
      snakecase('Foo').should == 'foo'
    end
    
    it "turns word separators into underscores" do
      snakecase('HeyYou').should == 'hey_you'
    end    
  end
  
  
end