require 'rake'

class Rules
  def initialize(rake_app, file_system, rules)
    @rake_app = rake_app
    @file_system = file_system
    @intermediate_files = []

    rules.each do |file, filter|
      add_rule(file, filter)
    end

    define_clean_tasks
  end

  def add_rule(file, filter)
    output = "source/#{File.basename(file, '.*')}"
    source = "source/#{file}"
    @intermediate_files << output
    @rake_app.define_task(Rake::FileTask, {output => source}) do
      content = filter.process(@file_system.read(source))
      @file_system.write(output, content, @file_system.mtime(source))
    end
  end

  def define_clean_tasks
    @rake_app.define_task(Rake::Task, :clean_intermediate_files) do 
      @file_system.remove_all(@intermediate_files)
    end
  end
end


require "minitest/autorun"
class RulesTest < Minitest::Unit::TestCase
  def setup
    @rake_app = RakeAppMock.new
  end

  def test_single_file_rule
    filter = Minitest::Mock.new
    file_system = Minitest::Mock.new
    rules = Rules.new(@rake_app, file_system, 'index.html.erb' => filter)

    task = @rake_app.tasks[0]
    assert_equal(Rake::FileTask, task.klass)
    assert_equal({'source/index.html' => 'source/index.html.erb'}, task.params)

    filter.expect(:process, 'filter output', ['src file content'])
    file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    mtime = Time.now
    file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    task.block.call
    [filter, file_system].each(&:verify)
    
    task = @rake_app.tasks[1]
    assert_equal(Rake::Task, task.klass)
    assert_equal(:clean_intermediate_files, task.params)
    file_system.expect(:remove_all, nil, [['source/index.html']])
    task.block.call
    file_system.verify
  end

  def test_output_file_extension
    rules = Rules.new(@rake_app, nil, 'style.ext2.ext1' => nil)
    assert_equal('source/style.ext2', @rake_app.tasks[0].params.keys[0])
  end

  class RakeAppMock
    attr_reader :tasks

    def initialize
      @tasks = []
    end

    def define_task(klass, params, &block)
      @tasks << OpenStruct.new(:klass => klass, :params => params, :block => Proc.new(&block))
    end
  end
end

