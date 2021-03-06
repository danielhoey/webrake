require 'rake'
require 'yaml'
require_relative './task'

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
    file_name = @transform.output_file_name(source.basename)
   
    output = @output_directory.join(relative_dir, file_name).cleanpath.to_s
    source = source.to_s
    Task.new(source, output, @transform, @file_system)
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require 'ostruct'
require_relative './source_file'

class RuleTest < Minitest::Unit::TestCase
  def setup
    @transform = Minitest::Mock.new
    def @transform.class; Minitest::Mock; end
    @file_system = Minitest::Mock.new
  end

  def test_create_task
    r = Rule.new(@transform, @file_system, 'source/')
    @transform.expect(:output_file_name, 'index.html', [Pathname.new('index.html.erb')])
    t = r.create_task('source/index.html.erb')

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/index.html.erb', t.source)
    assert_equal('source/index.html', t.output)

    # test t.proc
    mtime = Time.now
    @transform.expect(:apply, 'filter output', ['src file content', {}, mtime, []])
    @file_system.expect(:read, 'src file content', ['source/index.html.erb'])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', 'filter output', mtime])
    call_proc(t)
    [@transform, @file_system].each(&:verify)
  end

  def test_subdirectories
    r = Rule.new(@transform, @file_system, 'source/') 
    @transform.expect(:output_file_name, 'index.html', [Pathname.new('index.html.erb')])
    t = r.create_task('source/dir1/index.html.erb')

    assert_equal(Rake::FileTask, t.rake_task)
    assert_equal('source/dir1/index.html.erb', t.source)
    assert_equal('source/dir1/index.html', t.output)
  end

  def test_front_matter
    r = Rule.new(@transform, @file_system, 'source/') 
    @transform.expect(:output_file_name, 'index.html', [Pathname.new('index.html.erb')])
    t = r.create_task('source/index.html.erb')

    file_contents = '
---
title: Title
---
src file content'

    mtime = Time.now
    @file_system.expect(:read, file_contents, ['source/index.html.erb'])
    @transform.expect(:apply, 'filter output', ['src file content', {'title' => 'Title'}, mtime, []])
    @file_system.expect(:mtime, mtime, ['source/index.html.erb'])
    @file_system.expect(:write, nil, ['source/index.html', "filter output", mtime])

    call_proc(t)
    [@transform, @file_system].each(&:verify)
  end


  def test_source_files
    r = Rule.new(@transform, @file_system, 'source/') 
    @transform.expect(:output_file_name, 'blog_summary.html', [Pathname.new('blog_summary.html.erb')])
    t = r.create_task('source/blog_summary.html.erb')

    mtime = Time.now
    @file_system.expect(:read, 'summary', ['source/blog_summary.html.erb'])
    @file_system.expect(:mtime, mtime, ['source/blog_summary.html.erb'])
    @file_system.expect(:mtime, mtime, ['source/blog.html'])
    @file_system.expect(:write, nil, ['source/blog_summary.html', 'summary of blogs', mtime])
    @file_system.expect(:read, 'blog', ['source/blog.html']) # source file

    @transform.expect(:apply, 'summary of blogs', ['summary', {}, mtime, [SourceFile.new('source/blog.html', mtime, 'blog')]])
    
    call_proc(t, ['source/blog.html'])
    [@transform, @file_system].each(&:verify)
  end

  def call_proc(t, prerequisites=[])
    t.proc.call(OpenStruct.new(:prerequisites => prerequisites + [t.source]))
  end
end
end
end
