module Webrake::Filters
class Base
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

  def output_file_name(source_file_name)
    ofn = source_file_name.basename('.*')
    if ofn.to_s !~ /\.\w+$/ && !default_output_file_extension.nil?
      "#{ofn}.#{default_output_file_extension}"
    else
      ofn
    end
  end

  def default_output_file_extension
  end

  def name
    self.class.to_s
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class RuleTest < Minitest::Unit::TestCase
  def test_file_extensions
    filter = Base.new
    assert_equal('file.html', filter.output_file_name(Pathname.new('file.html.base')).to_s)
    assert_equal('file', filter.output_file_name(Pathname.new('file.base')).to_s)

    def filter.default_output_file_extension
      'txt'
    end

    assert_equal('file.txt', filter.output_file_name(Pathname.new('file.base')).to_s)
    assert_equal('file.html', filter.output_file_name(Pathname.new('file.html.base')).to_s)
  end
end
end
end
