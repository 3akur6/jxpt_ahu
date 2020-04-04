class Task

  attr_reader :title, :pubtime, :deadline, :judgement, :content, :issuer, :submit, :attachment, :attachment_name

  def initialize(clnt, options={})
    @clnt = clnt
    @title = options[:title]
    @deadline = options[:deadline]
    @issuer = options[:issuer]
    @id = options[:id]
    @submit = "http://jxpt.ahu.edu.cn/meol/common/hw/student/write.jsp?hwtid=#{@id}"
    @status = options[:status] # finished => true, unfinished => false
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/hwtask.view.jsp?hwtid=#{@id}"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    @title, @pubtime, @deadline, @judgement = doc.css(".infotable > tr > td").map { |x| x.text.gsub(/\n/, " ").strip.squeeze(" ") }
    doc = Nokogiri::HTML(doc.css(".text > input").attr("value").value.gsub(/&nbsp;/, " "))
    @content = doc.text.strip.squeeze(" ").chars.each_slice(50).to_a.map { |x| x.join + "\n" }.join
    @attachment = doc.css("a").attr("href") ? "http://jxpt.ahu.edu.cn#{doc.css("a").attr("href").value}" : "无"
    @attachment_name = doc.css("a").attr("title").value if @attachment != "无"
  end

  def table
    Terminal::Table.new do |t|
      t.title = "Task"
      t.add_row ["标题", @title]
      t.add_row ["链接", @submit]
      t.add_row ["发布人", @issuer]
      t.add_row ["发布时间", @pubtime]
      t.add_row ["截止时间", @deadline]
      t.add_row ["评分方式", @judgement]
      t.add_row ["作业内容", @content]
      t.add_row ["附件", @attachment]
      t.style = { :all_separators => true }
    end
  end

  def finished?
    @status
  end
end