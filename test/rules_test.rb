require "minitest/autorun"
require_relative "../src/rules"

class RulesTest < Minitest::Unit::TestCase
  def setup
    @rake_app = RakeAppMock.new
  end

  def test_single_file_rule
    filter = Minitest::Mock.new
    file_system = Minitest::Mock.new
    rules = Rules.new(@rake_app, file_system, 'index.html.erb' => filter)

    assert_equal({'source/index.html' => 'source/index.html.erb'}, @rake_app.tasks[0][0])

    filter.expect(:process, 'filter output', ['src file content'])
    file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    mtime = Time.now
    file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    @rake_app.tasks[0][1].call

    [filter, file_system].each(&:verify)
  end

  def test_output_file_extension
    rules = Rules.new(@rake_app, nil, 'style.ext2.ext1' => nil)
    assert_equal('source/style.ext2', @rake_app.tasks[0][0].keys[0])
  end

  class RakeAppMock
    attr_reader :tasks

    def initialize
      @tasks = []
    end

    def define_task(klass, params, &block)
      @tasks << [params, Proc.new(&block)]
    end
  end
end

