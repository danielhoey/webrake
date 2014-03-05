require_relative 'rule_list'

module Webrake
class TaskList < Struct.new(:rules, :input_files, :options)
  attr_reader :tasks, :output_files, :source_files

  def initialize(*args)
    super
    @recursive = options[:recursive] unless options.nil?

    @tasks = rules.create_tasks(input_files)
    @output_files = @tasks.map(&:output)
    @source_files = @tasks.map(&:source)

    unless @output_files.empty? || !@recursive
      subsequent_tasks = TaskList.new(rules, @output_files, options)

      @tasks += subsequent_tasks.tasks
      @output_files += subsequent_tasks.output_files
      @source_files += subsequent_tasks.source_files
    end
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
require "ostruct"
class TaskListTest < Minitest::Unit::TestCase
  def setup
  end

  def test_basic
    input_files = %w(page1.html.erb page2.html.erb)

    rule_list = MiniTest::Mock.new
    tasks = [Task.new('page1.html.erb', 'page1.html', :unused, :unused),
             Task.new('page2.html.erb', 'page2.html', :unused, :unused)]
    rule_list.expect(:create_tasks, tasks, [input_files])
    rule_list.expect(:create_tasks, [], [%w(page1.html page2.html)])

    task_list = TaskList.new(rule_list, input_files, {:recursive => true})

    assert_equal(%w(page1.html.erb page2.html.erb), task_list.source_files)
    assert_equal(%w(page1.html page2.html), task_list.output_files)
  end

  def test_rule_output_is_input_to_another_rules
    transform = Filters::Base.new
    input_files = %w(page1.css.less.erb)
    task_list = TaskList.new(RuleList.new({
      Glob.new('*.erb') => Rule.new(transform, :unused, ''),
      Glob.new('*.less') => Rule.new(transform, :unused, '')}),
      input_files, {:recursive => true})
    assert_equal(%w(page1.css.less.erb page1.css.less), task_list.source_files)
    assert_equal(%w(page1.css.less page1.css), task_list.output_files)
  end

  def test_endless_loop
    transform = Layout::None
    input_files = %w(page1.html)
    task_list = TaskList.new(RuleList.new({Glob.new('*.html') => Rule.new(transform, :unused, '')}), input_files)
    assert_equal(%w(page1.html), task_list.source_files)
    assert_equal(%w(page1.html), task_list.output_files)
  end
end
end
end
 
