class Message

  attr_reader :title

  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @url = "http://jxpt.ahu.edu.cn/meol/common/inform/message_content.jsp?nid=#{@id}"
    res = @clnt.get_content(@url)
    doc = Nokogiri::HTML(res)
    @title = doc.css(".atitle").text
    @issuer, @pubtime = doc.css(".adate").text.gsub(/&nbsp;/, "").scan(/发布人：(.*).*?发布时间：(.*)/)[0].map(&:strip)
    @content = Nokogiri::HTML(doc.css(".abody > input").attr("value").text.gsub(/&amp;nbsp;/, "")).text.strip.squeeze(" ").chars.each_slice(50).to_a.map { |x| x.join + "\n" }.join
  end

  def table
    Terminal::Table.new do |t|
      t.title = "Message"
      t.add_row ["标题", @title]
      t.add_row ["发布人", @issuer]
      t.add_row ["发布时间", @pubtime]
      t.add_row ["发布内容", @content]
      t.style = { :all_separators => true }
    end
  end
end