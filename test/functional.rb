require "minitest/autorun"

class FunctionalTest < Minitest::Unit::TestCase
  def test_webrake
    Dir.chdir(File.dirname(__FILE__))
    system("rake build_clean");
    assert_equal('', `diff source expected/source`)
    
    system("rake clean_intermediate_files");
    assert(!File.exist?('source/index.html'))
  end
end
