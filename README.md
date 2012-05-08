# RemoteModel


JSON API <-> NSObject in one line. Powered by RubyMotion and [BubbleWrap](https://github.com/mattetti/BubbleWrap/).

## Installation
------------

Add the git repos as submodules in ./vendor:

  git submodule add git://github.com/mattetti/BubbleWrap.git ./vendor/BubbleWrap
  git submodule add git://github.com:clayallsopp/remote_model.git ./vendor/remote_model

Then add the lib paths to your ./Rakefile:

```ruby
Motion::Project::App.setup do |app|
  ...
  app.files = Dir.glob(File.join(app.project_dir, 'vendor/BubbleWrap/lib/**/*.rb')) + Dir.glob(File.join(app.project_dir, 'vendor/remote_model/lib/**/*.rb')) + app.files
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
------------

Let's say we have some User, Question, and Answer objects retrievable via our API. Here's what our files can look like:

#### ./app/models/user
```ruby
class User < RemoteModule::RemoteModel
  attr_accessor :id, :phone, :email

  has_many :questions

  class << self; attr_accessor :current_user; end;

  collection_url "users"
  member_url "users/:id"
end
```

#### ./app/models/question.rb
```ruby
class Question < RemoteModule::RemoteModel
  attr_accessor :id, :question, :is_active

  belongs_to :user
  has_many :answers

  collection_url "users/:user_id/questions"
  member_url "users/:user_id/questions/:id"

  custom_urls :active_url => member_url + "/make_active"

  def user_id
    user && user.id
  end

  def make_active(active, &block)
    post(self.active_url, payload: {active: active}) do |response, json|
      self.is_active = json[:question][:is_active]
      if block
        block.call self
      end
    end
  end
end
```

#### ./app/models/answer.rb
```ruby
class Answer < RemoteModule::RemoteModel
  attr_accessor :id, :answer

  belongs_to :question
end
```

And now we can do fun stuff:

```ruby
user = User.find(1) do |user|
  # async
  Question.find_all(user_id: user.id) do |questions|
    # async
    puts questions
  end
end


=> [#<Question @answers=[#<Answer>, #<Answer>] @user=#<User>, #<Question @answers=[#<Answer>, #<Answer>] @user=#<User>]
```