require 'rake'
require 'pathname'
require_relative 'file_system'
Dir["#{File.expand_path(File.dirname(__FILE__))}/filters/*.rb"].each {|f| require f}
Dir["#{File.expand_path(File.dirname(__FILE__))}/layout/*.rb"].each {|f| require f}

class Webrake
  attr_accessor :intermediate_files

  def initialize(rake_app, file_system, rules={})
    @rake_app = rake_app
    @file_system = file_system
    @intermediate_files = []
    @output_files = []

    add_rules(rules) unless rules.empty?
  end

  def add_rules(rules)
    (rules.delete(:filters) || []).each do |glob, filter|
      input_files("source/#{glob}").each do |f|      
        add_filter(f, filter)
      end
    end
    
    (rules.delete(:output) || []).each do |glob, layout|
      @file_system.mkdir('output/')
      input_files("source/#{glob}").each do |f|
        add_output_rule(f, 'output/', layout)
      end
    end

    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def input_files(glob)
    files = @file_system.file_list(glob)
    @intermediate_files.each do |f| 
      files.add(f) if File.fnmatch(glob, f)
    end
    return files
  end

  def add_filter(source, rule)
    output = "source/#{File.basename(source, '.*')}"
    @intermediate_files << output
    @rake_app.define_task(Rake::FileTask, {output => source}) do
      content = rule.apply(@file_system.read(source))
      @file_system.write(output, content, @file_system.mtime(source))
    end
  end

  def add_output_rule(source, destination_directory, layout)
    source = Pathname.new(source)
    output = "#{destination_directory}#{source.relative_path_from(Pathname.new('source/'))}"
    @output_files << output
    @rake_app.define_task(Rake::FileTask, {output => source.to_s}) do
      content = layout.apply(@file_system.read(source.to_s))
      @file_system.write(output, content, @file_system.mtime(source.to_s))
    end
  end

  def define_clean_tasks
    @rake_app.define_task(Rake::Task, :clean_intermediate_files) do 
      @file_system.remove_all(@intermediate_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean_output_files) do 
      @file_system.remove_all(@output_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean => [:clean_intermediate_files, :clean_output_files])
  end

  def define_build_task
    @rake_app.define_task(Rake::Task, :build => @intermediate_files + @output_files)
  end
end



if ARGV[0] == 'test'
require "minitest/autorun"
class WebrakeTest < Minitest::Unit::TestCase
  def setup
    @filter = Minitest::Mock.new
    @file_system = Minitest::Mock.new
    @rake_app = RakeAppMock.new
  end

  def test_output_rules
    webrake = Webrake.new(@rake_app, @file_system)
    @file_system.expect(:file_list, FileList['source/file1.html'], ['source/*.html'])
    @file_system.expect(:mkdir, nil, ['output/'])
    webrake.intermediate_files = ['source/file2.html']
    layout = Minitest::Mock.new
    webrake.add_rules(:output => {'*.html' => layout})

    assert_equal({'output/file1.html' => 'source/file1.html'}, @rake_app.tasks[0].params)
    assert_equal({'output/file2.html' => 'source/file2.html'}, @rake_app.tasks[1].params)
    @file_system.verify
   
    @file_system.expect(:read, 'src file content', ['source/file1.html'])
    layout.expect(:apply, 'layout output', ['src file content'])
    mtime = Time.now
    @file_system.expect(:mtime, mtime, ['source/file1.html'])
    @file_system.expect(:write, nil, ['output/file1.html', 'layout output', mtime])
    @rake_app.tasks[0].block.call
    @file_system.verify
    layout.verify

    task = @rake_app.tasks[-1]
    assert_equal(Rake::Task, task.klass)
    assert_equal({:build => %w(source/file2.html output/file1.html output/file2.html)}, task.params)
  end

  def test_output_file_extension
    @file_system.expect(:file_list, ['source/style.ext2.ext1'], ['source/style.ext2.ext1'])
    Webrake.new(@rake_app, @file_system, :filters => {'style.ext2.ext1' => nil})
    assert_equal('source/style.ext2', @rake_app.tasks[0].params.keys[0])
    @file_system.verify
  end

  def test_single_file_rule
    @file_system.expect(:file_list, ['source/index.html.erb'], ['source/index.html.erb'])
    Webrake.new(@rake_app, @file_system, :filters => {'index.html.erb' => @filter})
    should_make_file_task
    should_make_clean_task
    should_make_build_task
  end

  def test_glob_rule
    @file_system.expect(:file_list, ['source/index.html.erb'], ['source/*.html.erb'])
    Webrake.new(@rake_app, @file_system, :filters => {'*.html.erb' => @filter})
    should_make_file_task
    should_make_clean_task
    should_make_build_task
  end

  def should_make_file_task
    task = @rake_app.tasks[0]
    assert_equal([Rake::FileTask, {'source/index.html' => 'source/index.html.erb'}], 
                 [task.klass, task.params])

    @filter.expect(:apply, 'filter output', ['src file content'])
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
    task = @rake_app.tasks[4]
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
end
