
class SourceFile 
  attr_accessor :path, :contents

  def initialize(args)
    @path = args[:path]
    if args[:file_system]
      @contents = args[:file_system].read(path) 
    else
      @contents = args[:contents]
    end
  end

  def output_path
    Pathname.new(@path).relative_path_from(Pathname.new('source/')) # TODO: consolide "source/"
  end

  def ==(other)
    @path == other.path &&
    @contents == other.contents
  end
end
