class Subtitle < Chapter

  attr_reader :sections

  def initialize(clnt, options)
    @clnt = clnt
    @column_id = options[:url].scan(/columnId=(\d+)/)[0][0] rescue nil
    @title = options[:title]
    @lid = options[:lid]
    @sections = options[:sections]
  end

  def to_s
    "--" + self.title
  end
end