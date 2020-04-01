class Inform

  attr_reader :title

  def initialize(clnt, title, url)
    @clnt = clnt
    @title = title
    @url = url
  end
end