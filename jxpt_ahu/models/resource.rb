class Resource

  require_relative 'online_preview'
  require_relative 'download_preview'

  attr_reader :name

  def initialize(clnt, options={})
    @clnt = clnt
    @name = options[:name]
    @url = options[:url]
    @lid = options[:lid]
    @id = @url.scan(/resid=(\d+)/)[0][0]
    @blng = options[:blng]
    type = @url.split(/[\/?]/)[-2]
    case type
    when "onlinepreview.jsp" then @type = OnlinePreview
    when "download_preview.jsp" then @type = DownloadPreview
    end
  end

  def detail
    @type.new(@clnt, :id => @id, :lid => @lid, :name => @name)
  end

  def to_s
    case
    when @blng == Chapter  then self.name
    when @blng == Subtitle then "--" + self.name
    when @blng == Section  then "----" + self.name
    end
  end
end