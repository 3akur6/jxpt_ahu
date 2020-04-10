class Chapter

  require_relative 'subtitle'
  require_relative 'resource'

  attr_reader :title, :subtitles

  def initialize(clnt, options)
    @clnt = clnt
    @title = options[:title]
    @subtitles = options[:subtitles]
    @lid = options[:lid]
    @column_id = options[:url].scan(/columnId=(\d+)/)[0][0] rescue nil
  end

  def resources
    return @resources if !@resources.nil?
    url = "http://jxpt.ahu.edu.cn/meol/buildless/resFolderViewList.do"
    params = { :lid => @lid, :columnId => @column_id }
    res = @clnt.get_content(url, params)
    doc = Nokogiri::HTML(res)
    @resources = doc.css("td:nth-child(1) > a:nth-child(2)").reduce([]) do |memo, x|
      url = x.attr("href")
      name = x.text.strip
      memo << Resource.new(@clnt, :url => url, :name => name, :lid => @lid, :blng => self.class)
    end
  end

  def resources?
    !self.resources.empty?
  end

  def to_s
    self.title
  end
end