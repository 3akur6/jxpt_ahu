class Section < Subtitle
  def to_s
    "----" + self.title
  end
end