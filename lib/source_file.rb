require 'yaml'

module Webrake
class SourceFile 
  attr_accessor :path, :content, :mtime, :data

  def initialize(path, mtime, raw_content)
    @path = Pathname.new(path).relative_path_from(Pathname.new('source/')) # TODO: consolide "source/"
    @mtime = mtime

    front_matter_match = self.class.match_front_matter(raw_content)
    if front_matter_match
      @data = YAML.load(front_matter_match[0])
      @content = front_matter_match[1]
    else
      @data = {}
      @content = raw_content
    end
  end

  def contents
    @content
  end

  def self.match_front_matter(file_contents)
    sections = file_contents.split("---\n")
    return unless sections.size > 1
    [sections[1], sections[2..-1].join("---\n")]
  end

  def ==(other)
    @path == other.path &&
    @content == other.content
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require 'ostruct'

class SourceFileTest < Minitest::Unit::TestCase
  def test_empty_file
    sf = SourceFile.new('source/file', :mtime, '')
    assert_equal('', sf.content)
    assert_equal({}, sf.data)
  end
    
  def test_no_front_matter
    sf = SourceFile.new('source/file', :mtime, 'file_content')
    assert_equal('file_content', sf.content)
    assert_equal({}, sf.data)
  end
  
  def test_front_matter
    text = ["---",
            "field: data",
            "---",
            "file_content"].join("\n")
    sf = SourceFile.new('source/file', :mtime, text)
    assert_equal('file_content', sf.content)
    assert_equal({'field' => 'data'}, sf.data)
  end

  def test_multiple_front_matter
    text = ["---",
            "field1: data1",
            "---",
            "file_content",
            "---",
            "field2: data2",
            "---"].join("\n")
    sf = SourceFile.new('source/file', :mtime, text)
    assert_equal({'field1' => 'data1'}, sf.data)
    assert_equal("file_content\n---\nfield2: data2\n---", sf.content)
  end

end
end
end
