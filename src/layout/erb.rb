require 'erb'

module Webrake::Layout
class Erb
  def initialize(layout)
    @layout = ERB.new(File.read(layout), nil, '>')
  end

  def apply(content)
    @layout.result(binding)
  end
end
end
