require "fileutils"
require "minitest/autorun"
require "byebug"

class FunctionalTest < Minitest::Unit::TestCase
  def setup
    Dir.chdir(File.dirname(__FILE__))
    @preexisting_files = Dir["actual/**/*"]
    system("touch -t 201308271200 actual/source/index.html.erb")
  end

  def teardown
    FileUtils.rm_rf('actual/output')
    FileUtils.rm_rf(Dir["actual/**/*"] - @preexisting_files)
  end

  def test_webrake
    system("cd actual; rake build_clean");
    diff_output = `diff -r -x ".*" actual expected`
    assert_equal('', diff_output, "\n#{diff_output}\n")

    system("cd actual; rake clean_intermediate_files")
    assert(!File.exist?('actual/source/index.html'))

    system("cd actual; rake clean")
    assert(!File.exist?('actual/output/index.html'))
    assert(!File.exist?('actual/output/blog/post1.html'))
  end
end
