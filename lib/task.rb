
module Webrake
class Task
  attr_accessor :source
  attr_reader :rake_task, :output, :proc

  def initialize(source, output, transform, file_system)
    @rake_task = Rake::FileTask
    @source = source
    @output = output
    @proc = Proc.new {|task|
      begin
        file = SourceFile.new(source, file_system.mtime(source), file_system.read(source))

        source_files = task.prerequisites.map{|s|
          next if s == source
          SourceFile.new(s, file_system.mtime(s), file_system.read(s))
        }.compact

        content = transform.apply(file.content, file.data, file.mtime, source_files)
        file_system.write(output, content, file.mtime) 
      rescue
        #raise $! if ARGV.include?('test')
        raise Task::Error.new(source, transform.name, $!) 
      end
    }
  end

  def self.match_front_matter(file_contents)
    file_contents.match(/\A\s*---\n(.*)\n---\s*\n(.*)/m)
  end

  class Error < Exception
    attr_reader :path, :transform, :base_exception

    def initialize(path, transform, base_exception)
      @path = path
      @transform = transform
      @base_exception = base_exception
    end

    def message
      "Error applying #{transform} to #{path}: #{base_exception}"
    end
  end
end


if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require 'ostruct'
class TaskTest < Minitest::Unit::TestCase
  def test_front_matter_only_detected_at_top_of_file
    file_contents = ['', '---', 'title: Title', '---', 'src file content'].join("\n")
    assert_equal(0, Task.match_front_matter(file_contents).begin(0))

    file_contents = ['Some file contents', '---', 'title: Title', '---', 'src file content'].join("\n")
    assert_equal(nil, Task.match_front_matter(file_contents))
  end
end
end
end
