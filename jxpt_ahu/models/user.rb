require 'httpclient'
require 'nokogiri'

class User

  require_relative 'course'

  attr_reader :name, :courses

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
    reminder = doc.css("#reminder > li:nth-child(2) > a:nth-child(1)").text
    @courses = doc.css("#reminder > li:nth-child(2) > ul:nth-child(2) a").reduce([]) do |memo, x|
      id = x.attr("onclick").scan(/\d+/)[0]
      name = x.text.strip
      memo << Course.new(id, name, @clnt)
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