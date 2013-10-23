require 'erb'
require_relative '../erb_common'
require_relative 'base'

module Webrake::Filters
class Erb < Base
  include Webrake::ErbCommon

  def transform(content, front_matter, modify_time)
    erb_result(ERB.new(content, nil, '>'), front_matter.merge(:modify_time => modify_time))
  end
end
end
