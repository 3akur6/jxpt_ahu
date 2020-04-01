class Course

  require_relative 'task'
  require_relative 'inform'

  attr_reader :name

  def initialize(course_id, name, clnt)
    @id = course_id
    @name = name
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
    @informs = doc.css(".body2 > ul li").map do |x|
      title = x.text.strip
      url = x.css("a:nth-child(2)").attr("href").value
      Inform.new(@clnt, title, url)
    end
  end

  def tasks
    return @tasks if !@tasks.empty?
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/index.jsp"
    params = { :courseId => @id }
    @clnt.get_content(url, params)
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/hwtask.jsp"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    @tasks = doc.css(".valuelist > tr").drop(1).reduce([]) do |memo, x|
      title = x.css("td:nth-child(1) > a:nth-child(1)").text.strip
      deadline = x.css("td:nth-child(2)").text
      issuer = x.css("td:nth-child(4)").text.strip
      url = x.css("td:nth-child(1) > a:nth-child(1)").attr("href")
      status = x.css(".enter").empty? ? true : false
      memo << Task.new(@clnt, title, deadline, issuer, url, status)
    end
  end
end