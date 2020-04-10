class Course

  require 'date'

  require_relative 'task'
  require_relative 'inform'
  require_relative 'chapter'
  require_relative 'subtitle'
  require_relative 'section'

  attr_reader :id, :name

  def initialize(clnt, options={})
    @id = options[:lid]
    @name = options[:name]
    @clnt = clnt
    @teacher = options[:teacher]
    @course_num = options[:course_num]
  end

  def index
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/index.jsp"
    params = { :courseId => @id }
    @index = @clnt.get_content(url, params)
  end

  def informs
    return @informs if !@informs.nil?
    url = "http://jxpt.ahu.edu.cn/meol/jpk/course/layout/newpage/default_demonstrate.jsp"
    params = { :courseId => @id }
    res = @clnt.get_content(url, params)
    doc = Nokogiri::HTML(res)
    @informs = []
    threads = []
    doc.css(".body2 > ul li").each_with_index do |x, idx|
      threads << Thread.new do
        title = x.text.strip
        url = x.css("a:nth-child(2)").attr("href").value
        issuer = x.css("a:nth-child(1) > span").text
        @informs << Inform.new(@clnt, :title => title, :url => url, :lid => @id, :issuer => issuer, :order => idx)
      end
    end
    threads.each(&:join)
    @informs.sort_by! { |i| i.order }
  end

  def tasks
    return @tasks if !@tasks.nil?
    self.index
    url = "http://jxpt.ahu.edu.cn/meol/common/hw/student/hwtask.jsp"
    res = @clnt.get_content(url)
    doc = Nokogiri::HTML(res)
    threads = []
    @tasks = []
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

  def chapters
    return @chapters if !@chapters.nil?
    self.index if @index.nil?
    doc = Nokogiri::HTML(@index)
    @chapters = doc.css("#ul_advance > li").reduce([]) do |memo, x|
      title = x.at_css("a > span").text.gsub(/\t/, " ").gsub(/、 /, "、")
      c_url = x.at_css("a").attr("href")
      if !x.css("ul > li > ul").empty?
        sections = x.css("ul > li > ul > li > a").map do |sc|
          url = sc.attr("href")
          sc_title = sc.css("span").text.gsub(/\t/, " ").gsub(/、/, "、")
          Section.new(@clnt, :url => url, :title => sc_title, :lid => @id)
        end
      end
      if !x.css("ul > li > a").empty?
        subtitles = x.css("ul > li > a").map do |s|
          url = s.attr("href")
          s_title = s.css("span").text.gsub(/\t/, " ").gsub(/、 /, "、")
          Subtitle.new(@clnt, :url => url, :title => s_title, :lid => @id, :sections => sections || [])
        end
      end
      memo << Chapter.new(@clnt, :title => title, :subtitles => subtitles || [], :url => c_url, :lid => @id)
    end
  end

  def contents
    return @contents if !@contents.nil?
    @contents = self.chapters.inject([]) { |cmemo, c| cmemo << [c] +
                                                              c.subtitles.inject([]) { |smemo, s| smemo << [s] +
                                                                                                           s.sections.inject([]) { |scmemo, sc| scmemo << sc } } }.flatten
  end

  def resources
    return @resources if !@resources.nil?
    @resources = self.contents.map(&:resources).flatten
  end

  def resources?
    self.chapters.any?(&:resources?) ||
    self.chapters.any? { |c| c.subtitles.any?(&:resources?) } ||
    self.chapters.any? { |c| c.subtitles.any? { |s| s.sections.any?(&:resources?) } }
  end
end