# Deprecation Warning

`remote_model` is from a time and place in RubyMotion where only the hackiest of hacks made this possible; please look into using (the tentatively titled) Maglev as a more modern, stable replacement: 

https://github.com/clayallsopp/maglev

# RemoteModel


JSON API <-> NSObject in one line. Powered by RubyMotion and [BubbleWrap](https://github.com/mattetti/BubbleWrap/).

## Example

Let's say we have some User and Question objects retrievable via our API. We can do fun stuff like:

```ruby
# GET http://ourapi.com/users/1.json -> {:user => {id: 1}}
user = User.find(1) do |user|
  # async
  # GET http://ourapi.com/users/1/questions.json -> {:questions => [...]}
  Question.find_all(user_id: user.id) do |questions|
    # async
    puts questions
  end
end

# Later...
=> [#<Question @user=#<User>, 
    #<Question @user=#<User>]
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

  # The urls substitute params based on a passed hash and/or object's methods,
  # so we define user_id to use for the collection/member urls
  def user_id
    user && user.id
  end

  # An example of how we can use custom URLs to make custom nice(r) methods
  # EX
  # a_question.make_active(false) do |question|
  #   p question.is_active
  # end
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

## Installation

```ruby
gem install remote_model
```

And now in your Rakefile, require `remote_model`:

```ruby
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require 'remote_model'

Motion::Project::App.setup do |app|
  ...
end
```

## Setup

Add an initialization file somewhere, like ./app/initializers/remote_model.rb. This is where we put the API specifications:

```ruby
module RemoteModule
  class RemoteModel
    # The default URL for our requests.
    # Overrideable per model subclass
    self.root_url = "http://localhost:5000/"

    # Options attached to every request
    # Appendable per model subclass
    # See BubbleWrap docs on what can be passed in BubbleWrap::HTTP.<method>(url, options)
    self.default_url_options = {
        :headers => {
          "x-api-token" => "some_token",
          "Accept" => "application/json"
        }
      }
  end
end
```

## How?

RemoteModel is designed for JSON APIs which return structures with "nice" properties.

When you make a request with a RemoteModel (self.get/put/post/delete), the result is always parsed as JSON. The ActiveRecord-esque methods take this JSON and create objects out of it. It's clever and creates the proper associations (belongs_to/has_one/has_many) within the objects, as defined in the models.

#### FormatableString

The AR methods also use the member/collection defined URLs to make requests. These URLs are a string which you can use :symbols to input dynamic values. These strings can be formatted using a hash and/or using an object (it will look to see if the object responds to these symbols and call the method if applicable):

```ruby
>> s = RemoteModule::FormatableString.new("url/:param")
=> "url/:param"
>> s.format({param: 6})
=> "url/6"
>> obj = Struct.new("Paramer", :param).new(param: 100)
=> ...
>> s.format({}, obj)
=>  "url/100"
```

RemoteModels can define custom urls and call those as methods (see question.rb above).

## Todo

- More tests
- CoreData integration
