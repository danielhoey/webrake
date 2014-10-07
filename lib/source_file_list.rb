require 'yaml'

module Webrake
class SourceFileList < Array
  def initialize(source_files)
    super(source_files)
  end

  def [](path_or_index)
    if path_or_index.is_a?(Integer)
      super
    else
      find{|sf| sf.path =~ /#{path_or_index}/}
    end
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require 'ostruct'

class SourceFileListTest < Minitest::Unit::TestCase
  def test_get_by_index
    sfl = SourceFileList.new([OpenStruct.new(path: '/source/a.txt')])
    assert_equal('/source/a.txt', sfl[0].path)
  end

  def test_get_by_path
    sfl = SourceFileList.new([OpenStruct.new(path: '/source/a.txt')])
    assert_equal('/source/a.txt', sfl['a.txt'].path)
  end
end
end
end
