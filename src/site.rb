require 'rake'
require_relative 'rule'
require_relative 'glob'
require_relative 'task_list'
require_relative 'dependency'

module Webrake
class Site
  attr_accessor :intermediate_files, :output_files

  def initialize(rake_app, file_system, rules={})
    @rake_app = rake_app
    @file_system = file_system
    @file_system.mkdir('output/')
    @source_dir = 'source/'

    add_rules(rules) unless rules.empty?
  end

  def add_rules(rules)
    filter_rules = create_rules(rules.delete(:filters), @source_dir)
    @filter_tasks = TaskList.new(filter_rules, source_files, :recursive => true)
    define_tasks(@filter_tasks)

    all_source_files = source_files.include(@filter_tasks.output_files)

    create_dependencies(rules.delete(:dependencies), all_source_files)

    output_rules = create_rules(rules.delete(:output), 'output/')
    @output_tasks = TaskList.new(output_rules, all_source_files)
    define_tasks(@output_tasks)

    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def create_dependencies(dependencies, source_files)
    dependencies.each do |globs, output|
      source = [globs].flatten.map{|glob| 
        glob = Glob.new(glob)
        source_files.find_all{|s| glob.match_including_subdirectories("source/#{s}")}
      }.flatten.uniq
      
      @rake_app.define_task(Rake::FileTask, {"source/#{output}" => source})
    end
  end

  def create_rules(rules, output_dir)
    RuleList.new(rules.map{|glob, transform|
      [Glob.new(glob), Rule.new(transform, @file_system, output_dir)]
    })
  end

  def source_files
    @file_system.file_list("source/**/*")
  end

  def define_tasks(tasks)
    tasks.each do |t|
      @rake_app.define_task(t.rake_task, {t.output => t.source}, &t.proc)
    end
  end

  def define_clean_tasks
    @rake_app.define_task(Rake::Task, :clean_intermediate_files) do 
      @file_system.remove_all(@filter_tasks.output_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean_output_files) do 
      @file_system.remove_all(@output_tasks.output_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean => [:clean_intermediate_files, :clean_output_files])
  end

  def define_build_task
    @rake_app.define_task(Rake::Task, :build => @output_tasks.output_files + @filter_tasks.output_files)
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class SiteTest < Minitest::Unit::TestCase
  def setup
    @file_system = MiniTest::Mock.new
    @file_system.expect(:mkdir, nil, ['output/'])
    Rake.application.clear
    @site = Site.new(Rake.application, @file_system)
  end

  def test_create_task
    task = Rule::Task.new(Rake::FileTask, 'source.txt', 'output.txt', Proc.new {})
    @site.define_tasks([task]) 
    assert_equal(1, Rake.application.tasks.size)
    assert_equal(%w(source.txt), Rake.application.tasks[0].prerequisites)
    
    task = Rule::Task.new(Rake::FileTask, ['source1.txt', 'source2.txt'], 'output2.txt', Proc.new {})
    @site.define_tasks([task]) 
    assert_equal(%w(source1.txt source2.txt), Rake.application.tasks[1].prerequisites)
  end

  def test_create_dependencies
    @site.create_dependencies({'src' => 'output', ['src1', 'src2'] => 'output'}, %w(source/src source/src1 source/src2))
    assert_equal(1, Rake.application.tasks.size)
    assert_equal(%w(source/src source/src1 source/src2), Rake.application.tasks[0].prerequisites)
  end

  def test_glob_dependencies
    @site.create_dependencies({'*.html' => 'output'}, %w(source/post1.html source/post2.html))

    assert_equal(1, Rake.application.tasks.size)
    assert_equal(%w(source/post1.html source/post2.html), Rake.application.tasks[0].prerequisites)
  end
end
end
end
