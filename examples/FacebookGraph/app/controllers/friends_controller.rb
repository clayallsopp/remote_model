class FriendsController < UITableViewController
  attr_reader :user

  def initWithUserId(id = "me")
    @user = User.new(id: id)
    self
  end

  def initWithUser(user)
    raise "User cannot be nil" if user.nil?
    @user = user
    self
  end

  def viewDidLoad
    super
    self.title = @user.name ? "Friends of #{@user.name}" : "Friends of #{@user.id}"

    defaults = NSUserDefaults.standardUserDefaults
    RemoteModule::RemoteModel.set_access_token(defaults["FBAccessTokenKey"])
    
    @activity = UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleGray)
    self.view.addSubview @activity
    @activity.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)
    @activity.startAnimating

    @user.find_friends do |user|
      @activity.stopAnimating
      @activity.removeFromSuperview
      self.tableView.reloadData
    end
  end

  def tableView(tableView, numberOfRowsInSection:section)
    return @user.friends.count
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    reuseIdentifier = "FriendCell"

    cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) || begin
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:reuseIdentifier)
      cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton
      cell
    end

    friend = @user.friends[indexPath.row]
    cell.textLabel.text = friend.name
    cell.detailTextLabel.text = friend.id

    cell
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)
    friend = @user.friends[indexPath.row]

    UIApplication.sharedApplication.delegate.navigationController.pushViewController(FriendsController.alloc.initWithUser(friend), animated: true)
  end
end