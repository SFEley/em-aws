require_relative '../../spec_helper'
require 'em-aws/query/query_params'

describe "#queryize_params" do
  include EventMachine::AWS::Query::QueryParams
  
  subject do
    queryize_params zoo: 'zar',
      foo: {
        thingy: 'zingy',
        'Thangy' => 'zangy',
        complex: {
          value: '17',
          modify: true
        }
      },
      some_thing: 'else',
      'happy' => 'Fun Ball',
      attributes: "to clean living",
      an_array: [11, 'hello', false]
      
  end

  it "capitalizes symbol keys" do
    subject['Zoo'].should == 'zar'
  end
  
  it "doesn't touch string keys" do
    subject['happy'].should == 'Fun Ball'
  end
  
  it "camelcases symbol keys" do
    subject['SomeThing'].should == 'else'
  end
  
  it "splits out subhashes" do
    subject['Foo.1.Name'].should == 'Thingy'
    subject['Foo.1.Value'].should == 'zingy'
  end
  
  it "has multiple values from subhashes" do
    subject['Foo.2.Name'].should == 'Thangy'
    subject['Foo.2.Value'].should == 'zangy'
  end
  
  it "splits out values from sub-subhashes" do
    subject['Foo.3.Name'].should == 'Complex'
    subject['Foo.3.Value'].should == '17'
    subject['Foo.3.Modify'].should == true
  end
  
  it "singularizes 'attributes' for readability" do
    subject['Attribute'].should == 'to clean living'
    subject['Attributes'].should be_nil
  end
  
  it "splits out arrays" do
    subject['AnArray.1'].should == 11
    subject['AnArray.2'].should == 'hello'
    subject['AnArray.3'].should be_false
  end
end