require_relative 'rule'
require_relative 'input_files'

module Webrake
class TaskList < Struct.new(:rules, :input_files, :options)
  attr_reader :tasks, :output_files, :source_files

  def initialize(*args)
    super
    self.options = {} if options.nil?

    @tasks = apply_rules(input_files)
    @output_files = @tasks.map(&:output)
    @source_files = @tasks.map(&:source)

    unless @output_files.empty? || !options[:recursive]
      subsequent_tasks = TaskList.new(rules, @output_files, options)

      @tasks += subsequent_tasks.tasks
      @output_files += subsequent_tasks.output_files
      @source_files += subsequent_tasks.source_files
    end
  end

  def apply_rules(files)
    result = []
    files.each do |f|
      rules.each do |glob, rule|
        if File.fnmatch("**/#{glob}", f, File::FNM_PATHNAME | File::FNM_DOTMATCH)
          result << rule.create_task(f) 
        end
      end
    end
    result
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
    input_files = %w(page1.html.erb page2.html.erb)
    #TODO: need to make these rules objects, or use a mock instead?
    task_list = TaskList.new({'*.html.erb' => Rule.new(:unused, :unused, 'output_dir', {:remove_file_extension => '.*'})},
                              input_files, {:recursive => true})

    assert_equal(%w(page1.html.erb page2.html.erb), task_list.source_files)
    assert_equal(%w(output_dir/page1.html output_dir/page2.html), task_list.output_files)
  end

  def PENDINGtest_overlapping_rules
    return
    input_files = Minitest::Mock.new
    input_files.expect(:all_files, %w(blog/page1.html.erb))
    task_list = TaskList.new({'blog/*.html.erb' => :used_for_blog, '*.html.erb' => :used_for_rest}, :file_system_unused, input_files, 'output_dir', {:remove_file_extension => '.*'})

    assert_equal(1, task_list.tasks.size)
  end

  def test_rule_output_is_input_to_another_rules
    input_files = %w(page1.css.less.erb)
    task_list = TaskList.new({
      '*.erb' => Rule.new(:unused, :unused, '', {:remove_file_extension => '.*'}),
      '*.less' => Rule.new(:unused, :unused, '', {:remove_file_extension => '.*'})},
      input_files, {:recursive => true})
    assert_equal(%w(page1.css.less.erb page1.css.less), task_list.source_files)
    assert_equal(%w(page1.css.less page1.css), task_list.output_files)
  end

  def test_endless_loop
    input_files = %w(page1.html)
    task_list = TaskList.new({'*.html' => Rule.new(:unused, :unused, '')}, input_files)
    assert_equal(%w(page1.html), task_list.source_files)
    assert_equal(%w(page1.html), task_list.output_files)
  end
end
end
end
 
