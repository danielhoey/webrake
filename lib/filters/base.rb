module Webrake::Filters
class Base
  def output_file_name(source_file_name)
    source_file_name.basename('.*')
  end

  def apply(content, front_matter, modify_time, source_files)
    transform_output = if source_files.empty?
                        transform(content, front_matter, modify_time)   
                       else
                         transform(content, front_matter, modify_time, source_files)   
                       end

    if front_matter.empty?
      transform_output
    else
      ["#{front_matter.to_yaml}---", transform_output].join("\n") 
    end
  end
end
end
