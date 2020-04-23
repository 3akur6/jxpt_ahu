class Inform

  require_relative "message"
  require_relative "topic"
  require_relative "task"

  attr_reader :title, :order

  def initialize(clnt, options={})
    @clnt = clnt
    @title = options[:title]
    @lid = options[:lid]
    @issuer = options[:issuer]
    @order = options[:order]
    *_, type, id = options[:url].split(/[\/?]/)
    case type
    when "message_content.jsp"
      @id = id.scan(/nid=(\d+)/)[0][0]
      @type = Message
    when "thread.jsp"
      @id = id.scan(/threadid=(\d+)/)[0][0]
      @type = Topic
    when "hwtask.view.jsp"
      @id = id.scan(/hwtid=(\d+)/)[0][0]
      @type = Task
    end
  end

  def detail
    @type.new(@clnt, :id => @id, :lid => @lid, :issuer => @issuer)
  end
end