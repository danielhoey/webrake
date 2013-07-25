require "fileutils"
require "minitest/autorun"

class FunctionalTest < Minitest::Unit::TestCase
  def setup
    Dir.chdir(File.dirname(__FILE__))
  end

  def teardown
    FileUtils.rm_rf('actual/output')
  end

  def test_webrake
    system("rake build_clean");
    diff_output = `diff -r --exclude=".*" actual expected`
    assert_equal('', diff_output, "\n#{diff_output}\n")
    
    system("rake clean_intermediate_files")
    assert(!File.exist?('source/index.html'))
    assert(!File.exist?('output/index.html'))
    assert(!File.exist?('output/blog/post1.html'))
  end
end
