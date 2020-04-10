class DownloadPreview
  def initialize(clnt, options={})
    @clnt = clnt
    @id = options[:id]
    @lid = options[:lid]
  end
end