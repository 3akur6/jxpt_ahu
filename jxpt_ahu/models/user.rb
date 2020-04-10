require 'httpclient'
require 'nokogiri'

class User

  require_relative 'course'

  attr_reader :name, :courses, :clnt, :tasks

  def initialize(options={})
    @username = options[:username]
    @password = options[:password]
    @clnt = HTTPClient.new
  end

  def login
    url = 'http://jxpt.ahu.edu.cn/meol/loginCheck.do'
    data = { :IPT_LOGINUSERNAME => @username, :IPT_LOGINPASSWORD => @password }
    res = @clnt.post_content(url, data)
    doc = Nokogiri::HTML(res)
    @name = doc.css(".info").text
    @name.empty? ? false : true
  end

  def courses
    return @courses if !@courses.nil?
    self.homework if @tasks.nil?
    url = "http://jxpt.ahu.edu.cn/meol/welcomepage/student/course_list_v8.jsp"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    @courses = []
    threads = []
    doc.css(".list.clearfix > ul > li > .list_content").each do |x|
      threads << Thread.new do
        title = x.css(".title > a").text.strip
        course_num = x.css(".coursenum").text.strip
        teacher = x.css("span.realname").text.strip
        id = x.css(".title > a").attr("onclick").value.scan(/courseId=(\d+)/)[0][0]
        @courses << Course.new(@clnt, :lid => id, :name => title, :course_num => course_num, :teacher => teacher)
      end
    end
    threads.each(&:join)
    @courses = (@tasks + @courses).uniq { |x| x.id }
  end

  def homework
    return @tasks if !@tasks.nil?
    res = @clnt.get_content("http://jxpt.ahu.edu.cn/meol/welcomepage/student/interaction_reminder_v8.jsp")
    doc = Nokogiri::HTML(res)
    @tasks = []
    threads = []
    doc.css("#reminder > li").select { |x| x.css("a[title=点击查看]").text.include? "待提交作业" }[0].css("ul a").each do |x|
      threads << Thread.new do
        id = x.attr("onclick").scan(/\d+/)[0]
        name = x.text.strip
        @tasks << Course.new(@clnt, :lid => id, :name => name)
      end
    end
    threads.each(&:join)
    @tasks
  end
end

# monkey patch to avoid Cookie#domain warning

class WebAgent
  class Cookie < HTTP::Cookie
    def domain
      self.original_domain
    end
  end
end