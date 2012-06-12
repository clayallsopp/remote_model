class FailingModel < RemoteModule::RemoteModel
    def self.root_url
      # returns a 400 when you don't have a proper token
      "http://graph.facebook.com/btaylor/friends"
    end

    collection_url ""
    member_url "/:id"
end

describe "The requests stuff" do
  it "should parse json" do
    @ran = false
    RemoteModule::RemoteModel.get("http://graph.facebook.com/btaylor") do |response, json|
      json.class.should == Hash
      response.ok?.should == true
      @ran = true
    end
    # really stupid, haven't made an async request example...
    wait 5.0 do
      @ran.should == true
    end
  end

  it "should return nil upon bad requests" do
    @ran_find_all = false
    @ran_find = false
    FailingModel.find_all do |results, response|
      results.should == nil
      @ran_find_all = true
    end

    FailingModel.find("1") do |result, response|
      result.should == nil
      @ran_find = true
    end

    wait 5.0 do
      @ran_find_all.should == true
      @ran_find.should == true
    end
  end
end