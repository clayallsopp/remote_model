class WallPost < RemoteModule::RemoteModel
  attr_accessor :id, :message
  attr_accessor :created_time

  # if we encounter "from" in the JSON return,
  # use the User class.
  has_one :from => :user

  collection_url ""
  member_url ":id"

  def self.from_string_date_formatter
    @from_string_date_formatter ||= begin
      dateFormat = NSDateFormatter.alloc.init
      dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
      dateFormat
    end
  end

  def self.to_string_date_formatter
    @to_string_date_formatter ||= begin
      dateFormat = NSDateFormatter.alloc.init
      dateFormat.dateFormat = "yyyy'-'MM'-'dd"
      dateFormat
    end
  end

  # EX 2012-05-09T21:57:42+0000
  def created_time=(created_time)
    if created_time.class == String
      @created_time = WallPost.from_string_date_formatter.dateFromString(created_time)
    elsif created_time.class == NSDate
      @created_time = created_time
    else
      raise "Incorrect class for created_time: #{created_time.class.to_s}"
    end
    @created_time
  end

  def created_time_string
    @created_time.nil? ? "" : WallPost.to_string_date_formatter.stringFromDate(@created_time)
  end
end