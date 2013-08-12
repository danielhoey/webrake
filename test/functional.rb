require "fileutils"
require "minitest/autorun"
require "byebug"

class FunctionalTest < Minitest::Test
  def setup
    Dir.chdir(File.dirname(__FILE__))
    @preexisting_files = Dir["actual/**/*"]
  end

  def teardown
    FileUtils.rm_rf('actual/output')
    FileUtils.rm_rf(Dir["actual/**/*"] - @preexisting_files)
  end

  def test_webrake
    system("rake build_clean");
    diff_output = `diff -r --exclude=".*" actual expected`
    assert_equal('', diff_output, "\n#{diff_output}\n")
    
    system("rake clean_intermediate_files")
    assert(!File.exist?('actual/source/index.html'))

    system("rake clean")
    assert(!File.exist?('actual/output/index.html'))
    assert(!File.exist?('actual/output/blog/post1.html'))
  end
end
