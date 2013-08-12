require_relative 'rule'

module Webrake
class TaskList < Struct.new(:rules, :file_system, :input_files, :output_dir, :options)
  attr_reader :output_files, :source_files

  def initialize(*args)
    super
    self.options = {} if options.nil?

    @tasks = rules.map {|glob, transform|
               rule = Rule.new(transform, file_system, output_dir, options)
               input_files.find(glob).map {|f| rule.create_task(f)}
             }.flatten

    @output_files = @tasks.map(&:output)
    @source_files = @tasks.map(&:source)
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
  def test_pending
    input_files = Minitest::Mock.new
    input_files.expect(:find, %w(page1.html.erb page2.html.erb), ['*.html.erb'])
    task_list = TaskList.new({'*.html.erb' => :transform_unused}, :file_system_unused, input_files, 'output_dir')
  end

  def test_overlapping_rules
     #'blog/*.html.erb' => PassThroughFilter.new)
  end

  def test_rule_output_is_input_to_another_rules
  end

  def test_endless_loop
  end
end
end
end
 
