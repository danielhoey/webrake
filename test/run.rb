require "minitest/autorun"

class FunctionalTest < Minitest::Unit::TestCase
  def test_webrake
    Dir.chdir(File.dirname(__FILE__))
    system("rake");
    assert_equal('', `diff source expected/source`)
  end
end
