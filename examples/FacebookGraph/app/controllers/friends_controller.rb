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
    self.title = "About #{@user.name || @user.id}"

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

  def numberOfSectionsInTableView(tableView)
    return 2
  end

  def tableView(tableView, titleForHeaderInSection:section)
    return ["Wall Posts", "Friends"][section]
  end

  def tableView(tableView, numberOfRowsInSection:section)
    return [1, @user.friends.count][section]
  end

  def layout_friend_in_cell(friend, cell)
    cell.textLabel.text = friend.name
    cell.detailTextLabel.text = friend.id
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    reuseIdentifier = ["WallPostsCell","FriendCell"][indexPath.section]

    cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) || begin
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:reuseIdentifier)
      cell
    end

    cell.accessoryType = [UITableViewCellAccessoryDisclosureIndicator, UITableViewCellAccessoryNone][indexPath.section]

    if indexPath.section == 0
      cell.textLabel.text = "Wall Posts"
      cell.detailTextLabel.text = ""
    else
      friend = @user.friends[indexPath.row]
      layout_friend_in_cell(friend, cell)
    end

    cell
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)

    if indexPath.section == 0
      UIApplication.sharedApplication.delegate.navigationController.pushViewController(WallPostsController.alloc.initWithUser(user), animated: true)
    else
      friend = @user.friends[indexPath.row]
      UIApplication.sharedApplication.delegate.navigationController.pushViewController(FriendsController.alloc.initWithUser(friend), animated: true)
    end
  end
end