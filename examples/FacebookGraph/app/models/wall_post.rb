class WallPost < RemoteModule::RemoteModel
  attr_accessor :id, :message

  # if we encounter "from" in the JSON return,
  # use the User class.
  has_one :from => :user

  collection_url ""
  member_url ":id"
end