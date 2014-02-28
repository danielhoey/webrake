require 'erb'
require_relative '../erb_common'

module Webrake::Layout
class Erb
  include Webrake::ErbCommon

  def initialize(layout_path)
    @layout_path = layout_path
    @layout = ERB.new(File.read(layout_path), nil, '>')
  end

  def output_file_name(source_file_name)
    source_file_name
  end

  def apply(content, front_matter, modify_time, source_files=[])
    erb_result(@layout, front_matter.merge(:content => content, :modify_time => modify_time))
  end

  def name
    "#{self.class.to_s}('#{@layout_path}')"
  end
end
end
