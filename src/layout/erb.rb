require 'erb'

module Layout
class Erb
  def initialize(layout)
    @layout = ERB.new(File.read(layout))
  end

  def apply(content)
    @layout.result(binding)
  end
end
end
