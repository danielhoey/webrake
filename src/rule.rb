require 'rake'
require 'yaml'

module Webrake
class Rule
  def initialize(transform, file_system, output_directory)
    @transform = transform
    @file_system = file_system
    @output_directory = Pathname.new(output_directory)
  end

  def create_task(source, remove_file_extension=false)
    source = Pathname.new(source)
    relative_dir = './'
    relative_dir = source.dirname.to_s.split('/')[1..-1].join('/')
    file_name = if remove_file_extension
                  source.basename('.*')
                else
                  source.basename
                end

    output = @output_directory.join(relative_dir, file_name).cleanpath.to_s
    source = source.to_s
    
    Task.new(Rake::FileTask, source, output, Proc.new { 
      begin
        mtime = @file_system.mtime(source)
        raw_content = @file_system.read(source)
      
        front_matter_match = raw_content.match(/\A\s*---\n(.*)\n---\s*\n(.*)/m)
        if front_matter_match
          front_matter = YAML.load(front_matter_match[1])
          main_content = front_matter_match[2]
        else
          front_matter = {}
          main_content = raw_content
        end

        content = @transform.apply(main_content, front_matter, mtime, @file_system)
        @file_system.write(output, content, mtime) 
      rescue
        raise Rule::Error.new(source, @transform.class, $!)
      end
    })
  end
  Task = Struct.new(:rake_task, :source, :output, :proc)


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
class RuleTest < Minitest::Unit::TestCase
  def setup
    @transform = Minitest::Mock.new
    def @transform.class; Minitest::Mock; end
    @file_system = Minitest::Mock.new
  end

  def test_create_task
    r = Rule.new(@transform, @file_system, 'source/') 
    t = r.create_task('source/index.html.erb', :remove_file_extension)

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/index.html.erb', t.source)
    assert_equal('source/index.html', t.output)

    # test t.proc
    mtime = Time.now
    @transform.expect(:apply, 'filter output', ['src file content', {}, mtime, @file_system])
    @file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    t.proc.call
    [@transform, @file_system].each(&:verify)
  end

  def test_subdirectories
    r = Rule.new(@transform, @file_system, 'source/') 
    t = r.create_task('source/dir1/index.html.erb', :remove_file_extension)

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/dir1/index.html.erb', t.source)
    assert_equal('source/dir1/index.html', t.output)
  end

  def test_front_matter
    r = Rule.new(@transform, @file_system, 'source/') 
    t = r.create_task('source/index.html.erb', :remove_file_extension)

    file_contents = '
---
title: Title
---
src file content'

    mtime = Time.now
    @file_system.expect(:read, file_contents, ['source/index.html.erb'])
    @transform.expect(:apply, 'filter output', ['src file content', {'title' => 'Title'}, mtime, @file_system])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', "filter output", mtime])

    t.proc.call
    [@transform, @file_system].each(&:verify)
  end

 
end
end
end
