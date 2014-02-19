require 'erb'
require_relative '../erb_common'
require_relative '../source_file'
require_relative 'base'

module Webrake::Filters
class Erb < Base
  include Webrake::ErbCommon

  def default_output_file_extension
    'html'
  end

  def transform(content, front_matter, modify_time, source_files=[])
    erb_result(ERB.new(content, nil, '>'), front_matter.merge(:modify_time => modify_time, :source_files => source_files))
  end
end
end
