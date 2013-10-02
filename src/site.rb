require 'rake'
require_relative 'rule'
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
    filter_rules = create_rules(rules.delete(:filters), 'source/')
    @filter_tasks = TaskList.new(filter_rules, source_files, :recursive => true)
    define_tasks(@filter_tasks)

    output_rules = create_rules(rules.delete(:output), 'output/')
    @output_tasks = TaskList.new(output_rules, source_files.include(@filter_tasks.output_files))
    define_tasks(@output_tasks)

    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def create_rules(rules, output_dir)
    RuleList.new(rules.map{|glob, transform|
      [glob, Rule.new(transform, @file_system, output_dir)]
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
class SiteTest < Minitest::Test
  def test_create_task
    #TODO: test that the rules are ordered by glob specificity
  end
end
end
end
