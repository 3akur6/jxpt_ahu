class Task

  attr_reader :title, :pubtime, :deadline, :judgement, :content, :issuer, :submit, :attachment, :attachment_name

  def initialize(clnt, title, deadline, issuer, url, status)
    @title = title
    @deadline = deadline
    @issuer = issuer
    @clnt = clnt
    @id = url.split("=")[-1]
    @submit = "http://jxpt.ahu.edu.cn/meol/common/hw/student/write.jsp?hwtid=#{@id}"
    @status = status # finished => true, unfinished => false
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/hwtask.view.jsp?hwtid=#{@id}"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    @title, @pubtime, @deadline, @judgement = doc.css(".infotable > tr > td").map { |x| x.text.gsub(/\n/, " ").strip.squeeze(" ") }
    doc = Nokogiri::HTML(doc.css(".text > input").attr("value").value.gsub(/&nbsp;/, " "))
    @content = doc.text.strip.squeeze(" ").chars.each_slice(50).to_a.map { |x| x.join + "\n" }.join
    @attachment = doc.attr("href") ? "http://jxpt.ahu.edu.cn#{doc.attr("href").value}" : "无"
    @attachment_name = doc.attr("title").value if @attachment != "无"
  end

  def finished?
    @status
  end
end