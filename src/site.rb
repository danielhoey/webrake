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
    define_filter_tasks(rules.delete(:filters))
    define_output_tasks(rules.delete(:output))
    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def create_rules(rules, output_dir, options={})
    rules.inject({}) do |hash, rule| #glob, transform|
      hash[rule[0]] = Rule.new(rule[1], @file_system, output_dir, options)
      hash
    end
  end

  def define_filter_tasks(rules)
    @filter_tasks = TaskList.new(create_rules(rules, 'source/', :remove_file_extension => '.*'), source_files, :recursive => true)
    define_tasks(@filter_tasks)
  end

  def define_output_tasks(rules)
    @output_tasks = TaskList.new(create_rules(rules, 'output/'), source_files.include(@filter_tasks.output_files))
    define_tasks(@output_tasks)
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
end
