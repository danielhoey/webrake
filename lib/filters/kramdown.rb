require_relative 'base'

module Webrake::Filters
class Kramdown < Base
  def initialize
    require 'kramdown'
  end

  def transform(content, front_matter, modify_time)
    ::Kramdown::Document.new(content).to_html
  end

  def default_output_file_extension
    'html'
  end
end
end
