# RemoteModel


JSON API <-> NSObject in one line. Powered by RubyMotion and [BubbleWrap](https://github.com/mattetti/BubbleWrap/).

## Installation

Add the git repos as submodules in ./vendor:

```shell
git submodule add git://github.com/mattetti/BubbleWrap.git ./vendor/BubbleWrap
git submodule add git://github.com:clayallsopp/remote_model.git ./vendor/remote_model
```

Then add the lib paths to your ./Rakefile:

```ruby
Motion::Project::App.setup do |app|
  ...
  app.files = Dir.glob(File.join(app.project_dir, 'vendor/BubbleWrap/lib/**/*.rb')) 
    + Dir.glob(File.join(app.project_dir, 'vendor/remote_model/lib/**/*.rb')) 
    + app.files
  ...
end
```

Add an initialization file somewhere, like ./app/initializers/remote_model.rb. This is where we put the API specifications:

```ruby
module RemoteModule
  class RemoteModel
    # The default URL for our requests.
    # Overrideable per model subclass
    self.root_url = "http://localhost:5000/"

    # Options attached to every request
    # Appendable per model subclass
    self.default_url_options = {
        :headers => {
          "x-api-token" => "some_token",
          "Accept" => "application/json"
        }
      }
  end
end
```

## Example

Let's say we have some User and Question objects retrievable via our API. We can do fun stuff like:

```ruby
user = User.find(1) do |user|
  # async
  Question.find_all(user_id: user.id) do |questions|
    # async
    puts questions
  end
end

# Later...
=> [#<Question @answers=[#<Answer>, #<Answer>] @user=#<User>, 
    #<Question @answers=[#<Answer>, #<Answer>] @user=#<User>]
```

Here's what our files look like:

#### ./app/models/user
```ruby
class User < RemoteModule::RemoteModel
  attr_accessor :id

  has_many :questions

  collection_url "users"
  member_url "users/:id"
end
```

#### ./app/models/question.rb
```ruby
class Question < RemoteModule::RemoteModel
  attr_accessor :id, :question, :is_active

  belongs_to :user

  collection_url "users/:user_id/questions"
  member_url "users/:user_id/questions/:id"

  custom_urls :active_url => member_url + "/make_active"

  def user_id
    user && user.id
  end

  def make_active(active)
    post(self.active_url, payload: {active: active}) do |response, json|
      self.is_active = json[:question][:is_active]
      if block_given?
        yield self
      end
    end
  end
end
```