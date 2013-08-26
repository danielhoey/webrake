require 'rake'
require 'yaml'

module Webrake
class Rule
  def initialize(transform, file_system, output_directory, options={})
    @transform = transform
    @file_system = file_system
    @output_directory = Pathname.new(output_directory)
    @remove_file_extension = options[:remove_file_extension]
  end

  def create_task(source)
    source = Pathname.new(source)
    relative_dir = './'
    relative_dir = source.dirname.to_s.split('/')[1..-1].join('/')
    file_name = basename(source)
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

        content = @transform.apply(main_content, front_matter, mtime)
        @file_system.write(output, content, mtime) 
      rescue
        raise Rule::Error.new(source, @transform.class, $!)
      end
    })
  end
  Task = Struct.new(:rake_task, :source, :output, :proc)

  def basename(source)
    if @remove_file_extension
      source.basename(@remove_file_extension)
    else
      source.basename
    end
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
class RuleTest < Minitest::Test
  def setup
    @transform = Minitest::Mock.new
    def @transform.class; Minitest::Mock; end
    @file_system = Minitest::Mock.new
  end

  def test_create_task
    r = Rule.new(@transform, @file_system, 'source/', :remove_file_extension => '.*') 
    t = r.create_task('source/index.html.erb')

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/index.html.erb', t.source)
    assert_equal('source/index.html', t.output)

    # test t.proc
    mtime = Time.now
    @transform.expect(:apply, 'filter output', ['src file content', {}, mtime])
    @file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    t.proc.call
    [@transform, @file_system].each(&:verify)
  end

  def test_subdirectories
    r = Rule.new(@transform, @file_system, 'source/', :remove_file_extension => '.*') 
    t = r.create_task('source/dir1/index.html.erb')

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/dir1/index.html.erb', t.source)
    assert_equal('source/dir1/index.html', t.output)
  end

  def test_front_matter
    r = Rule.new(@transform, @file_system, 'source/', :remove_file_extension => '.*') 
    t = r.create_task('source/index.html.erb')

    file_contents = '
---
title: Title
---
src file content'

    mtime = Time.now
    @file_system.expect(:read, file_contents, ['source/index.html.erb'])
    @transform.expect(:apply, 'filter output', ['src file content', {'title' => 'Title'}, mtime])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', "filter output", mtime])

    t.proc.call
    [@transform, @file_system].each(&:verify)
  end

 
end
end
end
