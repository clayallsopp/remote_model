class User < RemoteModule::RemoteModel
  attr_accessor :id, :name, :bio

  has_many :wall_posts
  has_many :friends => :user

  collection_url ""
  member_url ":id"

  custom_urls :friends_url => member_url + "/friends",
              :wall_posts_url => member_url + "/feed"

  # EX
  # user.find_friends do |user|
  #   p user.friends[0]
  # end
  def find_friends(&block)
    get(self.friends_url) do |response, json|
      self.friends = json[:data]
      if block
        block.call self
      end
    end
  end

  def find_wall_posts(&block)
    get(self.wall_posts_url) do |response, json|

      self.wall_posts = json[:data]
      if block
        block.call self
      end
    end
  end
end