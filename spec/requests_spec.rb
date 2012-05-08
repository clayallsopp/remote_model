describe "The requests stuff" do
  it "should parse json" do
    ran = false
    RemoteModule::RemoteModel.get("http://graph.facebook.com/btaylor") do |response, json|
      json.class.should == Hash
      response.ok?.should == true
      ran = true
    end
    # really stupid, haven't made an async request example...
    wait 5.0 do
      ran.should == true
    end
  end
end