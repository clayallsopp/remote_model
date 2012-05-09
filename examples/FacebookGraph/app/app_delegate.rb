class AppDelegate
  attr_accessor :facebook
  attr_accessor :navigationController

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @navigationController = UINavigationController.alloc.init
    @window.rootViewController = @navigationController

    fb_app_id = "YOUR-APP-ID"
    if fb_app_id == "YOUR-APP-ID"
      raise "You need to specify a Facebook App ID in ./app/app_delegate.rb"
    end
    @facebook = Facebook.alloc.initWithAppId(fb_app_id, andDelegate:self)

    defaults = NSUserDefaults.standardUserDefaults

    if defaults["FBAccessTokenKey"] && defaults["FBExpirationDateKey"]
      @facebook.accessToken = defaults["FBAccessTokenKey"]
      @facebook.expirationDate = defaults["FBExpirationDateKey"]
    end

    if facebook.isSessionValid
      openFriendsContorller
    else
      @navigationController.pushViewController(FacebookLoginController.alloc.init, animated: false)
    end

    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    true
  end

  def openFriendsContorller
    @navigationController.setViewControllers([FriendsController.alloc.initWithUserId], animated: false)
  end

  def fbDidLogin
    defaults = NSUserDefaults.standardUserDefaults
    defaults["FBAccessTokenKey"] = @facebook.accessToken
    defaults["FBExpirationDateKey"] = @facebook.expirationDate
    defaults.synchronize
    openFriendsContorller
  end

  def application(application,
                  openURL:url,
                  sourceApplication:sourceApplication,
                  annotation:annotation)
    @facebook.handleOpenURL(url)
  end
end
