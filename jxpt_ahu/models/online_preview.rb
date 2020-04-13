class OnlinePreview

  attr_reader :name

  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @lid = options[:lid]
    @name = options[:name]
  end

  def visit_times
    return @visit_times if !@visit_times.nil?
    url = "http://jxpt.ahu.edu.cn/meol/common/script/onlinepreview.jsp"
    params = { :lid => @lid, :resid => @id }
    tries = 0
    begin
      res = @clnt.get_content(url, params)
      doc = Nokogiri::HTML(res)
      @visit_times = doc.css(".needstar").text.scan(/您是第(\d+)次/)[0][0].to_i
    rescue NoMethodError
      sleep(2 ** tries)
      tries += 1
      retry
    end
  end

  def boost(time=60) # range: 1 - 119 (=~ 1min)
    url = "http://jxpt.ahu.edu.cn/meol/common/script/addscriptviewtime.jsp"
    data = { :lessonId => @lid, :resid => @id, :onlinetime => time }
    res = @clnt.post_content(url, data)
    @time = res.strip.to_i
  end

  def time(type=:min)
    @time ||= self.boost 1
    case type
    when :min then @time / 60
    when :sec then @time
    end
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