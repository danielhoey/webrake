
module Webrake::Filters
class PassThroughFilter < Base
  def transform(content, front_matter, modify_time)
    content
  end
end
end
