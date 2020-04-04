class Topic

  attr_reader :title

  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @lid = options[:lid]
    @url = "http://jxpt.ahu.edu.cn/meol/common/faq/thread.jsp?threadid=#{@id}&lid=#{@lid}"
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/index.jsp?courseId=#{@lid}"
    @clnt.get_content(url)
    res = @clnt.get_content(@url)
    doc = Nokogiri::HTML(res)
    if !doc.css("title").text.include? "错误"
      @pubtime = doc.css(".infotable tr:nth-child(2) .con_left > li:nth-child(2) > span").text.scan(/Posted:(.*)/)[0][0]
      @title, @issuer = doc.css("table.form tr:nth-child(1) > td").text.scan(/话题：(.*).*?作者：(.*)/)[0].map(&:strip)
      @description = Nokogiri::HTML(doc.css(".infotable > tr:nth-child(2) .content > input").attr("value").value.gsub(/&nbsp;/, "")).text.strip.squeeze(" ").chars.each_slice(50).to_a.map { |x| x.join + "\n" }.join
    else
      @title = "话题已经不存在或者已删除"
      @url = @issuer = @pubtime = @description = "无"
    end
  end

  def table
    Terminal::Table.new do |t|
      t.title = "Topic"
      t.add_row ["标题", @title]
      t.add_row ["链接", @url]
      t.add_row ["发布人", @issuer]
      t.add_row ["发布时间", @pubtime]
      t.add_row ["话题内容", @description]
      t.style = { :all_separators => true }
    end
  end
end