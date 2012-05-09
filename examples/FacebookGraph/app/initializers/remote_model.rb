module RemoteModule
  class RemoteModel
    self.root_url = "https://graph.facebook.com/"
    self.extension = ""

    def self.set_access_token(token)
      self.default_url_options = {
        :query => {
            "access_token" => token
        }
      }
    end
  end
end