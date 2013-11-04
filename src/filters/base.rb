module Webrake::Filters
class Base
  def apply(content, front_matter, modify_time, file_system)
    @file_system = file_system
    if front_matter.empty?
      transform(content, front_matter, modify_time)   
    else
      ["#{front_matter.to_yaml}---", transform(content, front_matter, modify_time)].join("\n") 
    end
  end
end
end
