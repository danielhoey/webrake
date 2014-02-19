module Webrake::Layout
class None 
  def self.output_file_name(source_file_name)
    source_file_name
  end


  def self.apply(content, front_matter, modify_time, file_system)
    content
  end
end
end
