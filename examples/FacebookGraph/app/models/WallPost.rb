class WallPost < RemoteModule::RemoteModel
  attr_accessor :id, :message

  has_one :from => :user

  collection_url ""
  member_url ":id"
end