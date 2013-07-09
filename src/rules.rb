require 'rake'

class Rules
  def initialize(rake_app, file_system, rules)
    @rake_app = rake_app
    @file_system = file_system
    @intermediate_files = []

    rules.each do |glob, filter|
      @file_system.file_list("source/#{glob}").each do |f|      
        add_rule(f, filter)
      end
    end

    define_clean_tasks
    define_build_task
  end

  def add_rule(source, filter)
    output = "source/#{File.basename(source, '.*')}"
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

  def define_build_task
    @rake_app.define_task(Rake::Task, :build => @intermediate_files)
  end
end


require "minitest/autorun"
class RulesTest < Minitest::Unit::TestCase
  require 'byebug'

  def setup
    @filter = Minitest::Mock.new
    @file_system = Minitest::Mock.new
    @rake_app = RakeAppMock.new
  end
  
  def make_rules(rules)
    Rules.new(@rake_app, @file_system, rules)
  end

  def test_output_file_extension
    @file_system.expect(:file_list, ['source/style.ext2.ext1'], ['source/style.ext2.ext1'])
    make_rules('style.ext2.ext1' => nil)
    assert_equal('source/style.ext2', @rake_app.tasks[0].params.keys[0])
  end

  def test_single_file_rule
    @file_system.expect(:file_list, ['source/index.html.erb'], ['source/index.html.erb'])
    make_rules('index.html.erb' => @filter)
    should_make_file_task
    should_make_clean_task
    should_make_build_task
  end

  def test_glob_rule
    @file_system.expect(:file_list, ['source/index.html.erb'], ['source/*.html.erb'])
    make_rules('*.html.erb' => @filter)
    should_make_file_task
    should_make_clean_task
    should_make_build_task
  end

  def should_make_file_task
    task = @rake_app.tasks[0]
    assert_equal([Rake::FileTask, {'source/index.html' => 'source/index.html.erb'}], 
                 [task.klass, task.params])

    @filter.expect(:process, 'filter output', ['src file content'])
    @file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    mtime = Time.now
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    task.block.call
    [@filter, @file_system].each(&:verify)
  end

  def should_make_clean_task 
    task = @rake_app.tasks[1]
    assert_equal(Rake::Task, task.klass)
    assert_equal(:clean_intermediate_files, task.params)
    @file_system.expect(:remove_all, nil, [['source/index.html']])
    task.block.call
    @file_system.verify
  end

  def should_make_build_task
    task = @rake_app.tasks[2]
    assert_equal(Rake::Task, task.klass)
    assert_equal({:build => ['source/index.html']}, task.params)
  end

  class RakeAppMock
    attr_reader :tasks

    def initialize
      @tasks = []
    end

    def define_task(klass, params, &block)
      block = Proc.new(&block) if block
      @tasks << OpenStruct.new(:klass => klass, :params => params, :block => block)
    end
  end
end

