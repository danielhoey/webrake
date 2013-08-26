require 'erb'
require_relative '../erb_common'

module Webrake::Layout
class Erb
  include Webrake::ErbCommon

  def initialize(layout)
    @layout = ERB.new(File.read(layout), nil, '>')
  end

  def apply(content, front_matter, modify_time)
    erb_result(@layout, front_matter.merge(:content => content, :modify_time => modify_time))
  end
end
end
