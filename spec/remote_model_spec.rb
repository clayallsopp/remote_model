class CustomUrlModel < RemoteModule::RemoteModel
  collection_url "collection"
  member_url "collection/:id"

  custom_urls :a_url => "custom", :format_url => "custom/:var",
    :method_url => "custom/:a_method"

  def id
    8
  end

  def a_method
    10
  end
end

describe "URLs" do
  it "should make visible urls at class and instance level" do
    CustomUrlModel.a_url.should == "custom"
    CustomUrlModel.collection_url.should == "collection"
    CustomUrlModel.member_url.should == "collection/:id"

    # NOTE that Class.member_url(params) won't work (it's the setter).
    CustomUrlModel.member_url.format(:id => 9).should == "collection/9"

    c = CustomUrlModel.new
    c.collection_url.should == "collection"
    c.member_url.should == "collection/8"
    c.a_url.should == "custom"

    CustomUrlModel.format_url.should == "custom/:var"
    c.format_url(:var => 3).should == "custom/3"
    c.method_url.should == "custom/10"
  end
end