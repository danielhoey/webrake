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
    #assert true, false, "TODO"
  end
end
end
end
 
