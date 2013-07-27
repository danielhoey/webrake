require 'rake'
require_relative 'rule'
require_relative 'input_files'

module Webrake
class Site
  attr_accessor :intermediate_files, :output_files

  def initialize(rake_app, file_system, rules={})
    @rake_app = rake_app
    @file_system = file_system
    @intermediate_files = []
    @output_files = []
    @file_system.mkdir('output/')

    add_rules(rules) unless rules.empty?
  end

  def add_rules(rules)
    process_rule(rules.delete(:filters), @intermediate_files, 'source/', :remove_file_extension => '.*')
    process_rule(rules.delete(:output), @output_files, 'output/')

    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def process_rule(rules, file_list, output_dir, options={})
    return if rules.nil?

    rules.each do |glob, filter|
      r = Rule.new(filter, @file_system, output_dir, options)
      input_files(glob).each do |f|
        add_task(r.create_task(f), file_list)
      end
    end
  end

  def add_task(t, file_list)
    file_list << t.output
    @rake_app.define_task(t.rake_task, {t.output => t.source}, &t.proc)
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

  def input_files(glob)
    InputFiles.new('source/', @file_system, @intermediate_files).find(glob)
  end
end
end
