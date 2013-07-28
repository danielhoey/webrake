
module Webrake
class Glob
  def initialize(raw_glob)
    @raw_glob = raw_glob
  end

  def <=>(other)
    return 0 if raw == other.raw
    return 0 if raw =~ /^\*+$/ and other.raw =~ /^\*+$/
    return 1 if raw == '*'
    return -1 if other.raw == '*'
    file_ending_comparision =  other.raw.split(".").size <=> raw.split(".").size 
    if file_ending_comparision == 0
      return other.raw.split("/").size <=> raw.split("/").size 
    else
      return file_ending_comparision
    end
  end

  def raw
    Pathname.new(@raw_glob).cleanpath.to_s
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class GlobTest < Minitest::Test
  def test_input_files
    assert_equal(1, Glob.new('*') <=> Glob.new('*.html'))

    assert_equal(0, Glob.new('*') <=> Glob.new('*'))
    assert_equal(0, Glob.new('**') <=> Glob.new('*'))

    assert_equal(-1, Glob.new('**/*.html') <=> Glob.new('*'))
    assert_equal(-1, Glob.new('*.html') <=> Glob.new('*'))
    
    assert_equal(-1, Glob.new('**/a/*.html') <=> Glob.new('**/*.html'))
    assert_equal(-1, Glob.new('**/*.erb.html') <=> Glob.new('**/*.html'))
    assert_equal(-1, Glob.new('**/*.erb.html') <=> Glob.new('**/a/*.html'))

    assert_equal(0, Glob.new('./**/*.html') <=> Glob.new('**/*.html'))
  end
end
end
end
