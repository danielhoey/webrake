require 'rake'
require_relative 'rule'
require_relative 'input_files'
require_relative 'glob'
require_relative 'task_list'

module Webrake
class Site
  attr_accessor :intermediate_files, :output_files

  def initialize(rake_app, file_system, rules={})
    @rake_app = rake_app
    @file_system = file_system
    @file_system.mkdir('output/')

    add_rules(rules) unless rules.empty?
  end

  def add_rules(rules)
    define_filter_tasks(rules.delete(:filters))
    define_output_tasks(rules.delete(:output))
    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def define_filter_tasks(rules)
    input_files = InputFiles.new('source/', @file_system, [])
    @filter_tasks = TaskList.new(rules, @file_system, input_files, 'source/', :remove_file_extension => '.*')
    define_tasks(@filter_tasks)
  end

  def define_output_tasks(rules)
    input_files = InputFiles.new('source/', @file_system, @filter_tasks.output_files)
    @output_tasks = TaskList.new(rules, @file_system, input_files, 'output/')
    define_tasks(@output_tasks)
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
class SiteTest < Minitest::Test
  def test_input_files
    rake_app = Minitest::Mock.new    
    file_system = Minitest::Mock.new    
    file_system.expect(:mkdir, nil, ['output/'])
    site = Site.new(rake_app, file_system)
    #rules = site.collate_rules('*.html.erb' => PassThroughFilter.new, 'blog/*.html.erb' => PassThroughFilter.new)

    #file_system.expect(
    #site.process_rules(rules, [])
  end
end
end
end
