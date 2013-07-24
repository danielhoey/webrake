require "minitest/autorun"

class FunctionalTest < Minitest::Unit::TestCase
  def test_webrake
    Dir.chdir(File.dirname(__FILE__))
    system("rake build_clean");
    diff_output = `diff -r --exclude=".*" actual expected`
    assert_equal('', diff_output, "\n#{diff_output}\n")
    
    system("rake clean_intermediate_files")
    assert(!File.exist?('source/index.html'))
    assert(!File.exist?('output/index.html'))
  end
end
