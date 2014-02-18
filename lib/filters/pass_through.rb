
module Webrake::Filters
class PassThrough < Base
  def transform(content, front_matter, modify_time)
    content
  end
end
end
