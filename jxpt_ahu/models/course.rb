class Course

  require 'date'

  require_relative 'task'
  require_relative 'inform'

  attr_reader :id, :name

  def initialize(clnt, options={})
    @id = options[:lid]
    @name = options[:name]
    @clnt = clnt
    @tasks = []
    @informs = []
  end

  def informs
    return @informs if !@informs.empty?
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/default_demonstrate.jsp"
    params = { :courseId => @id }
    res = @clnt.get_content(url, params)
    doc = Nokogiri::HTML(res)
    threads = []
    doc.css(".body2 > ul li").each_with_index do |x, idx|
      threads << Thread.new do
        title = x.text.strip
        url = x.css("a:nth-child(2)").attr("href").value
        issuer = x.css("span").text
        @informs << Inform.new(@clnt, :title => title, :url => url, :lid => @id, :issuer => issuer, :order => idx)
      end
    end
    threads.each(&:join)
    @informs.sort_by! { |i| i.order }
  end

  def tasks
    return @tasks if !@tasks.empty?
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/index.jsp"
    params = { :courseId => @id }
    @clnt.get_content(url, params)
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/hwtask.jsp"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    threads = []
    doc.css(".valuelist > tr").drop(1).each do |x|
      threads << Thread.new do
        title = x.css("td:nth-child(1) > a:nth-child(1)").text.strip
        deadline = x.css("td:nth-child(2)").text
        issuer = x.css("td:nth-child(4)").text.strip
        id = x.css("td:nth-child(1) > a:nth-child(1)").attr("href").value.split("=")[-1]
        status = x.css(".enter").empty? ? true : false
        @tasks << Task.new(@clnt, :title => title, :deadline => deadline, :issuer => issuer, :id => id, :status => status)
      end
    end
    threads.each(&:join)
    @tasks.sort_by { |t| Date.parse(t.deadline.gsub(/[年月]/, "-").gsub(/日/, "")) }.reverse!
  end
end