require 'erb'

module Webrake::Filters
class Erb
  def apply(content)
    @erb = ERB.new(content, nil, '>')
    @erb.result(binding)
  end
end
end
