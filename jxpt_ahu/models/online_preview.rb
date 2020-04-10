class OnlinePreview
  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @lid = options[:lid]
    @name = options[:name]
    url = "http://jxpt.ahu.edu.cn/meol/common/script/onlinepreview.jsp"
    params = { :lid => @lid, :resid => @id }
    res = @clnt.get_content(url, params)
    doc = Nokogiri::HTML(res)
    @visit_times, @time = doc.css(".needstar").text.scan(/您是第(\d+)次.*?学习了(\d+)分钟/)[0]
  end

  def boost(minute=1)
    time = 60 * minute
    url = "http://jxpt.ahu.edu.cn/meol/common/script/addscriptviewtime.jsp"
    data = { :lessonId => @lid, :resid => @id, :onlinetime => time }
    @clnt.post_content(url, data)
  end

  def table
    Terminal::Table.new do |t|
      t.title = "OnlinePreview"
      t.add_row ["标题", @name]
      t.add_row ["访问次数", @visit_times]
      t.add_row ["学习时长", @time]
    end
  end
end