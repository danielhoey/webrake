require_relative 'base'

module Webrake::Filters
class Less < Base
  def initialize
    require 'less'
  end

  def transform(content, front_matter, modify_time)
    ::Less::Parser.new.parse(content).to_css
      #.to_css(:compress => true)
  end

  def default_output_file_extension
    'css'
  end
end
end
