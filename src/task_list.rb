require_relative 'rule'

module Webrake
class TaskList < Struct.new(:rules, :file_system, :input_files, :output_dir, :options)
  attr_reader :tasks, :output_files, :source_files

  def initialize(*args)
    super
    self.options = {} if options.nil?
    @tasks = apply_rules(input_files)
    @output_files = @tasks.map(&:output)
    @source_files = @tasks.map(&:source)

    unless @output_files.empty? || !options[:remove_file_extension]
      subsequent_tasks = TaskList.new(rules, file_system, InputFiles.new(nil,nil,@output_files), output_dir, options)

      @tasks += subsequent_tasks.tasks
      @output_files += subsequent_tasks.output_files
      @source_files += subsequent_tasks.source_files
    end
  end

  def apply_rules(files)
   rules.map {|glob, transform|
     rule = Rule.new(transform, file_system, output_dir, options)
     files.find(glob).map {|f| rule.create_task(f)}
   }.flatten
  end

  def all_files
    @output_files + @source_files
  end

  def each(&block)
    @tasks.each {|t| yield t}
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class TaskListTest < Minitest::Test
  def test_basic
    input_files = Minitest::Mock.new
    input_files.expect(:find, %w(page1.html.erb page2.html.erb), ['*.html.erb'])
    task_list = TaskList.new({'*.html.erb' => :transform_unused}, :file_system_unused, input_files, 'output_dir', {:remove_file_extension => '.*'})
    assert_equal(%w(page1.html.erb page2.html.erb), task_list.source_files)
    assert_equal(%w(output_dir/page1.html output_dir/page2.html), task_list.output_files)
  end

  def test_overlapping_rules
     #'blog/*.html.erb' => PassThroughFilter.new)
  end

  def test_rule_output_is_input_to_another_rules
    input_files = Minitest::Mock.new
    input_files.expect(:find, %w(page1.css.less.erb), ['*.erb'])
    input_files.expect(:find, [], ['*.less'])
    task_list = TaskList.new(
      {'*.erb' => :transform_unused, '*.less' => :transform_unused},
      :file_system_unused, input_files, '', {:remove_file_extension => '.*'})
    assert_equal(%w(page1.css.less.erb page1.css.less), task_list.source_files)
    assert_equal(%w(page1.css.less page1.css), task_list.output_files)
  end

  def test_endless_loop
    input_files = Minitest::Mock.new
    input_files.expect(:find, %w(page1.html), ['*.html'])
    task_list = TaskList.new({'*.html' => :transform_unused},
      :file_system_unused, input_files, '')
    assert_equal(%w(page1.html), task_list.source_files)
    assert_equal(%w(page1.html), task_list.output_files)
  end
end
end
end
 
