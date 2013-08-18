module Webrake::Filters
class Less
  def initialize
    require 'less'
  end

  def apply(content)
    Less::Parser.new.parse(content).to_css
      #.to_css(:compress => true)
  end
end
end
