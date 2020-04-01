class Task

  attr_reader :title, :pubtime, :deadline, :judgement, :content, :issuer

  def initialize(clnt, title, deadline, issuer, url, status)
    @title = title
    @deadline = deadline
    @issuer = issuer
    @url = url
    @clnt = clnt
    @status = status # finished => true, unfinished => false
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/#{@url}"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    @title, @pubtime, @deadline, @judgement = doc.css(".infotable > tr > td").map { |x| x.text.gsub(/\n/, " ").strip.squeeze(" ") }
    @content = Nokogiri::HTML(doc.css(".text > input").attr("value").text.gsub(/&nbsp;/, " ")).text.strip.squeeze(" ").chars.each_slice(50).to_a.map { |x| x.join + "\n" }.join
  end

  def finished?
    @status
  end
end