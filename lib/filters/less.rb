require_relative 'base'

module Webrake::Filters
class Less < Base
  def initialize(*import_paths)
    require 'less'
    @import_paths = import_paths
  end

  def transform(content, front_matter, modify_time)
    ::Less::Parser.new(:paths => @import_paths).parse(content).to_css
  end

  def default_output_file_extension
    'css'
  end
end
end
