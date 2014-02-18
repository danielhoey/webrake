#
# Dependency 
# Manually creates a Rake prerequiste on a file task
# Example: one file contains another file's contents
#

module Webrake
class Dependency
  def self.create(sources, output, tasks, source_dir)
    output = "#{source_dir}#{output}" unless source_dir.nil?
    task = find_task(tasks, output)
    task.source = [task.source, sources.map{|s| "#{source_dir}#{s}"}].flatten
  end

  def self.find_task(tasks, output)
    task = tasks.find{|t| t.output == output}
    raise "Dependency error - no task found with output: #{output.inspect}" if task.nil?
    return task
  end
end


if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require "rake"
require_relative "rule"
class DependencyTest < Minitest::Unit::TestCase
  def test_find_task
    tasks = [Rule::Task.new(:rake_task, :source, 'dir/output_file', :proc)]
    assert_equal(tasks[0], Dependency.find_task(tasks, 'dir/output_file'))
  end

  def test_apply_dependency_to_task_list
    rake_task = Rake::Task.new('test', Rake::Application.new)
    task = Rule::Task.new(rake_task, 'dir/source_file', 'dir/output_file', :proc)
    dependency = Dependency.create(%w(src1 src2), 'output_file', [task], 'dir/')

    assert_equal(%w(dir/source_file dir/src1 dir/src2), task.source)
  end

  def skiptest_single_source
    rake_task = Rake::Task.new('test', Rake::Application.new)
    dependency = Dependency.create('src1', 'output_file', [Rule::Task.new(rake_task, :source, 'output_file', :proc)])

    assert_equal(%w(src1), rake_task.prerequisites)
  end

end
end
end
