class FacebookLoginController < UIViewController
  def viewDidLoad
    self.title = "Login"
    self.view.backgroundColor = UIColor.whiteColor

    button = UIButton.buttonWithType UIButtonTypeRoundedRect
    button.when(UIControlEventTouchUpInside) do
      UIApplication.sharedApplication.delegate.facebook.authorize nil
    end
    button.setTitle("FB Login", forState: UIControlStateNormal)
    button.sizeToFit

    # ugly, dont really do this.
    width, height = button.frame.size.width, button.frame.size.height
    button.frame = CGRectMake(((self.view.frame.size.width - width) / 2).round, 
                              ((self.view.frame.size.height - height) / 2).round, 
                              width, 
                              height)
    self.view.addSubview button
  end
end