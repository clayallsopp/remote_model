# Facebook Graph Example

The Facebook Graph API is a great example of how powerful RemoteModel is. Facebook auth code adapted from [facebook-auth-ruby-motion-example](https://github.com/aaronfeng/facebook-auth-ruby-motion-example)

## Running

You need [motion-cocoapods](https://github.com/HipByte/motion-cocoapods) installed to load the Facebook iOS SDK. 

It also appears that (as of May 9 2011), motion-cocoapods doesn't play nice with the FB SDK and you need to use `rake --trace` to get it to load correctly.

You need to specify an FB app ID, which you can create [in FB's Developer app](https://www.facebook.com/developers):

###### app_delegate.rby

```ruby
def application(application, didFinishLaunchingWithOptions:launchOptions)
  ...
  @facebook = Facebook.alloc.initWithAppId("YOUR-APP-ID", andDelegate:self)
  ...
end
```

###### Rakefile

```ruby
Motion::Project::App.setup do |app|
  ...
  fb_app_id = "YOUR-APP-ID"
  app.info_plist['CFBundleURLTypes'] = [{'CFBundleURLSchemes' => ["fb#{fb_app_id}"]}]
  ...
end
```