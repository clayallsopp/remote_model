class WallPostsController < UITableViewController
  attr_reader :user

  def initWithUser(user)
    raise "User cannot be nil" if user.nil?
    @user = user
    self
  end

  def viewDidLoad
    super
    self.title = "Wall Posts for #{@user.name || @user.id}"

    defaults = NSUserDefaults.standardUserDefaults
    RemoteModule::RemoteModel.set_access_token(defaults["FBAccessTokenKey"])
    
    @activity = UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleGray)
    self.view.addSubview @activity
    @activity.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)
    @activity.startAnimating

    @user.find_wall_posts do |user|
      @activity.stopAnimating
      @activity.removeFromSuperview
      self.tableView.reloadData
    end
  end

  def tableView(tableView, numberOfRowsInSection:section)
    return @user.wall_posts.count
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    reuseIdentifier = "WallPostCell"

    cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) || begin
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:reuseIdentifier)
      cell
    end

    wall_post = @user.wall_posts[indexPath.row]
    cell.textLabel.text = wall_post.message
    cell.detailTextLabel.text = wall_post.created_time_string

    cell
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)
  end
end