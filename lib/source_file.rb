
class SourceFile 
  attr_accessor :path, :content, :mtime, :data

  def initialize(path, mtime, raw_content)
    @path = Pathname.new(path).relative_path_from(Pathname.new('source/')) # TODO: consolide "source/"
    @mtime = mtime

    front_matter_match = self.class.match_front_matter(raw_content)
    if front_matter_match
      @data = YAML.load(front_matter_match[1])
      @content = front_matter_match[2]
    else
      @data = {}
      @content = raw_content
    end
  end

  def contents
    @content
  end

  def self.match_front_matter(file_contents)
    file_contents.match(/\A\s*---\n(.*)\n---\s*\n(.*)/m)
  end

  def ==(other)
    @path == other.path &&
    @content == other.content
  end
end
