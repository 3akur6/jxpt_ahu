class OnlinePreview

  attr_reader :name, :visit_times

  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @lid = options[:lid]
    @name = options[:name]
    url = "http://jxpt.ahu.edu.cn/meol/common/script/onlinepreview.jsp"
    params = { :lid => @lid, :resid => @id }
    tries = 0
    begin
      res = @clnt.get_content(url, params)
      doc = Nokogiri::HTML(res)
      @visit_times, @start_time = doc.css(".needstar").text.scan(/您是第(\d+)次.*?学习了(\d+)分钟/)[0].map(&:to_i)
    rescue NoMethodError
      sleep(2 ** tries)
      tries += 1
      retry
    end
  end

  def boost
    time = 60 # range: 0 - 119 (=~ 1min)
    url = "http://jxpt.ahu.edu.cn/meol/common/script/addscriptviewtime.jsp"
    data = { :lessonId => @lid, :resid => @id, :onlinetime => time }
    res = @clnt.post_content(url, data)
    @time = res.strip.to_i
  end

  def time(type=:min)
    @time ||= @start_time * 60
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