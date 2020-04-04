require 'httpclient'
require 'nokogiri'

class User

  require_relative 'course'

  attr_reader :name, :courses, :clnt

  def initialize(options={})
    @username = options[:username]
    @password = options[:password]
    @clnt = HTTPClient.new
    @courses = []
  end

  def login
    url = 'http://jxpt.ahu.edu.cn/meol/loginCheck.do'
    data = { :IPT_LOGINUSERNAME => @username, :IPT_LOGINPASSWORD => @password }
    res = @clnt.post_content(url, data)
    doc = Nokogiri::HTML(res)
    @name = doc.css(".info").text
    @name.empty? ? false : true
  end

  def homework
    res = @clnt.get_content("http://jxpt.ahu.edu.cn/meol/welcomepage/student/interaction_reminder_v8.jsp")
    doc = Nokogiri::HTML(res)
    @courses = doc.css("#reminder > li").select { |x| x.css("a[title=点击查看]").text.include? "待提交作业" }[0].css("ul a").reduce([]) do |memo, x|
      id = x.attr("onclick").scan(/\d+/)[0]
      name = x.text.strip
      memo << Course.new(@clnt, :lid => id, :name => name)
    end
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